package main

import (
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/xuri/excelize/v2"
)

type Factory struct {
	Name        string
	FilManHours float64 // hours per day
	PolManHours float64 // hours per day
	FQCManHours float64 // hours per day

	AddFilManHours float64 // hours per day
	AddPolManHours float64 // hours per day
	AddFQCManHours float64 // hours per day
}

type Order struct {
	OrderNo            string
	Factory            string
	FilingStartDate    time.Time
	PolishingStartDate time.Time
	FQCStartDate       time.Time
	OrderEndDate       time.Time
	FilWorkingHrs      float64
	PolWorkingHrs      float64
	FQCWorkingHrs      float64
}

type Overload struct {
	Factory string
	Date    time.Time
	Process string // "Filing", "Polishing", "FQC"
	Excess  float64
}

type demand struct {
	order         *Order
	requiredToday float64
	deadline      time.Time
}

func main() {
	// Read factory capacity
	factoryMaster, err := readFactoriesFromExcel("factory-capacity.xlsx")
	if err != nil {
		log.Fatal(err)
	}

	// Read orders
	orders, err := readOrdersFromExcel("test-ppc-base-data.xlsx")
	if err != nil {
		log.Fatal(err)
	}

	// Check initial feasibility
	fmt.Println("🔍  Checking initial feasibility...")
	// ok, overloads := CheckFeasibility(orders, factoryMaster)
	ok, _ := CheckFeasibility(orders, factoryMaster)
	if ok {
		fmt.Println("✅  All orders are FEASIBLE")
		return
	}
	fmt.Println("❌  Orders are infeasible")

	// // Try to improve feasibility
	// ok = ImproveFeasibility(orders, factoryMaster, overloads)

	// if ok {
	// 	fmt.Println("🎉  Feasibility restored")
	// } else {
	// 	fmt.Println("💥  Could not restore feasibility")
	// }
}

func readFactoriesFromExcel(filename string) (map[string]Factory, error) {

	file, err := excelize.OpenFile(filename)
	if err != nil {
		wd, _ := os.Getwd()
		abs, _ := filepath.Abs(filename)
		return nil, fmt.Errorf("failed to open %s: %v (CWD: %s, Full Path: %s)", filename, err, wd, abs)
	}
	defer file.Close()

	rows, err := file.GetRows("Sheet1")
	if err != nil {
		return nil, err
	}

	factories := make(map[string]Factory)

	for i, row := range rows {

		if i == 0 || len(row) < 3 {
			continue
		}

		// Skip Total row
		if row[0] == "Total" {
			continue
		}

		filerCount, err1 := strconv.ParseFloat(strings.TrimSpace(row[1]), 64)
		polisherCount, err2 := strconv.ParseFloat(strings.TrimSpace(row[2]), 64)
		fqcCount, err3 := strconv.ParseFloat(strings.TrimSpace(row[3]), 64)

		addFilerCount, err4 := strconv.ParseFloat(strings.TrimSpace(row[4]), 64)
		addPolisherCount, err5 := strconv.ParseFloat(strings.TrimSpace(row[5]), 64)
		addFqcCount, err6 := strconv.ParseFloat(strings.TrimSpace(row[6]), 64)

		if err1 != nil || err2 != nil || err3 != nil || err4 != nil || err5 != nil || err6 != nil {
			return nil, fmt.Errorf("invalid numeric data in Factories row %d: (Col1: %q, Col2: %q, Col3: %q, Col4: %q, Col5: %q, Col6: %q)", i+1, row[1], row[2], row[3], row[4], row[5], row[6])
		}

		factories[row[0]] = Factory{
			Name:           strings.TrimSpace(row[0]),
			FilManHours:    filerCount * 8, // convert staff to hours/day
			PolManHours:    polisherCount * 8,
			FQCManHours:    fqcCount * 8,
			AddFilManHours: addFilerCount * 8,
			AddPolManHours: addPolisherCount * 8,
			AddFQCManHours: addFqcCount * 8,
		}
	}

	return factories, nil
}

