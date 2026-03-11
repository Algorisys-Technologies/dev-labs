package excel

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"optimisation-problem/internal/models"
	"optimisation-problem/internal/utils"

	"github.com/xuri/excelize/v2"
)

func ReadFactoriesFromExcel(filename string) (map[string]models.Factory, error) {
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

	factories := make(map[string]models.Factory)

	for i, row := range rows {
		if i == 0 || len(row) < 3 {
			continue
		}

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

		factories[row[0]] = models.Factory{
			Name:           strings.TrimSpace(row[0]),
			FilManHours:    filerCount * 8,
			PolManHours:    polisherCount * 8,
			FQCManHours:    fqcCount * 8,
			AddFilManHours: addFilerCount * 8,
			AddPolManHours: addPolisherCount * 8,
			AddFQCManHours: addFqcCount * 8,
		}
	}

	return factories, nil
}

func ReadOrdersFromExcel(filename string) ([]models.Order, error) {
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

	var orders []models.Order

	for i, row := range rows {
		if i == 0 {
			continue
		}

		filingStart, err1 := utils.ParseDate(row[56])
		polishingStart, err2 := utils.ParseDate(row[64])
		orderEnd, err3 := utils.ParseDate(row[70])
		filHrs, err4 := strconv.ParseFloat(strings.TrimSpace(row[161]), 64)
		polHrs, err5 := strconv.ParseFloat(strings.TrimSpace(row[162]), 64)
		fqcStart, err6 := utils.ParseDate(row[65])
		fqcHrs, err7 := strconv.ParseFloat(strings.TrimSpace(row[165]), 64)

		if err1 != nil || err2 != nil || err3 != nil || err4 != nil || err5 != nil || err6 != nil || err7 != nil {
			return nil, fmt.Errorf("invalid numeric data in Orders row %d: (Col3: %q, Col4: %q, Col5: %q, Col6: %q, Col7: %q, Col8: %q)",
				i+1, row[56], row[64], row[70], row[161], row[162], row[165])
		}

		orders = append(orders, models.Order{
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
