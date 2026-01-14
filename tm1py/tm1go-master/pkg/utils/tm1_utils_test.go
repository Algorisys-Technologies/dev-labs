package utils

import (
	"testing"
)

func TestLowerAndDropSpaces(t *testing.T) {
	if got := LowerAndDropSpaces(" Travel Expenses "); got != "travelexpenses" {
		t.Errorf("LowerAndDropSpaces() = %q, want %q", got, "travelexpenses")
	}
}

func TestVerifyVersion(t *testing.T) {
	if !VerifyVersion("11.0", "11.8.0") {
		t.Error("VerifyVersion(11.0, 11.8.0) should be true")
	}
	if VerifyVersion("12.0", "11.8.0") {
		t.Error("VerifyVersion(12.0, 11.8.0) should be false")
	}
}

func TestBuildContentFromCellset(t *testing.T) {
	// Simple mockup of a cellset JSON response
	rawCellset := map[string]interface{}{
		"Cube": map[string]interface{}{
			"Dimensions": []interface{}{
				map[string]interface{}{"Name": "Dim1"},
				map[string]interface{}{"Name": "Dim2"},
			},
		},
		"Axes": []interface{}{
			map[string]interface{}{
				"Cardinality": 2.0,
				"Tuples": []interface{}{
					map[string]interface{}{
						"Members": []interface{}{
							map[string]interface{}{"UniqueName": "[Dim2].[E1]", "Name": "E1"},
						},
					},
					map[string]interface{}{
						"Members": []interface{}{
							map[string]interface{}{"UniqueName": "[Dim2].[E2]", "Name": "E2"},
						},
					},
				},
			},
			map[string]interface{}{
				"Cardinality": 1.0,
				"Tuples": []interface{}{
					map[string]interface{}{
						"Members": []interface{}{
							map[string]interface{}{"UniqueName": "[Dim1].[E3]", "Name": "E3"},
						},
					},
				},
			},
		},
		"Cells": []interface{}{
			map[string]interface{}{"Ordinal": 0.0, "Value": 100.0},
			map[string]interface{}{"Ordinal": 1.0, "Value": 200.0},
		},
	}

	content := BuildContentFromCellset(rawCellset, 0, true, true)

	if len(content) != 2 {
		t.Errorf("Expected 2 cells, got %d", len(content))
	}

	if val, ok := content["[Dim1].[E3]|[Dim2].[E1]"]; !ok || val != 100.0 {
		t.Errorf("Cell [Dim1].[E3]|[Dim2].[E1] = %v, want 100.0", val)
	}
}