func readOrdersFromExcel(filename string) ([]Order, error) {

	file, err := excelize.OpenFile(filename)
	if err != nil {
		wd, _ := os.Getwd()
		abs, _ := filepath.Abs(filename)
		return nil, fmt.Errorf("failed to open %s: %v (CWD: %s, Full Path: %s)", filename, err, wd, abs)
	}
	defer file.Close()

	rows, err := file.GetRows("BASE DATA")
	if err != nil {
		return nil, err
	}

	var orders []Order

	for i, row := range rows {
		if i == 0 {
			continue
		}
		// if len(row) < 7 {
		// 	continue
		// }

		filingStart, err1 := parseDate(row[56])
		polishingStart, err2 := parseDate(row[64])
		orderEnd, err3 := parseDate(row[70])
		filHrs, err4 := strconv.ParseFloat(strings.TrimSpace(row[161]), 64)
		polHrs, err5 := strconv.ParseFloat(strings.TrimSpace(row[162]), 64)
		fqcStart, err6 := parseDate(row[65])
		fqcHrs, err7 := strconv.ParseFloat(strings.TrimSpace(row[163]), 64)

		if err1 != nil || err2 != nil || err3 != nil || err4 != nil || err5 != nil || err6 != nil || err7 != nil {
			return nil, fmt.Errorf("invalid numeric data in Orders row %d: (Col3: %q, Col4: %q, Col5: %q, Col6: %q, Col7: %q, Col8: %q)",
				i+1, row[56], row[64], row[70], row[161], row[162], row[163])
		}

		orders = append(orders, Order{
			OrderNo:            strings.TrimSpace(row[89]),
			Factory:            strings.TrimSpace(row[87]),
			FilingStartDate:    filingStart,
			PolishingStartDate: polishingStart,
			FQCStartDate:       fqcStart,
			OrderEndDate:       orderEnd,
			FilWorkingHrs:      filHrs,
			PolWorkingHrs:      polHrs,
			FQCWorkingHrs:      fqcHrs,
		})
	}

	return orders, nil
}

