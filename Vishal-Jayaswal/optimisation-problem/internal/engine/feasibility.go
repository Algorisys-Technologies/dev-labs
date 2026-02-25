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

			if ok, def := DistributeWithSlackEDF(activeFil, remainingFilHrs, currentDate, func(o *models.Order) time.Time { return o.PolishingStartDate }, f.DailyFilManHours); ok {
				return false, []models.Overload{{Factory: factoryName, Process: "Filing", Date: currentDate, Deficit: def}}
			}
		}
	}

	return true, nil
}

func CheckFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) (bool, []models.Overload) {
	var overloads []models.Overload

	// Initial Validation (Filing → Polishing → FQC)
	if windowErrors := ValidateOrderWindows(orders); len(windowErrors) > 0 {
		return false, windowErrors
	}

	// Group orders by factory
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
			for _, o := range fOrders {
				if (currentDate.Equal(o.FilingStartDate) || currentDate.After(o.FilingStartDate)) &&
					currentDate.Before(o.PolishingStartDate) &&
					remainingFilHrs[o.OrderNo] > 0 {
					activeFil = append(activeFil, o)
				}
			}
			if ok, def := DistributeWithSlackEDF(activeFil, remainingFilHrs, currentDate, func(o *models.Order) time.Time { return o.PolishingStartDate }, f.FilManHours); ok {
				overloads = append(overloads, models.Overload{Factory: factoryName, Process: "Filing", Date: currentDate, Deficit: def})
			}

			// --- Polishing ---
			activePol := []*models.Order{}
			for _, o := range fOrders {
				if (currentDate.Equal(o.PolishingStartDate) || currentDate.After(o.PolishingStartDate)) &&
					currentDate.Before(o.FQCStartDate) &&
					remainingPolHrs[o.OrderNo] > 0 {
					activePol = append(activePol, o)
				}
			}
			if ok, def := DistributeWithSlackEDF(activePol, remainingPolHrs, currentDate, func(o *models.Order) time.Time { return o.FQCStartDate }, f.PolManHours); ok {
				overloads = append(overloads, models.Overload{Factory: factoryName, Process: "Polishing", Date: currentDate, Deficit: def})
			}
		}
	}

	// --- FQC ---
	if fqcFactory, ok := factoryMaster["FQC"]; ok {
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
				if (currentDate.Equal(o.FQCStartDate) || currentDate.After(o.FQCStartDate)) &&
					!currentDate.After(o.OrderEndDate) &&
					remainingFQCHrs[o.OrderNo] > 0 {
					activeFQC = append(activeFQC, o)
				}
			}
			if ok, def := DistributeWithSlackEDF(activeFQC, remainingFQCHrs, currentDate, func(o *models.Order) time.Time { return o.OrderEndDate }, fqcFactory.FQCManHours); ok {
				overloads = append(overloads, models.Overload{Factory: "FQC", Process: "FQC", Date: currentDate, Deficit: def})
			}
		}
	}

	if len(overloads) > 0 {
		return false, overloads
	}
	return true, nil
}

func ValidateOrderWindows(orders []models.Order) []models.Overload {
	var overloads []models.Overload
	for _, o := range orders {
		if !o.FilingStartDate.Before(o.PolishingStartDate) {
			overloads = append(overloads, models.Overload{Factory: o.Factory, Process: "Filing", Date: o.FilingStartDate, Deficit: 999})
		}
		if !o.PolishingStartDate.Before(o.FQCStartDate) {
			overloads = append(overloads, models.Overload{Factory: o.Factory, Process: "Polishing", Date: o.PolishingStartDate, Deficit: 999})
		}
		if !o.FQCStartDate.Before(o.OrderEndDate) {
			overloads = append(overloads, models.Overload{Factory: "FQC", Process: "FQC", Date: o.FQCStartDate, Deficit: 999})
		}
	}
	return overloads
}

func ImproveFeasibility(orders []models.Order, factories map[string]models.Factory, initialOverloads []models.Overload) bool {
	fmt.Println("⚙️ Iteratively increasing manpower to resolve all bottlenecks...")

	initial := make(map[string]models.Factory)
	maps.Copy(initial, factories)

	lastTotalDeficit := 0.0
	for i := 1; i <= 100; i++ {
		ok, currentOverloads := CheckFeasibility(orders, factories)
		if ok {
			fmt.Printf("✅ Feasibility restored after %d iteration(s)!\n", i-1)
			PrintManpowerSummary(initial, factories)
			return true
		}

		// Calculate total deficit for progress checking
		currentTotalDeficit := 0.0
		for _, o := range currentOverloads {
			currentTotalDeficit += o.Deficit
		}

		// If we made NO progress, we might be stuck
		if i > 1 && currentTotalDeficit >= lastTotalDeficit && lastTotalDeficit > 0 {
			fmt.Println("⚠️ Warning: No progress detected. Manpower alone may not solve this.")
		}
		lastTotalDeficit = currentTotalDeficit

		IncreaseManpower(factories, currentOverloads)
	}

	fmt.Println("❌ Still infeasible after limit reached.")
	PrintManpowerSummary(initial, factories)
	return false
}

func IncreaseManpower(factories map[string]models.Factory, overloads []models.Overload) {
	// Aggregate overloads: Find the MAXIMUM deficit per Factory/Process pair
	type key struct {
		factory string
		process string
	}
	maxDeficits := make(map[key]float64)

	for _, o := range overloads {
		k := key{o.Factory, o.Process}
		if o.Deficit > maxDeficits[k] {
			maxDeficits[k] = o.Deficit
		}
	}

	// Apply only the maximum found deficit for each pair
	for k, deficit := range maxDeficits {
		f := factories[k.factory]
		switch k.process {
		case "Filing":
			f.FilManHours += deficit
			fmt.Printf("+ Filing:    +%.2f hrs/day bottleneck at %s\n", deficit, k.factory)
		case "Polishing":
			f.PolManHours += deficit
			fmt.Printf("+ Polishing: +%.2f hrs/day bottleneck at %s\n", deficit, k.factory)
		case "FQC":
			f.FQCManHours += deficit
			fmt.Printf("+ FQC:       +%.2f hrs/day bottleneck at %s\n", deficit, k.factory)
		}
		factories[k.factory] = f
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
