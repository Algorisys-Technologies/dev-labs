package engine

import (
	"fmt"
	"maps"
	"math"
	"time"

	"optimisation-problem/internal/models"
)

func CheckFeasibilitySimple(orders []models.Order, factoryMaster map[string]models.Factory2) (bool, []models.Overload) {
	// 1. Static Window Check (Filing Only)
	var overloads []models.Overload
	for _, o := range orders {
		f, ok := factoryMaster[o.Factory]
		if !ok {
			continue
		}
		filingDays := int(o.PolishingStartDate.Sub(o.FilingStartDate).Hours() / 24)
		if filingDays < 1 {
			filingDays = 1
		}
		maxFilManHoursCapacity := float64(filingDays) * f.DailyFilManHours
		if o.FilWorkingHrs > maxFilManHoursCapacity {
			overloads = append(overloads, models.Overload{
				Factory: o.Factory,
				Process: "Filing",
				Date:    o.PolishingStartDate,
				Deficit: (o.FilWorkingHrs - maxFilManHoursCapacity) / float64(filingDays),
				OrderNo: o.OrderNo,
			})
		}
	}
	if len(overloads) > 0 {
		return false, overloads
	}

	// 2. Daily Simulation (Filing Only)
	remainingFilHrs := make(map[string]float64)
	factoryWiseOrders := make(map[string][]*models.Order)
	for i := range orders {
		o := &orders[i]
		remainingFilHrs[o.OrderNo] = o.FilWorkingHrs
		factoryWiseOrders[o.Factory] = append(factoryWiseOrders[o.Factory], o)
	}

	for factoryName, f := range factoryMaster {
		fOrders := factoryWiseOrders[factoryName]
		if len(fOrders) == 0 {
			continue
		}

		minDate := fOrders[0].FilingStartDate
		maxDate := fOrders[0].PolishingStartDate
		for _, o := range fOrders {
			if o.FilingStartDate.Before(minDate) {
				minDate = o.FilingStartDate
			}
			if o.PolishingStartDate.After(maxDate) {
				maxDate = o.PolishingStartDate
			}
		}

		for currentDate := minDate; currentDate.Before(maxDate); currentDate = currentDate.AddDate(0, 0, 1) {
			activeFil := []*models.Order{}
			for _, o := range fOrders {
				if (currentDate.Equal(o.FilingStartDate) || currentDate.After(o.FilingStartDate)) &&
					currentDate.Before(o.PolishingStartDate) &&
					remainingFilHrs[o.OrderNo] > 0 {
					activeFil = append(activeFil, o)
				}
			}

			if ok, def, oNo := DistributeWithSlackEDF(activeFil, remainingFilHrs, currentDate, func(o *models.Order) time.Time { return o.PolishingStartDate }, f.DailyFilManHours); ok {
				return false, []models.Overload{{Factory: factoryName, Process: "Filing", Date: currentDate, Deficit: def, OrderNo: oNo}}
			}
		}
	}

	return true, nil
}

func CheckFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) (bool, []models.Overload) {

	// Initial Validation: Ensure all orders have valid working windows (Start < End)
	if overloads := ValidateOrderWindows(orders); len(overloads) > 0 {
		return false, overloads
	}

	var overloads []models.Overload

	fqcFactory, ok := factoryMaster["FQC"]
	if !ok {
		fmt.Println("❌ FQC factory not found")
		return false, nil
	}

	factoryWiseOrders := make(map[string][]*models.Order)
	for i := range orders {
		o := &orders[i]
		factoryWiseOrders[o.Factory] = append(factoryWiseOrders[o.Factory], o)
	}

	remainingFilHrs := make(map[string]float64)
	remainingPolHrs := make(map[string]float64)
	remainingFQCHrs := make(map[string]float64)

	for _, o := range orders {
		remainingFilHrs[o.OrderNo] = o.FilWorkingHrs
		remainingPolHrs[o.OrderNo] = o.PolWorkingHrs
		remainingFQCHrs[o.OrderNo] = o.FQCWorkingHrs
	}

	for factoryName, f := range factoryMaster {
		if factoryName == "FQC" {
			continue
		}

		fOrders := factoryWiseOrders[factoryName]
		if len(fOrders) == 0 {
			continue
		}

		minDate := fOrders[0].FilingStartDate
		maxDate := fOrders[0].FQCStartDate.AddDate(0, 0, -1)

		for _, o := range fOrders {
			if o.FilingStartDate.Before(minDate) {
				minDate = o.FilingStartDate
			}
			if o.FQCStartDate.AddDate(0, 0, -1).After(maxDate) {
				maxDate = o.FQCStartDate.AddDate(0, 0, -1)
			}
		}

		for currentDate := minDate; !currentDate.After(maxDate); currentDate = currentDate.AddDate(0, 0, 1) {
			// --- Filing ---
			activeFil := []*models.Order{}

			// Find all filing orders that are active on the current date and find their total remaining work
			for _, o := range fOrders {
				if currentDate.Before(o.FilingStartDate) ||
					!currentDate.Before(o.PolishingStartDate) ||
					remainingFilHrs[o.OrderNo] <= 0 {
					continue
				}
				activeFil = append(activeFil, o)
			}

			filCapacity := f.FilManHours
			if ok, def, oNo := DistributeWithSlackEDF(activeFil, remainingFilHrs, currentDate, func(o *models.Order) time.Time { return o.PolishingStartDate }, filCapacity); ok {
				return false, []models.Overload{{Factory: factoryName, Process: "Filing", Date: currentDate, Deficit: def, OrderNo: oNo}}
			}

			// --- Polishing ---
			activePol := []*models.Order{}

			// Find all polishing orders that are active on the current date and find their total remaining work
			for _, o := range fOrders {
				if currentDate.Before(o.PolishingStartDate) ||
					!currentDate.Before(o.FQCStartDate) ||
					remainingPolHrs[o.OrderNo] <= 0 {
					continue
				}
				activePol = append(activePol, o)
			}

			polCapacity := f.PolManHours
			if ok, def, oNo := DistributeWithSlackEDF(activePol, remainingPolHrs, currentDate, func(o *models.Order) time.Time { return o.FQCStartDate }, polCapacity); ok {
				return false, []models.Overload{{Factory: factoryName, Process: "Polishing", Date: currentDate, Deficit: def, OrderNo: oNo}}
			}
		}
	}

	var minDateFQC, maxDateFQC time.Time
	first := true

	for _, o := range orders {
		if first || o.FQCStartDate.Before(minDateFQC) {
			minDateFQC = o.FQCStartDate
		}
		if first || o.OrderEndDate.After(maxDateFQC) {
			maxDateFQC = o.OrderEndDate
		}
		first = false
	}

	for currentDate := minDateFQC; !currentDate.After(maxDateFQC); currentDate = currentDate.AddDate(0, 0, 1) {
		activeFQC := []*models.Order{}

		for i := range orders {
			o := &orders[i]
			if currentDate.Before(o.FQCStartDate) || currentDate.After(o.OrderEndDate) || remainingFQCHrs[o.OrderNo] <= 0 {
				continue
			}
			activeFQC = append(activeFQC, o)
		}

		fqcCapacity := fqcFactory.FQCManHours
		if ok, def, oNo := DistributeWithSlackEDF(activeFQC, remainingFQCHrs, currentDate, func(o *models.Order) time.Time { return o.OrderEndDate }, fqcCapacity); ok {
			return false, []models.Overload{{Factory: "FQC", Process: "FQC", Date: currentDate, Deficit: def, OrderNo: oNo}}
		}
	}

	return true, overloads
}

func ValidateOrderWindows(orders []models.Order) []models.Overload {
	var overloads []models.Overload
	for _, o := range orders {
		if !o.FilingStartDate.Before(o.PolishingStartDate) {
			overloads = append(overloads, models.Overload{Factory: o.Factory, Process: "Filing", Date: o.FilingStartDate, Deficit: 999, OrderNo: o.OrderNo})
		}
		if !o.PolishingStartDate.Before(o.FQCStartDate) {
			overloads = append(overloads, models.Overload{Factory: o.Factory, Process: "Polishing", Date: o.PolishingStartDate, Deficit: 999, OrderNo: o.OrderNo})
		}
		if !o.FQCStartDate.Before(o.OrderEndDate) {
			overloads = append(overloads, models.Overload{Factory: "FQC", Process: "FQC", Date: o.FQCStartDate, Deficit: 999, OrderNo: o.OrderNo})
		}
	}
	return overloads
}

