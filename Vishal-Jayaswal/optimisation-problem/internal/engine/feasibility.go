package engine

import (
	"fmt"
	"time"

	"optimisation-problem/internal/models"
)

// var ProcessSequence = []string{"waxing", "waxsetting", "srd_split", "filing", "polishing"}
var ProcessSequence = []string{"filing"}

func CheckFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) (bool, []models.Overload) {
	// 1. Process sequence validation (Timeline errors like StartDate > EndDate must be fixed first)
	if overloads := ValidateOrderWindows(orders); len(overloads) > 0 {
		return false, overloads
	}

	// 2. Perform a complete simulation to find all required manpower adjustments
	results := AnalyzeRequiredManpower(orders, factoryMaster)

	return len(results) == 0, results
}

// ImproveFeasibility is the main entry point for Strategy B.
// It will orchestrate different adjustment functions to make the plan feasible.
func ImproveFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) {
	fmt.Println("\n👷 [STRATEGY B] Orchestrating feasibility improvements...")

	// 1. Check for Timeline errors first (Sequence Validation)
	timelineErrors := ValidateOrderWindows(orders)
	if len(timelineErrors) > 0 {
		fmt.Printf("❌ Cannot proceed. Found %d bags with incorrect date sequences.\n", len(timelineErrors))
		return
	}

	// 2. Initial Analysis
	adjustments := AnalyzeRequiredManpower(orders, factoryMaster)

	if len(adjustments) == 0 {
		fmt.Println("✅ No manpower adjustments needed. The original plan is already feasible!")
		return
	}

	// 3. Group and Analyze by Process/Source
	type procKey struct {
		F string
		P string
	}
	type procStat struct {
		TotalMins     float64
		PeakMins      float64
		DaysAffected  int
		CumulativeDef map[time.Time]float64
		MinDate       time.Time
		MaxDate       time.Time
	}

	summary := make(map[procKey]*procStat)
	for _, o := range orders {
		for pName, pInfo := range o.Processes {
			source := resolveCapacitySource(pName, &o)
			pk := procKey{source, pName}
			if summary[pk] == nil {
				summary[pk] = &procStat{
					CumulativeDef: make(map[time.Time]float64),
					MinDate:       pInfo.StartDate,
					MaxDate:       pInfo.EndDate,
				}
			} else {
				if pInfo.StartDate.Before(summary[pk].MinDate) {
					summary[pk].MinDate = pInfo.StartDate
				}
				if pInfo.EndDate.After(summary[pk].MaxDate) {
					summary[pk].MaxDate = pInfo.EndDate
				}
			}
		}
	}

	for _, adj := range adjustments {
		pk := procKey{adj.Factory, adj.Process}
		stat := summary[pk]
		if stat == nil {
			continue
		}
		stat.TotalMins += adj.Deficit
		stat.DaysAffected++
		if adj.Deficit > stat.PeakMins {
			stat.PeakMins = adj.Deficit
		}
	}

	fmt.Println("\n--- MANPOWER REQUIREMENTS SUMMARY (Incremental Additions) ---")
	fmt.Printf("%-25s | %-12s | %-12s | %-12s | %-8s\n", "Source/Factory", "Total Extra", "Total Shifts", "Constant Addition", "Impact")
	fmt.Println("----------------------------------------------------------------------------------------------------------")

	// We'll prepare an augmented factory master based on recommendations
	recommendedMaster := make(map[string]models.Factory)
	for k, v := range factoryMaster {
		newCap := make(map[string]float64)
		for p, c := range v.ProcessCapacity {
			newCap[p] = c
		}
		recommendedMaster[k] = models.Factory{Name: v.Name, ProcessCapacity: newCap}
	}

	for k, stat := range summary {
		if stat.TotalMins == 0 {
			continue
		}

		duration := int(stat.MaxDate.Sub(stat.MinDate).Hours()/24) + 1
		if duration < 1 {
			duration = 1
		}

		// Calculate required headcount addition for the entire schedule duration
		// This is roughly TotalMins / (duration * 480)
		avgHeadcount := stat.TotalMins / (float64(duration) * 480.0)
		peakHeadcount := stat.PeakMins / 480.0

		// We recommend the Ceil of avgHeadcount but caution about peak
		recommendedAdd := float64(int(avgHeadcount + 0.999)) // Ceil
		if recommendedAdd < 1 && stat.TotalMins > 0 {
			recommendedAdd = 1
		}

		fmt.Printf("%-25s | %8.1f mins | %8.1f     | %4.1f workers | %d days span (Peak: %.1f)\n",
			k.F+" ["+k.P+"]", stat.TotalMins, stat.TotalMins/480.0, recommendedAdd, duration, peakHeadcount)

		// Apply to recommendation
		f := recommendedMaster[k.F]
		if f.ProcessCapacity == nil {
			// This covers sources that were virtual (like Waxing) but aren't in factoryMaster
			f.Name = k.F
			f.ProcessCapacity = make(map[string]float64)
		}
		f.ProcessCapacity[k.P] += recommendedAdd * 480.0
		recommendedMaster[k.F] = f
	}

	// 4. Final Verification Pass (PROVE it works with constant additions)
	fmt.Println("\n🔎 [VERIFICATION] Testing the plan with these suggested additions...")
	verificationResults := AnalyzeRequiredManpower(orders, recommendedMaster)

	if len(verificationResults) == 0 {
		fmt.Println("✅ SUCCESS: Adding the suggested workers for the entire schedule makes the plan 100% FEASIBLE.")
	} else {
		fmt.Printf("⚠️  PARTIAL FEASIBILITY: Even with suggested additions, %d bottleneck points remain.\n", len(verificationResults))
		fmt.Println("   The workload distribution may be too concentrated for a constant headcount increase.")
		fmt.Println("   Consider adding more workers during peak periods or shifting order dates.")
	}
}

