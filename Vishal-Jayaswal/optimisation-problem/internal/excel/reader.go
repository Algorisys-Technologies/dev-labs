package excel

import (
	"strconv"
	"strings"

	"optimisation-problem/internal/models"
	"optimisation-problem/internal/utils"

	"github.com/xuri/excelize/v2"
)

const (
	// Conversion Constants
	MinsPerPoint = 10.0
	MinsPerShift = 8.0 * 60.0

	// Order Sheet Columns
	ColOrderNo    = 0
	ColBagNo      = 2
	ColFactory    = 24
	ColOrderType  = 4
	ColOrderStart = 26

	// Waxing
	ColWaxEnd = 39
	ColWaxPts = 17

	// Waxsetting
	ColWaxSetEnd = 40
	ColWaxSetPts = 18

	// SRD Split
	ColSRDEnd = 44
	ColSRDPts = 19

	// Filing
	ColFilEnd = 46
	ColFilPts = 15

	// Polishing
	ColPolEnd = 54
	ColPolPts = 16
)

func PointsToMins(points float64) float64 {
	return points * MinsPerPoint
}

func ReadFactoriesFromExcel(filename string) (map[string]models.Factory, error) {
	file, err := excelize.OpenFile(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	rows, err := file.GetRows("Sheet1")
	if err != nil {
		return nil, err
	}

	factories := make(map[string]models.Factory)

	for i, row := range rows {
		if i == 0 || len(row) < 4 {
			continue
		}

		name := strings.TrimSpace(row[0])
		if utils.IsNull(name) || strings.EqualFold(name, "Total") {
			continue
		}

		// Capacity is worker count from Excel. 1 worker = 8 hours = 480 mins.
		workspaceWorkers, _ := strconv.ParseFloat(strings.TrimSpace(row[1]), 64)
		filingWorkers, _ := strconv.ParseFloat(strings.TrimSpace(row[2]), 64)
		polishingWorkers, _ := strconv.ParseFloat(strings.TrimSpace(row[3]), 64)

		capMap := make(map[string]float64)
		if filingWorkers > 0 {
			capMap["filing"] = filingWorkers * MinsPerShift
		}
		if polishingWorkers > 0 {
			capMap["polishing"] = polishingWorkers * MinsPerShift
		}

		if workspaceWorkers > 0 {
			lowerName := strings.ToLower(name)
			if strings.Contains(lowerName, "waxing") {
				capMap["waxing"] = workspaceWorkers * MinsPerShift
			} else if strings.Contains(lowerName, "waxsetting") {
				capMap["waxsetting"] = workspaceWorkers * MinsPerShift
			} else if strings.Contains(lowerName, "srd_split") {
				capMap["srd_split"] = workspaceWorkers * MinsPerShift
			} else {
				capMap["Manpower"] = workspaceWorkers * MinsPerShift
			}
		}

		factories[name] = models.Factory{
			Name:            name,
			ProcessCapacity: capMap,
		}
	}

	return factories, nil
}

func ReadOrdersFromExcel(filename string) ([]models.Order, error) {
	file, err := excelize.OpenFile(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// rows, err := file.GetRows("Sheet1") // Entire year data
	// rows, err := file.GetRows("Sheet2") // Only february start date data
	rows, err := file.GetRows("Sheet3") // Only march start date data
	if err != nil {
		return nil, err
	}

	var orders []models.Order

	for i, row := range rows {
		if i == 0 {
			continue
		}

		// Ensure row has enough columns for all process indices (highest is ColPolEnd at 54)
		if len(row) <= ColPolEnd {
			continue
		}

		orderNo := strings.TrimSpace(row[ColOrderNo])
		bagNo := strings.TrimSpace(row[ColBagNo])
		factory := strings.TrimSpace(row[ColFactory])
		orderType := strings.ToLower(strings.TrimSpace(row[ColOrderType]))

		processes := make(map[string]models.ProcessInfo)

		// 1. Determine seed start date (Order Start Date)
		rawStart := row[ColOrderStart]
		currentStart, _ := utils.ParseDate(rawStart)

		// 2. Define the process sequence with their respective Excel columns
		type procCfg struct {
			name   string
			endCol int
			ptsCol int
		}
		sequence := []procCfg{
			{"waxing", ColWaxEnd, ColWaxPts},
			{"waxsetting", ColWaxSetEnd, ColWaxSetPts},
			{"srd_split", ColSRDEnd, ColSRDPts},
			{"filing", ColFilEnd, ColFilPts},
			{"polishing", ColPolEnd, ColPolPts},
		}

		for _, cfg := range sequence {
			// Skip if end date is missing or explicitly marked "NULL"
			val := row[cfg.endCol]
			if len(row) <= cfg.endCol || utils.IsNull(val) {
				continue
			}

			endDate, err := utils.ParseDate(val)
			if err != nil {
				continue
			}

			var pts float64
			if len(row) > cfg.ptsCol {
				raw := strings.TrimSpace(row[cfg.ptsCol])
				pts, _ = strconv.ParseFloat(raw, 64)
			}

			processes[cfg.name] = models.ProcessInfo{
				Name:        cfg.name,
				StartDate:   currentStart,
				EndDate:     endDate,
				WorkingMins: PointsToMins(pts),
			}

			// Next process can start on the same day the current one ends (overlap allowed)
			currentStart = endDate
		}

		orders = append(orders, models.Order{
			OrderNo:   orderNo,
			BagNo:     bagNo,
			Factory:   factory,
			OrderType: orderType,
			Processes: processes,
		})
	}

	return orders, nil
}