func ImproveFeasibility(orders []models.Order, factories map[string]models.Factory, overloads []models.Overload) bool {
	fmt.Println("⚙️ Iteratively increasing manpower to resolve all bottlenecks...")

	// Snapshot initial capacity to show total added workers later
	initial := make(map[string]models.Factory)
	maps.Copy(initial, factories)

	for i := 1; i <= 2000; i++ {
		ok, currentOverloads := CheckFeasibility(orders, factories)
		if ok {
			fmt.Printf("✅ Feasibility restored after %d iteration(s)!\n", i-1)
			PrintManpowerSummary(initial, factories)
			return true
		}

		IncreaseManpower(factories, currentOverloads)
	}

	fmt.Println("❌ Still infeasible after 100 iterations.")
	PrintManpowerSummary(initial, factories)
	return false
}

func IncreaseManpower(factories map[string]models.Factory, overloads []models.Overload) {
	for _, o := range overloads {
		if o.Deficit < 0.001 {
			continue
		}
		f := factories[o.Factory]

		// Add exactly what is needed to bridge the gap in the simulation
		capacityToAdd := o.Deficit

		switch o.Process {
		case "Filing":
			f.FilManHours += capacityToAdd
			fmt.Printf("+ Filing: +%.2f hrs/day bottleneck at %s\n", capacityToAdd, o.Factory)

		case "Polishing":
			f.PolManHours += capacityToAdd
			fmt.Printf("+ Polishing: +%.2f hrs/day bottleneck at %s\n", capacityToAdd, o.Factory)

		case "FQC":
			f.FQCManHours += capacityToAdd
			fmt.Printf("+ FQC: +%.2f hrs/day bottleneck at %s\n", capacityToAdd, o.Factory)
		}

		factories[o.Factory] = f
	}
}

func PrintManpowerSummary(initial, final map[string]models.Factory) {
	const hoursInShift = 8.0
	fmt.Println("\n📊 MANPOWER SUMMARY (Headcount Required)")
	fmt.Println("--------------------------------------------------")
	fmt.Printf("%-15s %-10s %-10s %-10s %-10s\n", "Factory", "Process", "Initial", "Required", "Added")

	for name := range initial {
		f0 := initial[name]
		f1 := final[name]

		// We round INITIAL to nearest (assuming it was integer start)
		// but use CEIL for REQUIRED to ensure we cover the calculated deficit.
		if f1.FilManHours > f0.FilManHours {
			w0 := math.Round(f0.FilManHours / hoursInShift)
			w1 := math.Ceil(f1.FilManHours / hoursInShift)
			fmt.Printf("%-15s %-10s %-10.0f %-10.0f (+%.0f)\n",
				name, "Filing", w0, w1, w1-w0)
		}
		if f1.PolManHours > f0.PolManHours {
			w0 := math.Round(f0.PolManHours / hoursInShift)
			w1 := math.Ceil(f1.PolManHours / hoursInShift)
			fmt.Printf("%-15s %-10s %-10.0f %-10.0f (+%.0f)\n",
				name, "Polishing", w0, w1, w1-w0)
		}
		if f1.FQCManHours > f0.FQCManHours {
			w0 := math.Round(f0.FQCManHours / hoursInShift)
			w1 := math.Ceil(f1.FQCManHours / hoursInShift)
			fmt.Printf("%-15s %-10s %-10.0f %-10.0f (+%.0f)\n",
				name, "FQC", w0, w1, w1-w0)
		}
	}
	fmt.Println("--------------------------------------------------")
}

func ResolveByRemovingOrders(orders []models.Order, factoryMaster map[string]models.Factory) ([]string, bool) {
	fmt.Println("🚀 Identifying orders to remove to restore feasibility...")

	currentOrders := make([]models.Order, len(orders))
	copy(currentOrders, orders)

	var removedOrders []string

	for {
		ok, overloads := CheckFeasibility(currentOrders, factoryMaster)
		if ok {
			return removedOrders, true
		}

		// Take the first overload's OrderID as the candidate for removal
		culprit := overloads[0].OrderNo
		if culprit == "" {
			fmt.Println("⚠️ Overload detected but no specific order identified. Stopping.")
			return removedOrders, false
		}

		fmt.Printf("❌ Bottleneck detected! Suggested removal: Order %s\n", culprit)
		removedOrders = append(removedOrders, culprit)

		// Filter out the culprit order
		newOrders := []models.Order{}
		for _, o := range currentOrders {
			if o.OrderNo != culprit {
				newOrders = append(newOrders, o)
			}
		}
		currentOrders = newOrders

		if len(currentOrders) == 0 {
			break
		}
	}

	return removedOrders, false
}