// AdjustManpower calculates the total extra capacity (hours) needed on specific days
// to make the schedule feasible in one pass by "granting" required deficit.
func AdjustManpower(orders []models.Order, factoryMaster map[string]models.Factory) []models.Overload {
	return AnalyzeRequiredManpower(orders, factoryMaster)
}

// AnalyzeRequiredManpower calculates the total extra capacity (hours) needed on all days
// to make the entire schedule feasible by "granting" required deficit locally and proceeding.
func AnalyzeRequiredManpower(orders []models.Order, factoryMaster map[string]models.Factory) []models.Overload {
	var results []models.Overload

	// Each bag-process remaining minutes
	remainingMins := make(map[string]map[string]float64)
	for _, o := range orders {
		key := o.GetBagKey()
		remainingMins[key] = make(map[string]float64)
		for pName, pInfo := range o.Processes {
			remainingMins[key][pName] = pInfo.WorkingMins
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
			activeBySource := make(map[string][]*models.Order) // Factory -> Orders
			for i := range orders {
				o := &orders[i]
				pInfo, ok := o.Processes[pName]
				if ok && !currentDate.Before(pInfo.StartDate) &&
					!currentDate.After(pInfo.EndDate) &&
					remainingMins[o.GetBagKey()][pName] > 0 {
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

				effectiveCap := baseCap

				// Loop until this day/source is feasible
				dailyDeficit := 0.0
				lastCulpritKey := ""
				for {
					pRemaining := make(map[string]float64)
					for _, o := range active {
						key := o.GetBagKey()
						pRemaining[key] = remainingMins[key][pName]
					}

					overload, def, culpritKey := DistributeWithSlackEDF(
						active,
						pRemaining,
						currentDate,
						func(o *models.Order) time.Time {
							return o.Processes[pName].EndDate
						},
						effectiveCap,
					)

					if !overload {
						// Success! Day is feasible with current capacity.
						// Update global remaining hours and move to next source/day
						for _, o := range active {
							key := o.GetBagKey()
							remainingMins[key][pName] = pRemaining[key]
						}
						break
					}

					// Bottleneck found! Record it and "Grant" the capacity for the rest of the simulation.
					dailyDeficit += def
					lastCulpritKey = culpritKey
					effectiveCap += def
				}

				if dailyDeficit > 0 {
					oNo, bNo := models.ParseBagKey(lastCulpritKey)
					results = append(results, models.Overload{
						Factory:      source,
						Process:      pName,
						Date:         currentDate,
						Deficit:      dailyDeficit,
						OrderNo:      oNo,
						BagNo:        bNo,
						AffectedBags: len(active),
					})
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
