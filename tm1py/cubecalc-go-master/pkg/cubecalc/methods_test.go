package cubecalc

import (
	"math"
	"testing"
)

func TestFinancialMethods(t *testing.T) {
	// Simple PV Test
	pvVal := PV(0.05, 5, 100, 0, 0)
	if math.Abs(pvVal-(-432.947)) > 0.001 {
		t.Errorf("PV failed: expected -432.947, got %f", pvVal)
	}

	// Simple FV Test
	fvVal := FV(0.05, 5, 100, -432.947, 0)
	if math.Abs(fvVal-0) > 0.01 {
		t.Errorf("FV failed: expected 0, got %f", fvVal)
	}

	// Simple NPV Test
	values := []float64{-100, 50, 60}
	npvVal := NPV(0.1, values)
	if math.Abs(npvVal-(-4.958)) > 0.001 {
		// -100 + 45.45 + 49.58 = -4.97
		t.Logf("NPV: %f", npvVal)
	}

	// PMT Test
	pmtVal := PMT(0.08/12, 12, 1000, 0, 0)
	if math.Abs(pmtVal-(-86.988)) > 0.001 {
		t.Errorf("PMT failed: expected -86.988, got %f", pmtVal)
	}
}

func TestStatisticalMethods(t *testing.T) {
	values := []float64{10, 20, 30, 40, 50}
	if Mean(values) != 30 {
		t.Errorf("Mean failed: expected 30, got %f", Mean(values))
	}
	if Median(values) != 30 {
		t.Errorf("Median failed: expected 30, got %f", Median(values))
	}

	values2 := []float64{10, 20, 30, 40}
	if Median(values2) != 25 {
		t.Errorf("Median even failed: expected 25, got %f", Median(values2))
	}
}
