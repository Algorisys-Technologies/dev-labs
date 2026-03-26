package process_map

import (
	"os"
	"strings"
	"testing"
)

func TestParse_skipsHeaderTrimsAndMapsColumn0ToColumn1(t *testing.T) {
	input := "" +
		"Process,PPC Module Description\n" +
		" ZCAD , ZCAD \n" +
		" RWAX , Waxing \n" +
		"RSET, HandSetting \n" +
		"RSET,MicroSetting\n"

	m, err := Parse(strings.NewReader(input), 0, 1)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}

	wantZCAD := []string{"ZCAD"}
	if got := m["ZCAD"]; !equalStringSlices(got, wantZCAD) {
		t.Fatalf("ZCAD mapping: got %v, want %v", got, wantZCAD)
	}

	wantRWAX := []string{"Waxing"}
	if got := m["RWAX"]; !equalStringSlices(got, wantRWAX) {
		t.Fatalf("RWAX mapping: got %v, want %v", got, wantRWAX)
	}

	wantRSET := []string{"HandSetting", "MicroSetting"}
	if got := m["RSET"]; !equalStringSlices(got, wantRSET) {
		t.Fatalf("RSET mapping: got %v, want %v", got, wantRSET)
	}
}

func TestParse_duplicateKeyAppendsValuesInEncounterOrder(t *testing.T) {
	input := "" +
		"Process,PPC Module Description\n" +
		"RSET,HandSetting\n" +
		"RSET,MicroSetting\n"

	m, err := Parse(strings.NewReader(input), 0, 1)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}

	want := []string{"HandSetting", "MicroSetting"}
	if got := m["RSET"]; !equalStringSlices(got, want) {
		t.Fatalf("RSET mapping: got %v, want %v", got, want)
	}
}

func TestParse_returnsErrorOnBlankKeyOrBlankValue(t *testing.T) {
	t.Run("blank_key", func(t *testing.T) {
		input := "" +
			"Process,PPC Module Description\n" +
			",HandSetting\n"

		_, err := Parse(strings.NewReader(input), 0, 1)
		if err == nil {
			t.Fatal("expected error for blank key, got nil")
		}
	})

	t.Run("blank_value", func(t *testing.T) {
		input := "" +
			"Process,PPC Module Description\n" +
			"RSET,\n"

		_, err := Parse(strings.NewReader(input), 0, 1)
		if err == nil {
			t.Fatal("expected error for blank value, got nil")
		}
	})
}

func equalStringSlices(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func TestParse_customKeyValueColumnIndices(t *testing.T) {
	input := "" +
		"A,B,Process,PPC\n" +
		"x,x, ZCAD , ZCAD \n" +
		"x,x, RWAX , Waxing \n"

	m, err := Parse(strings.NewReader(input), 2, 3)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if got := m["ZCAD"]; !equalStringSlices(got, []string{"ZCAD"}) {
		t.Fatalf("ZCAD mapping: got %v", got)
	}
	if got := m["RWAX"]; !equalStringSlices(got, []string{"Waxing"}) {
		t.Fatalf("RWAX mapping: got %v", got)
	}
}

func TestParse_rejectsEqualKeyValueIndices(t *testing.T) {
	_, err := Parse(strings.NewReader("H\na,b\n"), 1, 1)
	if err == nil {
		t.Fatal("expected error when key and value indices are equal")
	}
}

func TestParse_realProcessMap_usesFirstTwoColumnsAndSupportsDuplicateKeys(t *testing.T) {
	// Repo format: data/preoptimization_process_map.csv
	// Header: Process,PPC Module Description
	// Test runs with working directory as the package directory, so use a
	// repo-relative path to the fixture CSV.
	f, err := os.Open("../../data/preoptimization_process_map.csv")
	if err != nil {
		t.Fatalf("open data/preoptimization_process_map.csv: %v", err)
	}
	defer f.Close()

	m, err := Parse(f, 0, 1)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}

	// Ensure keys are consolidated in the map, but values can have multiple entries.
	if got := m["RWAX"]; !equalStringSlices(got, []string{"Waxing"}) {
		t.Fatalf("RWAX mapping: got %v, want %v", got, []string{"Waxing"})
	}
	if got := m["RSETA"]; !equalStringSlices(got, []string{"FanukSetting"}) {
		t.Fatalf("RSETA mapping: got %v, want %v", got, []string{"FanukSetting"})
	}
	if got := m["RSET"]; !equalStringSlices(got, []string{"HandSetting", "MicroSetting"}) {
		t.Fatalf("RSET mapping: got %v, want %v", got, []string{"HandSetting", "MicroSetting"})
	}
}
