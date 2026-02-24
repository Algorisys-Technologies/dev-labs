package engine

import (
	"fmt"
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
				Process: "Filing window infeasible",
				Date:    o.PolishingStartDate,
				Excess:  o.FilWorkingHrs - maxFilManHoursCapacity,
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

			if DistributeWithSlackEDF(activeFil, remainingFilHrs, currentDate, func(o *models.Order) time.Time { return o.PolishingStartDate }, f.DailyFilManHours) {
				return false, []models.Overload{{Factory: factoryName, Process: "Filing overload", Date: currentDate}}
			}
		}
	}

	return true, nil
}

func CheckFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) (bool, []models.Overload) {

	// Fast "sanity check" before running the daily shared-capacity simulation to ensure individual orders are theoretically possible
	windowOverloads := CheckPerOrderWindowFeasibility(orders, factoryMaster)
	if len(windowOverloads) > 0 {
		return false, windowOverloads
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
			totalRemainingFilHrs := 0.0

			// Find all filing orders that are active on the current date and find their total remaining work
			for _, o := range fOrders {
				if currentDate.Before(o.FilingStartDate) ||
					!currentDate.Before(o.PolishingStartDate) ||
					remainingFilHrs[o.OrderNo] <= 0 {
					continue
				}
				activeFil = append(activeFil, o)
				totalRemainingFilHrs += remainingFilHrs[o.OrderNo]
			}

			filCapacity := f.FilManHours
			if DistributeWithSlackEDF(activeFil, remainingFilHrs, currentDate, func(o *models.Order) time.Time { return o.PolishingStartDate }, filCapacity) {
				return false, []models.Overload{{Factory: factoryName, Process: "Filing overload", Date: currentDate}}
			}

			// --- Polishing ---
			activePol := []*models.Order{}
			totalRemainingPolHrs := 0.0

			// Find all polishing orders that are active on the current date and find their total remaining work
			for _, o := range fOrders {
				if currentDate.Before(o.PolishingStartDate) ||
					!currentDate.Before(o.FQCStartDate) ||
					remainingPolHrs[o.OrderNo] <= 0 {
					continue
				}
				activePol = append(activePol, o)
				totalRemainingPolHrs += remainingPolHrs[o.OrderNo]
			}

			polCapacity := f.PolManHours
			if DistributeWithSlackEDF(activePol, remainingPolHrs, currentDate, func(o *models.Order) time.Time { return o.FQCStartDate }, polCapacity) {
				return false, []models.Overload{{Factory: factoryName, Process: "Polishing overload", Date: currentDate}}
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
		totalFQCRemaining := 0.0

		for i := range orders {
			o := &orders[i]
			if currentDate.Before(o.FQCStartDate) || currentDate.After(o.OrderEndDate) || remainingFQCHrs[o.OrderNo] <= 0 {
				continue
			}
			activeFQC = append(activeFQC, o)
			totalFQCRemaining += remainingFQCHrs[o.OrderNo]
		}

		fqcCapacity := fqcFactory.FQCManHours
		if DistributeWithSlackEDF(activeFQC, remainingFQCHrs, currentDate, func(o *models.Order) time.Time { return o.OrderEndDate }, fqcCapacity) {
			return false, []models.Overload{{Factory: "FQC", Process: "FQC overload", Date: currentDate}}
		}
	}

	for _, o := range orders {
		if remainingFilHrs[o.OrderNo] > 0.01 {
			fmt.Printf("Order %s incomplete: Filing short\n", o.OrderNo)
			return false, overloads
		}
		if remainingPolHrs[o.OrderNo] > 0.01 {
			fmt.Printf("Order %s incomplete: Polishing short\n", o.OrderNo)
			return false, overloads
		}
		if remainingFQCHrs[o.OrderNo] > 0.01 {
			fmt.Printf("Order %s incomplete: FQC short\n", o.OrderNo)
			return false, overloads
		}
	}

	return true, overloads
}

// Fast "sanity check" before running the daily shared-capacity simulation
func CheckPerOrderWindowFeasibility(orders []models.Order, factoryMaster map[string]models.Factory) []models.Overload {
	var overloads []models.Overload
	fqcFactory := factoryMaster["FQC"]

	for _, o := range orders {
		f := factoryMaster[o.Factory]

		filingDays := int(o.PolishingStartDate.Sub(o.FilingStartDate).Hours() / 24)
		if filingDays < 0 {
			filingDays = 0
		}
		maxFilCapacity := float64(filingDays) * f.FilManHours

		if o.FilWorkingHrs > maxFilCapacity {
			overloads = append(overloads, models.Overload{
				Factory: o.Factory,
				Process: "Filing window infeasible",
				Date:    o.PolishingStartDate,
				Excess:  o.FilWorkingHrs - maxFilCapacity,
			})
		}

		polishingDays := int(o.FQCStartDate.Sub(o.PolishingStartDate).Hours() / 24)
		if polishingDays < 0 {
			polishingDays = 0
		}
		maxPolCapacity := float64(polishingDays) * f.PolManHours

		if o.PolWorkingHrs > maxPolCapacity {
			overloads = append(overloads, models.Overload{
				Factory: o.Factory,
				Process: "Polishing window infeasible",
				Date:    o.FQCStartDate,
				Excess:  o.PolWorkingHrs - maxPolCapacity,
			})
		}

		fqcDays := int(o.OrderEndDate.Sub(o.FQCStartDate).Hours() / 24)
		if fqcDays < 0 {
			fqcDays = 0
		}
		maxFQCCapacity := float64(fqcDays) * fqcFactory.FQCManHours

		if o.FQCWorkingHrs > maxFQCCapacity {
			overloads = append(overloads, models.Overload{
				Factory: "FQC",
				Process: "FQC window infeasible",
				Date:    o.OrderEndDate,
				Excess:  o.FQCWorkingHrs - maxFQCCapacity,
			})
		}
	}

	return overloads
}

func ImproveFeasibility(orders []models.Order, factories map[string]models.Factory, overloads []models.Overload) bool {
	fmt.Println("⚙️ Attempting to improve feasibility...")

	// 1. Increase Manpower
	IncreaseManpower(factories, overloads)

	ok, _ := CheckFeasibility(orders, factories)
	if ok {
		fmt.Println("✅ Feasible after manpower increase")
		return true
	}
	fmt.Println("❌ Still infeasible after manpower increase")

	// 2. Factory Reallocation
	// 3. Overtime

	return false
}

func IncreaseManpower(factories map[string]models.Factory, overloads []models.Overload) {

}
