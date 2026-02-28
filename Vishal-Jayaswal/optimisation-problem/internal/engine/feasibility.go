package engine

import (
	"fmt"
	"strconv"
	"time"

	"optimisation-problem/internal/models"
)

var ProcessSequence = []string{"waxing", "waxsetting", "srd_split", "filing", "polishing"}

func CheckFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) (bool, []models.Overload) {

	// Process sequence validation
	if overloads := ValidateOrderWindows(orders); len(overloads) > 0 {
		return false, overloads
	}

	// Track remaining hours per bag per process
	remainingHrs := make(map[string]map[string]float64)
	for _, o := range orders {
		key := o.GetBagKey()
		remainingHrs[key] = make(map[string]float64)
		for pName, pInfo := range o.Processes {
			remainingHrs[key][pName] = pInfo.WorkingHrs
		}
	}

	// Iterate through each process in the sequence
	for _, pName := range ProcessSequence {
		// Identify overall time window for this process
		var minDate, maxDate time.Time
		first := true
		for _, o := range orders {
			if pInfo, ok := o.Processes[pName]; ok {
				if first || pInfo.StartDate.Before(minDate) {
					minDate = pInfo.StartDate
				}
				if first || pInfo.EndDate.After(maxDate) {
					maxDate = pInfo.EndDate
				}
				first = false
			}
		}

		if minDate.IsZero() {
			continue
		}

		// Daily Simulation for current process
		for currentDate := minDate; !currentDate.After(maxDate); currentDate = currentDate.AddDate(0, 0, 1) {
			activeBySource := make(map[string][]*models.Order)

			for i := range orders {
				o := &orders[i]
				pInfo, ok := o.Processes[pName]
				if ok && !currentDate.Before(pInfo.StartDate) &&
					!currentDate.After(pInfo.EndDate) &&
					remainingHrs[o.GetBagKey()][pName] > 0 {
					source := resolveCapacitySource(pName, o)
					activeBySource[source] = append(activeBySource[source], o)
				}
			}

			for source, active := range activeBySource {
				f, hasFactory := factoryMaster[source]
				capacity := 0.0
				if hasFactory {
					capacity = f.ProcessCapacity[pName]
				}

				pRemaining := make(map[string]float64)
				for _, o := range active {
					key := o.GetBagKey()
					pRemaining[key] = remainingHrs[key][pName]
				}

				ok, def, culpritKey := DistributeWithSlackEDF(active, pRemaining, currentDate, func(o *models.Order) time.Time {
					return o.Processes[pName].EndDate
				}, capacity)

				// Update global remaining hours
				for _, o := range active {
					key := o.GetBagKey()
					remainingHrs[key][pName] = pRemaining[key]
				}

				if ok {
					// Separate the Key back into OrderNo and BagNo for the report
					oNo, bNo := models.ParseBagKey(culpritKey)
					return false, []models.Overload{{
						Factory: source,
						Process: pName,
						Date:    currentDate,
						Deficit: def,
						OrderNo: oNo,
						BagNo:   bNo,
					}}
				}
			}
		}
	}

	return true, nil
}

// ImproveFeasibility is the main entry point for Strategy B.
// It will orchestrate different adjustment functions to make the plan feasible.
func ImproveFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) {
	fmt.Println("\n👷 [STRATEGY B] Orchestrating feasibility improvements...")

	// 1. Check for Timeline errors first (Sequence Validation)
	timelineErrors := ValidateOrderWindows(orders)
	if len(timelineErrors) > 0 {
		fmt.Printf("❌ Cannot proceed with manpower adjustments. Found %d bags with incorrect date sequences.\n", len(timelineErrors))
		fmt.Println("   (Example: Polishing scheduled to end before Filing ends + 1 day gap)")
		fmt.Println("   Please fix the Excel dates for these bags first.")
		return
	}

	// 2. Adjust Manpower (Strategy B1)
	adjustments := AdjustManpower(orders, factoryMaster)

	if len(adjustments) == 0 {
		fmt.Println("✅ No manpower adjustments needed beyond fixing any initial bottlenecks.")
		return
	}

	fmt.Printf("⚠️  Target achieved: Identified %d unique adjustment points resolving failures for multiple bags.\n", len(adjustments))

	// Group and Print Summary
	type adjKey struct {
		F string
		P string
		D string
	}
	type adjStat struct {
		Hrs      float64
		BagCount int
	}
	summary := make(map[adjKey]*adjStat)
	for _, adj := range adjustments {
		k := adjKey{adj.Factory, adj.Process, adj.Date.Format("02/01/2006")}
		if summary[k] == nil {
			summary[k] = &adjStat{}
		}
		summary[k].Hrs += adj.Deficit
		count, _ := strconv.Atoi(adj.BagNo) // We stored the count here
		summary[k].BagCount += count
	}

	totalExtraHrs := 0.0
	fmt.Println("\nSuggested Manpower Increases (Shift = 8h):")
	for k, stat := range summary {
		baseCap := 0.0
		if f, ok := factoryMaster[k.F]; ok {
			baseCap = f.ProcessCapacity[k.P]
		}
		workers := stat.Hrs / 8.0
		totalExtraHrs += stat.Hrs
		fmt.Printf("    → %-20s [%-12s] on %10s: Cap:%6.2f | Add %6.2f hrs (~%4.2f workers) | %3d bags\n",
			k.F, k.P, k.D, baseCap, stat.Hrs, workers, stat.BagCount)
	}

	fmt.Printf("\nTOTAL ADDITIONAL MAN-HOURS REQUIRED: %.2f hrs (~%.1f full-shift worker equivalent)\n",
		totalExtraHrs, totalExtraHrs/8.0)
}

