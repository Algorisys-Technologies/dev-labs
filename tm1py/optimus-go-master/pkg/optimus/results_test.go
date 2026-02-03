package optimus

import (
	"os"
	"testing"
)

func TestPermutationResult(t *testing.T) {
	res := NewPermutationResult(OriginalOrder, "TestCube", []string{"View1"}, "", []string{"Dim1", "Dim2"})
	res.QueryTimesByView["View1"] = []float64{1.2, 1.4, 1.3}

	if len(res.QueryTimesByView["View1"]) != 3 {
		t.Errorf("Expected 3 query times, got %d", len(res.QueryTimesByView["View1"]))
	}
}

func TestReporting(t *testing.T) {
	result := NewOptimusResult("Sales")
	res1 := NewPermutationResult(OriginalOrder, "Sales", []string{"View1"}, "", []string{"Dim1", "Dim2"})
	res1.QueryTimesByView["View1"] = []float64{1.0, 1.1}
	res1.RamUsage = 1.5
	result.PermutationResults = append(result.PermutationResults, res1)

	// Test CSV Export
	csvPath := "test_results.csv"
	err := result.ExportToCSV(csvPath)
	if err != nil {
		t.Errorf("CSV export failed: %v", err)
	}
	defer os.Remove(csvPath)

	// Test JSON Export
	jsonPath := "test_results.json"
	err = result.ExportToJSON(jsonPath)
	if err != nil {
		t.Errorf("JSON export failed: %v", err)
	}
	defer os.Remove(jsonPath)

	// Test XLSX Export
	xlsxPath := "test_results.xlsx"
	err = result.ExportToXLSX(xlsxPath)
	if err != nil {
		t.Errorf("XLSX export failed: %v", err)
	}
	defer os.Remove(xlsxPath)
}
