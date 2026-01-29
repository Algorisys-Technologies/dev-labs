package utils

import (
	"testing"
)

func TestCurlyBraces(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"e1", "{e1}"},
		{"{e1}", "{e1}"},
		{"", "{}"},
	}

	for _, tt := range tests {
		if got := CurlyBraces(tt.input); got != tt.expected {
			t.Errorf("CurlyBraces(%q) = %q, want %q", tt.input, got, tt.expected)
		}
	}
}

func TestConstructMdx(t *testing.T) {
	rows := []*DimensionSelection{
		NewDimensionSelection("Dim1", nil, "Subset1", ""),
	}
	cols := []*DimensionSelection{
		NewDimensionSelection("Dim2", []string{"E1", "E2"}, "", ""),
	}
	cube := "MyCube"

	got := ConstructMdx(cube, rows, cols, nil, "Both")
	expected := "SELECT NON EMPTY {Tm1SubsetToSet([Dim1], 'Subset1')} ON ROWS, NON EMPTY {[Dim2].[E1],[Dim2].[E2]} ON COLUMNS FROM [MyCube] "

	if got != expected {
		t.Errorf("ConstructMdx() = %q, want %q", got, expected)
	}
}