// Feasibility Check
func CheckFeasibility(orders []Order, factoryMaster map[string]Factory) (bool, []Overload) {

	// Per-order window feasibility
	windowOverloads := CheckPerOrderWindowFeasibility(orders, factoryMaster)
	if len(windowOverloads) > 0 {
		return false, windowOverloads
	}

	var overloads []Overload

	// Separate FQC factory
	fqcFactory, ok := factoryMaster["FQC"]
	if !ok {
		fmt.Println("❌ FQC factory not found")
		return false, nil
	}

	// Group orders by factories
	factoryWiseOrders := make(map[string][]*Order)
	for i := range orders {
		o := &orders[i]
		factoryWiseOrders[o.Factory] = append(factoryWiseOrders[o.Factory], o)
	}

	// Track remaining work hrs for each order
	remainingFilHrs := make(map[string]float64)
	remainingPolHrs := make(map[string]float64)
	remainingFQCHrs := make(map[string]float64)

	// Initialize total remaining work (filing, polishing, fqc) for each order
	for _, o := range orders {
		remainingFilHrs[o.OrderNo] = o.FilWorkingHrs
		remainingPolHrs[o.OrderNo] = o.PolWorkingHrs
		remainingFQCHrs[o.OrderNo] = o.FQCWorkingHrs
	}

	// --------------------------------------------------
	// 🏭 STEP 1: Filing & Polishing per factory
	// --------------------------------------------------

	for factoryName, f := range factoryMaster {

		if factoryName == "FQC" {
			continue // skip FQC factory here
		}

		// Fetch all orders of the current factory
		fOrders := factoryWiseOrders[factoryName]
		if len(fOrders) == 0 {
			continue
		}

		// determine simulation window
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

		// Iterate through each day in the simulation window for Filing and Polishing
		for currentDate := minDate; !currentDate.After(maxDate); currentDate = currentDate.AddDate(0, 0, 1) { // maxDate is inclusive

			// ---------- Filing ----------
			activeFil := []*Order{}
			totalRemainingFilHrs := 0.0

			// Get current date active orders for filing
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
			// distributeWork(activeFil, remainingFil, totalFilRemaining, filCapacity)
			filOverloads := distributeEvenWithEDF(
				activeFil,
				remainingFilHrs,
				currentDate,
				func(o *Order) time.Time { return o.PolishingStartDate },
				filCapacity,
			)

			if filOverloads {
				return false, []Overload{{
					Factory: factoryName,
					Process: "Filing overload",
					Date:    currentDate,
				}}
			}

			// ---------- Polishing ----------
			activePol := []*Order{}
			totalRemainingPolHrs := 0.0

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
			// distributeWork(activePol, remainingPol, totalPolRemaining, polCapacity)
			polOverloads := distributeEvenWithEDF(
				activePol,
				remainingPolHrs,
				currentDate,
				func(o *Order) time.Time { return o.FQCStartDate },
				polCapacity,
			)

			if polOverloads {
				return false, []Overload{{
					Factory: factoryName,
					Process: "Polishing overload",
					Date:    currentDate,
				}}
			}

		}
	}

	// --------------------------------------------------
	// 🧪 STEP 2: Global FQC simulation
	// --------------------------------------------------

	// determine FQC simulation window
	var minDate, maxDate time.Time
	first := true

	// Find the earliest FQC start date and the latest order end date
	for _, o := range orders {
		if first || o.FQCStartDate.Before(minDate) {
			minDate = o.FQCStartDate
		}
		if first || o.OrderEndDate.After(maxDate) {
			maxDate = o.OrderEndDate
		}
		first = false
	}

	// Iterate through each day in the FQC simulation window
	for currentDate := minDate; !currentDate.After(maxDate); currentDate = currentDate.AddDate(0, 0, 1) {

		activeFQC := []*Order{}
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
		// distributeWork(activeFQC, remainingFQC, totalFQCRemaining, fqcCapacity)
		fqcOverloads := distributeEvenWithEDF(
			activeFQC,
			remainingFQCHrs,
			currentDate,
			func(o *Order) time.Time { return o.OrderEndDate },
			fqcCapacity,
		)

		if fqcOverloads {
			return false, []Overload{{
				Factory: "FQC",
				Process: "FQC overload",
				Date:    currentDate,
			}}
		}

	}

	// --------------------------------------------------
	// ✅ Final validation (Sanity check)
	// --------------------------------------------------

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

	return len(overloads) == 0, overloads
}

func parseDate(value string) (time.Time, error) {
	layout := "02/01/2006"

	t, err := time.Parse(layout, strings.TrimSpace(value))
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid date format '%s': %w", value, err)
	}

	return t, nil
}

func distributeWork(active []*Order, remaining map[string]float64, totalRemaining, capacity float64) {
	if totalRemaining == 0 || capacity == 0 {
		return
	}

	if totalRemaining <= capacity {
		for _, o := range active {
			remaining[o.OrderNo] = 0
		}
		return
	}

	for _, o := range active {
		share := (remaining[o.OrderNo] / totalRemaining) * capacity
		remaining[o.OrderNo] -= share
	}
}

func distributeEvenWithEDF(
	activeOrders []*Order,
	remainingHrs map[string]float64,
	currentDate time.Time,
	processEndDate func(*Order) time.Time,
	processCapacity float64,
) (overload bool) {

	if len(activeOrders) == 0 {
		return false
	}

	var demands []demand
	totalRequiredHrs := 0.0

	// 1️⃣ Compute required work (avg work per day) for today for all orders
	for _, o := range activeOrders {
		endDate := processEndDate(o)
		remainingDays := int(endDate.Sub(currentDate).Hours() / 24)
		if remainingDays <= 0 {
			remainingDays = 1
		}

		requiredHrs := remainingHrs[o.OrderNo] / float64(remainingDays)
		demands = append(demands, demand{o, requiredHrs, endDate})
		totalRequiredHrs += requiredHrs
	}

	// 2️⃣ Overload check
	if totalRequiredHrs > processCapacity+1e-6 {
		return true
	}

	// 3️⃣ Allocate required work
	for _, d := range demands {
		remainingHrs[d.order.OrderNo] -= d.requiredToday
		processCapacity -= d.requiredToday
	}

	// 4️⃣ Spare capacity → EDF (earliest deadline first)
	if processCapacity > 0 {
		sort.Slice(demands, func(i, j int) bool {
			return demands[i].deadline.Before(demands[j].deadline)
		})

		for _, d := range demands {
			if processCapacity <= 0 {
				break
			}

			if remainingHrs[d.order.OrderNo] <= 0 {
				continue
			}

			extra := math.Min(remainingHrs[d.order.OrderNo], processCapacity)
			remainingHrs[d.order.OrderNo] -= extra
			processCapacity -= extra
		}
	}

	return false
}

