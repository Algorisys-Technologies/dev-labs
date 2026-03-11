package excel

import (
	"fmt"
	"strconv"
	"strings"

	"optimisation-problem/internal/models"
	"optimisation-problem/internal/utils"

	"github.com/xuri/excelize/v2"
)

func ReadDummyFactories(filename string) (map[string]models.Factory2, error) {
	file, err := excelize.OpenFile(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	rows, err := file.GetRows("Sheet1")
	if err != nil {
		return nil, err
	}

	factories := make(map[string]models.Factory2)
	for i, row := range rows {
		if i == 0 || len(row) < 2 {
			continue
		}

		filerCount, _ := strconv.ParseFloat(strings.TrimSpace(row[1]), 64)
		// Assume 1 Filer provides 8 hours/day
		factories[row[0]] = models.Factory2{
			Name:             strings.TrimSpace(row[0]),
			DailyFilManHours: filerCount * 8,
			// Set others high to not interfere with dummy test
			DailyPolManHours: 9999,
			DailyFQCManHours: 9999,
		}
	}
	return factories, nil
}

func ReadDummyOrders(filename string) ([]models.Order, error) {
	file, err := excelize.OpenFile(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	rows, err := file.GetRows("Sheet1")
	if err != nil {
		return nil, err
	}

	var orders []models.Order
	for i, row := range rows[:len(rows)-2] {
		if i == 0 || len(row) < 8 {
			continue
		}

		val1 := strings.TrimSpace(row[1])
		val2 := strings.TrimSpace(row[2])
		val7 := strings.TrimSpace(row[7])

		filingStart, _ := utils.ParseDate(val1)
		orderEnd, _ := utils.ParseDate(val2)

		totalHrs, errParse := strconv.ParseFloat(val7, 64)

		if filingStart.IsZero() || orderEnd.IsZero() || errParse != nil {
			fmt.Printf("⚠️ Warning: Skipping row %d due to parse error (Filing: %q, End: %q, Hrs: %q)\n",
				i+1, val1, val2, val7)
			continue
		}

		orders = append(orders, models.Order{
			OrderNo:            strings.TrimSpace(row[0]),
			Factory:            "1",
			FilingStartDate:    filingStart,
			PolishingStartDate: orderEnd,
			FQCStartDate:       orderEnd.AddDate(0, 0, 1),
			OrderEndDate:       orderEnd.AddDate(0, 0, 2),
			FilWorkingHrs:      totalHrs,
			PolWorkingHrs:      0,
			FQCWorkingHrs:      0,
		})
	}
	return orders, nil
}