// AdjustManpower calculates the total extra capacity (hours) needed on specific days
// to make the schedule feasible in one pass by "granting" required deficit.
func AdjustManpower(orders []models.Order, factoryMaster map[string]models.Factory) []models.Overload {
	var results []models.Overload

	// We'll track dynamically added capacity locally to this simulation
	extraCapacity := make(map[string]map[time.Time]float64) // Source -> Date -> AddedHrs

	remainingHrs := make(map[string]map[string]float64)
	for _, o := range orders {
		key := o.GetBagKey()
		remainingHrs[key] = make(map[string]float64)
		for pName, pInfo := range o.Processes {
			remainingHrs[key][pName] = pInfo.WorkingHrs
		}
	}

	for _, pName := range ProcessSequence {
		var minDate, maxDate time.Time
		first := true
		for _, o := range orders {
			if pInfo, ok := o.Processes[pName]; ok {
				if first || pInfo.StartDate.Before(minDate) {
					minDate = pInfo.StartDate
				}
				if first || pInfo.EndDate.After(maxDate) {
					maxDate = pInfo.EndDate
				}
				first = false
			}
		}

		if minDate.IsZero() {
			continue
		}

		for currentDate := minDate; !currentDate.After(maxDate); currentDate = currentDate.AddDate(0, 0, 1) {
			activeBySource := make(map[string][]*models.Order)
			for i := range orders {
				o := &orders[i]
				pInfo, ok := o.Processes[pName]
				if ok && !currentDate.Before(pInfo.StartDate) &&
					!currentDate.After(pInfo.EndDate) &&
					remainingHrs[o.GetBagKey()][pName] > 0 {
					source := resolveCapacitySource(pName, o)
					activeBySource[source] = append(activeBySource[source], o)
				}
			}

			// For each factory source on this date
			for source, active := range activeBySource {
				f, hasFactory := factoryMaster[source]
				baseCap := 0.0
				if hasFactory {
					baseCap = f.ProcessCapacity[pName]
				}

				added := 0.0
				if extraCapacity[source] != nil {
					added = extraCapacity[source][currentDate]
				}

				effectiveCap := baseCap + added

				pRemaining := make(map[string]float64)
				for _, o := range active {
					key := o.GetBagKey()
					pRemaining[key] = remainingHrs[key][pName]
				}

				ok, def, culpritKey := DistributeWithSlackEDF(active, pRemaining, currentDate, func(o *models.Order) time.Time {
					return o.Processes[pName].EndDate
				}, effectiveCap)

				if ok {
					oNo, _ := models.ParseBagKey(culpritKey)
					results = append(results, models.Overload{
						Factory: source,
						Process: pName,
						Date:    currentDate,
						Deficit: def,
						OrderNo: oNo,
						BagNo:   strconv.Itoa(len(active)), // Pass count of affected bags
					})

					// "Grant" the capacity so we can continue checking
					if extraCapacity[source] == nil {
						extraCapacity[source] = make(map[time.Time]float64)
					}
					extraCapacity[source][currentDate] += def
					effectiveCap += def

					// Re-run the distribution for this day WITH the new capacity to advance the state correctly
					DistributeWithSlackEDF(active, pRemaining, currentDate, func(o *models.Order) time.Time {
						return o.Processes[pName].EndDate
					}, effectiveCap)
				}

				// Update global state
				for _, o := range active {
					key := o.GetBagKey()
					remainingHrs[key][pName] = pRemaining[key]
				}
			}
		}
	}

	return results
}

func resolveCapacitySource(pName string, o *models.Order) string {
	switch pName {
	case "waxing":
		return "Waxing"
	case "waxsetting":
		if o.OrderType == "mined" {
			return "Waxsetting (mined)"
		}
		return "Waxsetting (lgd)"
	case "srd_split":
		if o.OrderType == "mined" {
			return "SRD_SPLIT (mined)"
		}
		return "SRD_SPLIT (lgd)"
	default:
		return o.Factory
	}
}

func ValidateOrderWindows(orders []models.Order) []models.Overload {
	var overloads []models.Overload
	for _, o := range orders {
		for pName, pInfo := range o.Processes {
			if !pInfo.EndDate.IsZero() && pInfo.StartDate.After(pInfo.EndDate) {
				overloads = append(overloads, models.Overload{
					Factory: resolveCapacitySource(pName, &o),
					Process: pName,
					Date:    pInfo.StartDate,
					Deficit: 999,
					OrderNo: o.OrderNo,
					BagNo:   o.BagNo,
				})
			}
		}
	}
	return overloads
}

func ResolveByRemovingOrders(orders []models.Order, factoryMaster map[string]models.Factory) ([]string, bool) {
	fmt.Println("🚀 Identifying bags to remove to restore feasibility...")
	currentOrders := make([]models.Order, len(orders))
	copy(currentOrders, orders)
	var removedBags []string
	for {
		ok, overloads := CheckFeasibility(currentOrders, factoryMaster)
		if ok {
			return removedBags, true
		}
		culprit := overloads[0].BagNo
		if culprit == "" {
			culprit = overloads[0].OrderNo // Fallback
		}

		fmt.Printf("❌ Bottleneck detected! Suggested removal: Bag %s (Order %s)\n", culprit, overloads[0].OrderNo)
		removedBags = append(removedBags, culprit)

		newOrders := []models.Order{}
		for _, o := range currentOrders {
			// Check if this bag matches the culprit
			if o.BagNo != culprit || (o.BagNo == "" && o.OrderNo != culprit) {
				newOrders = append(newOrders, o)
			}
		}
		currentOrders = newOrders
		if len(currentOrders) == 0 {
			break
		}
	}
	return removedBags, false
}
