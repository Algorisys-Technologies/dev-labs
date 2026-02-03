package optimus

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"os"

	"github.com/xuri/excelize/v2"
)

// ExportToCSV writes the optimization results to a CSV file
func (r *OptimusResult) ExportToCSV(filePath string) error {
	file, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Header
	header := []string{"Mode", "Cube", "Dimension Order", "Mean Query Time", "RAM Usage"}
	if err := writer.Write(header); err != nil {
		return err
	}

	for _, res := range r.PermutationResults {
		meanTime := 0.0
		totalTimes := 0
		for _, times := range res.QueryTimesByView {
			for _, t := range times {
				meanTime += t
				totalTimes++
			}
		}
		if totalTimes > 0 {
			meanTime = meanTime / float64(totalTimes)
		}

		row := []string{
			res.Mode.String(),
			res.CubeName,
			fmt.Sprintf("%v", res.DimensionOrder),
			fmt.Sprintf("%.4f", meanTime),
			fmt.Sprintf("%.2f GB", res.RamUsage),
		}
		if err := writer.Write(row); err != nil {
			return err
		}
	}

	return nil
}

// ExportToJSON writes the optimization results to a JSON file
func (r *OptimusResult) ExportToJSON(filePath string) error {
	data, err := json.MarshalIndent(r, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filePath, data, 0644)
}

// DetermineBestResult finds the permutation with the lowest mean execution time
func (r *OptimusResult) DetermineBestResult() *PermutationResult {
	if len(r.PermutationResults) == 0 {
		return nil
	}

	bestRes := r.PermutationResults[0]
	minTime := r.getMeanTime(bestRes)

	for _, res := range r.PermutationResults {
		meanTime := r.getMeanTime(res)
		if meanTime < minTime {
			minTime = meanTime
			bestRes = res
		}
	}
	return bestRes
}

func (r *OptimusResult) getMeanTime(res *PermutationResult) float64 {
	meanTime := 0.0
	totalTimes := 0
	for _, times := range res.QueryTimesByView {
		for _, t := range times {
			meanTime += t
			totalTimes++
		}
	}
	for _, times := range res.ProcessTimesByProcess {
		for _, t := range times {
			meanTime += t
			totalTimes++
		}
	}
	if totalTimes > 0 {
		return meanTime / float64(totalTimes)
	}
	return 0
}

// ExportToXLSX writes the optimization results to an Excel file
func (r *OptimusResult) ExportToXLSX(filePath string) error {
	f := excelize.NewFile()
	defer f.Close()

	sheet := "Results"
	f.SetSheetName("Sheet1", sheet)

	// Header
	headers := []string{"Mode", "Cube", "Dimension Order", "Mean Query Time", "RAM Usage"}
	for i, h := range headers {
		cell := fmt.Sprintf("%c1", 'A'+i)
		f.SetCellValue(sheet, cell, h)
	}

	// Data
	for idx, res := range r.PermutationResults {
		meanTime := 0.0
		totalTimes := 0
		for _, times := range res.QueryTimesByView {
			for _, t := range times {
				meanTime += t
				totalTimes++
			}
		}
		if totalTimes > 0 {
			meanTime = meanTime / float64(totalTimes)
		}

		rowIdx := idx + 2
		f.SetCellValue(sheet, fmt.Sprintf("A%d", rowIdx), res.Mode.String())
		f.SetCellValue(sheet, fmt.Sprintf("B%d", rowIdx), res.CubeName)
		f.SetCellValue(sheet, fmt.Sprintf("C%d", rowIdx), fmt.Sprintf("%v", res.DimensionOrder))
		f.SetCellValue(sheet, fmt.Sprintf("D%d", rowIdx), meanTime)
		f.SetCellValue(sheet, fmt.Sprintf("E%d", rowIdx), res.RamUsage)
	}

	return f.SaveAs(filePath)
}
