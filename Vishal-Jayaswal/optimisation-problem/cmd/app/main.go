package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
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

func main() {
	factories, err := readFactoriesFromExcel("factory-capacity.xlsx")
	if err != nil {
		log.Fatal(err)
	}

	orders, err := readOrdersFromExcel("test-ppc-base-data.xlsx")
	if err != nil {
		log.Fatal(err)
	}

	ok := CheckFeasibility(orders, factories)

	if ok {
		fmt.Println("\nAll orders are FEASIBLE ✅")
	} else {
		fmt.Println("\nOrders are NOT feasible ❌")
	}
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

		if err1 != nil || err2 != nil || err3 != nil {
			return nil, fmt.Errorf("invalid numeric data in Factories row %d: (Col1: %q, Col2: %q, Col3: %q)", i+1, row[1], row[2], row[3])
		}

		factories[row[0]] = Factory{
			Name:        strings.TrimSpace(row[0]),
			FilManHours: filerCount * 8, // convert staff to hours/day
			PolManHours: polisherCount * 8,
			FQCManHours: fqcCount * 8,
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
		fqcStart, err6 := parseDate(row[65])                                // ← adjust index
		fqcHrs, err7 := strconv.ParseFloat(strings.TrimSpace(row[163]), 64) // adjust index

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
func CheckFeasibility(orders []Order, factories map[string]Factory) bool {

	// Separate FQC factory
	fqcFactory, ok := factories["FQC"]
	if !ok {
		fmt.Println("❌ FQC factory not found")
		return false
	}

	// Group orders by production factory
	factoryOrders := make(map[string][]*Order)
	for i := range orders {
		o := &orders[i]
		factoryOrders[o.Factory] = append(factoryOrders[o.Factory], o)
	}

	// Track remaining work for each order
	remainingFil := make(map[string]float64)
	remainingPol := make(map[string]float64)
	remainingFQC := make(map[string]float64)

	// Track polishing completion date (for FQC eligibility)
	polishingDoneDate := make(map[string]time.Time)

	// Initialize total remaining work (filing, polishing, fqc) for each order
	for _, o := range orders {
		remainingFil[o.OrderNo] = o.FilWorkingHrs
		remainingPol[o.OrderNo] = o.PolWorkingHrs
		remainingFQC[o.OrderNo] = o.FQCWorkingHrs
	}

	// --------------------------------------------------
	// 🏭 STEP 1: Filing & Polishing per factory
	// --------------------------------------------------

	for factoryName, f := range factories {

		if factoryName == "FQC" {
			continue // skip FQC factory here
		}

		fOrders := factoryOrders[factoryName]
		if len(fOrders) == 0 {
			continue
		}

		// determine simulation window
		minDate := fOrders[0].FilingStartDate
		maxDate := fOrders[0].OrderEndDate

		for _, o := range fOrders {
			if o.FilingStartDate.Before(minDate) {
				minDate = o.FilingStartDate
			}
			if o.OrderEndDate.After(maxDate) {
				maxDate = o.OrderEndDate
			}
		}

		// Iterate through each day in the simulation window
		for current := minDate; !current.After(maxDate); current = current.AddDate(0, 0, 1) {

			// ---------- Filing ----------
			activeFil := []*Order{}
			totalFilRemaining := 0.0

			for _, o := range fOrders {
				if current.Before(o.FilingStartDate) ||
					!current.Before(o.PolishingStartDate) ||
					remainingFil[o.OrderNo] <= 0 {
					continue
				}
				activeFil = append(activeFil, o)
				totalFilRemaining += remainingFil[o.OrderNo]
			}

			distributeWork(activeFil, remainingFil, totalFilRemaining, f.FilManHours)

			// ---------- Polishing ----------
			activePol := []*Order{}
			totalPolRemaining := 0.0

			for _, o := range fOrders {
				if current.Before(o.PolishingStartDate) ||
					current.After(o.OrderEndDate) ||
					remainingPol[o.OrderNo] <= 0 {
					continue
				}
				activePol = append(activePol, o)
				totalPolRemaining += remainingPol[o.OrderNo]
			}

			// Track remaining polishing work before distribution
			before := make(map[string]float64)
			for _, o := range activePol {
				before[o.OrderNo] = remainingPol[o.OrderNo]
			}

			distributeWork(activePol, remainingPol, totalPolRemaining, f.PolManHours)

			// detect polishing completion
			for _, o := range activePol {
				if before[o.OrderNo] > 0 && remainingPol[o.OrderNo] <= 0 {
					polishingDoneDate[o.OrderNo] = current
				}
			}
		}
	}

	// --------------------------------------------------
	// 🧪 STEP 2: Global FQC simulation
	// --------------------------------------------------

	// determine FQC simulation window
	var minDate, maxDate time.Time
	first := true

	// Find the earliest polishing completion date and the latest order end date
	for _, o := range orders {
		if first || polishingDoneDate[o.OrderNo].Before(minDate) {
			minDate = polishingDoneDate[o.OrderNo]
		}
		if first || o.OrderEndDate.After(maxDate) {
			maxDate = o.OrderEndDate
		}
		first = false // Set first to false after the first iteration
	}

	// Iterate through each day in the FQC simulation window
	for current := minDate; !current.After(maxDate); current = current.AddDate(0, 0, 1) {

		activeFQC := []*Order{}
		totalFQCRemaining := 0.0

		for i := range orders {
			o := &orders[i]

			// Skip if FQC has not started yet
			if current.Before(o.FQCStartDate) {
				continue
			}

			// must finish polishing first
			if polishingDoneDate[o.OrderNo].After(current) {
				continue
			}

			if current.After(o.OrderEndDate) {
				continue
			}

			if remainingFQC[o.OrderNo] <= 0 {
				continue
			}

			activeFQC = append(activeFQC, o)
			totalFQCRemaining += remainingFQC[o.OrderNo]
		}

		distributeWork(activeFQC, remainingFQC, totalFQCRemaining, fqcFactory.FQCManHours)
	}

	// --------------------------------------------------
	// ✅ Final validation
	// --------------------------------------------------

	for _, o := range orders {

		if remainingFil[o.OrderNo] > 0.01 {
			fmt.Printf("Order %s incomplete: Filing short\n", o.OrderNo)
			return false
		}

		if remainingPol[o.OrderNo] > 0.01 {
			fmt.Printf("Order %s incomplete: Polishing short\n", o.OrderNo)
			return false
		}

		if remainingFQC[o.OrderNo] > 0.01 {
			fmt.Printf("Order %s incomplete: FQC short\n", o.OrderNo)
			return false
		}
	}

	return true
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