func ImproveFeasibility(
	orders []Order,
	factories map[string]Factory,
	overloads []Overload,
) bool {

	fmt.Println("⚙️ Attempting to improve feasibility...")

	// 1️⃣ Try manpower increase
	fmt.Println("➡️ Trying manpower increase...")
	IncreaseManpower(factories, overloads)

	ok, _ := CheckFeasibility(orders, factories)
	if ok {
		fmt.Println("✅ Feasible after manpower increase")
		return true
	}

	// 🔜 Future tweaks
	// AddOvertime()
	// ReallocateFactories()

	fmt.Println("❌ Still infeasible after manpower increase")
	return false
}

func IncreaseManpower(
	factories map[string]Factory,
	overloads []Overload,
) {
	for _, o := range overloads {
		f := factories[o.Factory]

		switch o.Process {
		case "Filing":
			add := math.Min(o.Excess, f.AddFilManHours)
			f.FilManHours += add
			fmt.Printf("➕ Added %.2f filing hours at %s\n", add, o.Factory)

		case "Polishing":
			add := math.Min(o.Excess, f.AddPolManHours)
			f.PolManHours += add
			fmt.Printf("➕ Added %.2f polishing hours at %s\n", add, o.Factory)

		case "FQC":
			add := math.Min(o.Excess, f.AddFQCManHours)
			f.FQCManHours += add
			fmt.Printf("➕ Added %.2f FQC hours at %s\n", add, o.Factory)
		}

		factories[o.Factory] = f
	}
}

func CheckPerOrderWindowFeasibility(orders []Order, factoryMaster map[string]Factory) []Overload {
	var overloads []Overload
	fqcFactory := factoryMaster["FQC"]

	for _, o := range orders {
		f := factoryMaster[o.Factory]

		// ---------- Filing must finish before Polishing ----------
		filingDays := int(o.PolishingStartDate.Sub(o.FilingStartDate).Hours() / 24)
		if filingDays < 0 {
			filingDays = 0
		}
		maxFilCapacity := float64(filingDays) * f.FilManHours

		if o.FilWorkingHrs > maxFilCapacity {
			overloads = append(overloads, Overload{
				Factory: o.Factory,
				Process: "Filing window infeasible",
				Date:    o.PolishingStartDate,
				Excess:  o.FilWorkingHrs - maxFilCapacity,
			})
		}

		// ---------- Polishing must finish before FQC ----------
		polishingDays := int(o.FQCStartDate.Sub(o.PolishingStartDate).Hours() / 24)
		if polishingDays < 0 {
			polishingDays = 0
		}
		maxPolCapacity := float64(polishingDays) * f.PolManHours

		if o.PolWorkingHrs > maxPolCapacity {
			overloads = append(overloads, Overload{
				Factory: o.Factory,
				Process: "Polishing window infeasible",
				Date:    o.FQCStartDate,
				Excess:  o.PolWorkingHrs - maxPolCapacity,
			})
		}

		// ---------- FQC must finish before Order End ----------
		fqcDays := int(o.OrderEndDate.Sub(o.FQCStartDate).Hours() / 24)
		if fqcDays < 0 {
			fqcDays = 0
		}
		maxFQCCapacity := float64(fqcDays) * fqcFactory.FQCManHours

		if o.FQCWorkingHrs > maxFQCCapacity {
			overloads = append(overloads, Overload{
				Factory: "FQC",
				Process: "FQC window infeasible",
				Date:    o.OrderEndDate,
				Excess:  o.FQCWorkingHrs - maxFQCCapacity,
			})
		}
	}

	return overloads
}
