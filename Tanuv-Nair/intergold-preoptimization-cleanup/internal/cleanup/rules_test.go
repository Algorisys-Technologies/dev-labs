package cleanup

import (
	"testing"
	"time"

	"os"
	"strings"

	"intergold-preoptimization-cleanup/internal/process_map"
)

func TestExcelColumnLabelToIndex_numericAndLetters(t *testing.T) {
	t.Parallel()

	cases := []struct {
		label string
		want  int
	}{
		{label: "A", want: 0},
		{label: "B", want: 1},
		{label: "Z", want: 25},
		{label: "AA", want: 26},
		{label: "AB", want: 27},
	}

	for _, tc := range cases {
		t.Run(tc.label, func(t *testing.T) {
			t.Parallel()

			got, err := excelColumnLabelToIndex(tc.label)
			if err != nil {
				t.Fatalf("excelColumnLabelToIndex(%q): %v", tc.label, err)
			}
			if got != tc.want {
				t.Fatalf("excelColumnLabelToIndex(%q): got %d, want %d", tc.label, got, tc.want)
			}
		})
	}
}

func TestExcelColumnLabelToIndex_rejectsInvalidLabels(t *testing.T) {
	t.Parallel()

	invalid := []string{
		"",
		"1",
		"A1",
		"a",
		"@",
	}

	for _, label := range invalid {
		t.Run(label, func(t *testing.T) {
			t.Parallel()

			_, err := excelColumnLabelToIndex(label)
			if err == nil {
				t.Fatalf("excelColumnLabelToIndex(%q): expected error, got nil", label)
			}
		})
	}
}

func TestColIndexFromEnv_acceptsNumericAndExcelLetters(t *testing.T) {
	t.Parallel()

	cases := []struct {
		in   string
		want int
	}{
		{in: "0", want: 0},
		{in: "22", want: 22},
		{in: "Z", want: 25},
		{in: "AA", want: 26},
		{in: "AB", want: 27},
	}

	for _, tc := range cases {
		t.Run(tc.in, func(t *testing.T) {
			t.Parallel()

			got, err := colIndexFromEnvValue(tc.in)
			if err != nil {
				t.Fatalf("colIndexFromEnvValue(%q): %v", tc.in, err)
			}
			if got != tc.want {
				t.Fatalf("colIndexFromEnvValue(%q): got %d, want %d", tc.in, got, tc.want)
			}
		})
	}
}

func TestColIndexFromEnv_rejectsInvalidValues(t *testing.T) {
	t.Parallel()

	invalid := []string{
		" ",
		"1A",
		"0x10",
		"AAA1",
		"AA ",
	}

	for _, in := range invalid {
		t.Run(in, func(t *testing.T) {
			t.Parallel()

			_, err := colIndexFromEnvValue(in)
			if err == nil {
				t.Fatalf("colIndexFromEnvValue(%q): expected error, got nil", in)
			}
		})
	}
}

func TestParseProcessDate_ddmmyyyyAndYearWindowAndSentinel(t *testing.T) {
	t.Parallel()

	const currentYear = 2026
	const windowX = 5

	t.Run("validWithinYearWindow", func(t *testing.T) {
		t.Parallel()

		got, ok, err := parseProcessDateDDMMYYYYOrNull("25-02-2026", currentYear, windowX)
		if err != nil {
			t.Fatalf("parseProcessDateDDMMYYYYOrNull: %v", err)
		}
		if !ok {
			t.Fatalf("expected ok=true, got ok=false")
		}
		if got.Year() != 2026 {
			t.Fatalf("year: got %d, want 2026", got.Year())
		}
	})

	t.Run("invalidOutsideYearWindow", func(t *testing.T) {
		t.Parallel()

		_, ok, err := parseProcessDateDDMMYYYYOrNull("01-01-2020", currentYear, windowX)
		if err != nil {
			t.Fatalf("parseProcessDateDDMMYYYYOrNull: %v", err)
		}
		if ok {
			t.Fatalf("expected ok=false for out-of-range year")
		}
	})

	t.Run("invalidSentinelDate", func(t *testing.T) {
		t.Parallel()

		_, ok, err := parseProcessDateDDMMYYYYOrNull("01-01-1900", currentYear, windowX)
		if err != nil {
			t.Fatalf("parseProcessDateDDMMYYYYOrNull: %v", err)
		}
		if ok {
			t.Fatalf("expected ok=false for sentinel date")
		}
	})

	t.Run("invalidFormatReturnsError", func(t *testing.T) {
		t.Parallel()

		_, _, err := parseProcessDateDDMMYYYYOrNull("2026-02-25", currentYear, windowX)
		if err == nil {
			t.Fatalf("expected error for invalid date format, got nil")
		}
	})
}

func TestRulesConfigFromEnv_usesDotEnvExampleFallbacksWhenUnset(t *testing.T) {
	// Ensure none of the keys are set so fallbacks apply.
	keys := []string{
		"PROD_END_DT_COL_INDEX",
		"BLOC_COL_INDEX",
		"FIRST_BLOC_PROCESS_COL_INDEX",
		"LAST_BLOC_PROCESS_COL_INDEX",
		"NULL_DATE_YEAR_WINDOW_X",
		"REMARKS_EXTENSION_NEEDED",
	}
	for _, k := range keys {
		_ = os.Unsetenv(k)
	}

	cfg, err := rulesConfigFromEnv()
	if err != nil {
		t.Fatalf("rulesConfigFromEnv(): %v", err)
	}

	// Values from .env.example:
	// PROD_END_DT_COL_INDEX="W" -> 22
	// BLOC_COL_INDEX="BD" -> 55
	// FIRST_BLOC_PROCESS_COL_INDEX="AB" -> 27
	// LAST_BLOC_PROCESS_COL_INDEX="AY" -> 50
	if cfg.ProdEndDtColIndex != 22 {
		t.Fatalf("ProdEndDtColIndex: got %d, want %d", cfg.ProdEndDtColIndex, 22)
	}
	if cfg.BLOCColIndex != 55 {
		t.Fatalf("BLOCColIndex: got %d, want %d", cfg.BLOCColIndex, 55)
	}
	if cfg.FirstBlocProcessColIndex != 27 {
		t.Fatalf("FirstBlocProcessColIndex: got %d, want %d", cfg.FirstBlocProcessColIndex, 27)
	}
	if cfg.LastBlocProcessColIndex != 50 {
		t.Fatalf("LastBlocProcessColIndex: got %d, want %d", cfg.LastBlocProcessColIndex, 50)
	}
	if cfg.NullDateYearWindowX != 5 {
		t.Fatalf("NullDateYearWindowX: got %d, want %d", cfg.NullDateYearWindowX, 5)
	}
	if cfg.RemarksExtensionNeeded != "extension needed" {
		t.Fatalf("RemarksExtensionNeeded: got %q, want %q", cfg.RemarksExtensionNeeded, "extension needed")
	}
}

func TestAdjustBusinessDays_skipsWeekend(t *testing.T) {
	t.Parallel()

	// 2026-03-20 is Friday; 2026-03-21 is Saturday (business); 2026-03-22 is Sunday.
	// So the next business day after Friday is Saturday 2026-03-21.
	start := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC)

	isHoliday := func(d time.Time) bool {
		return false
	}

	got := adjustBusinessDays(start, 1, isHoliday)
	want := time.Date(2026, 3, 21, 0, 0, 0, 0, time.UTC) // Saturday

	if !got.Equal(want) {
		t.Fatalf("adjustBusinessDays: got %s, want %s", got.Format("2006-01-02"), want.Format("2006-01-02"))
	}
}

func TestAdjustBusinessDays_skipsHoliday(t *testing.T) {
	t.Parallel()

	start := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC)   // Friday
	holiday := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC) // Monday business day

	isHoliday := func(d time.Time) bool {
		return d.Equal(holiday)
	}

	got := adjustBusinessDays(start, 1, isHoliday)
	want := time.Date(2026, 3, 21, 0, 0, 0, 0, time.UTC) // Saturday (Monday is holiday but not reached)

	if !got.Equal(want) {
		t.Fatalf("adjustBusinessDays: got %s, want %s", got.Format("2006-01-02"), want.Format("2006-01-02"))
	}
}

func TestAdjustBusinessDays_zeroKeepsBusinessDayOrSkipsToNext(t *testing.T) {
	t.Parallel()

	isHoliday := func(d time.Time) bool { return false }

	t.Run("fridayUnchanged", func(t *testing.T) {
		t.Parallel()
		start := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday
		got := adjustBusinessDays(start, 0, isHoliday)
		if !got.Equal(start) {
			t.Fatalf("adjustBusinessDays: got %s, want %s", got.Format("2006-01-02"), start.Format("2006-01-02"))
		}
	})

	t.Run("sundayToMonday", func(t *testing.T) {
		t.Parallel()
		start := time.Date(2026, 3, 22, 0, 0, 0, 0, time.UTC) // Sunday
		want := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)  // Monday
		got := adjustBusinessDays(start, 0, isHoliday)
		if !got.Equal(want) {
			t.Fatalf("adjustBusinessDays: got %s, want %s", got.Format("2006-01-02"), want.Format("2006-01-02"))
		}
	})

	t.Run("holidayRollsForward", func(t *testing.T) {
		t.Parallel()
		holiday := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC) // Monday
		got := adjustBusinessDays(holiday, 0, func(d time.Time) bool {
			return d.Equal(holiday)
		})
		want := time.Date(2026, 3, 24, 0, 0, 0, 0, time.UTC) // Tuesday
		if !got.Equal(want) {
			t.Fatalf("adjustBusinessDays: got %s, want %s", got.Format("2006-01-02"), want.Format("2006-01-02"))
		}
	})
}

func TestApplyRulesToRow_prodEndBeforeCurrentDate_RPOL_updatesMappedColumnAndRemarks(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	// Indices:
	// ProdEndDt=0, ZCAD=1, ZCAM=2, Polish=3, Bloc=4
	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"RPOL": {"Polish"},
		"ZCAD": {"ZCAD"},
	}

	row := []string{
		"10-03-2026", // ProdEndDt < now
		"01-03-2026", // ZCAD
		"01-03-2026", // ZCAM
		"01-03-2026", // Polish (will be updated)
		"RPOL",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	// Current business day for Fri 20-Mar-2026 is the same day.
	if got := updatedRow[3]; got != "20-03-2026" {
		t.Fatalf("Polish updated date: got %q, want %q", got, "20-03-2026")
	}
	if got := updatedRow[1]; got != "01-03-2026" {
		t.Fatalf("ZCAD should be unchanged: got %q, want %q", got, "01-03-2026")
	}
	if got := updatedRow[2]; got != "01-03-2026" {
		t.Fatalf("ZCAM should be unchanged: got %q, want %q", got, "01-03-2026")
	}
	if got, want := remarks, "Updated: Polish; changes made"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
	if strings.Contains(remarks, "Unchanged:") {
		t.Fatalf("remarks must not include unchanged fields, got %q", remarks)
	}
}

func TestApplyRulesToRow_prodEndBeforeCurrentDate_nonRPOL_extensionNeededNoDateChanges(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"RPOL": {"Polish"},
		"ZCAD": {"ZCAD"},
	}

	row := []string{
		"10-03-2026", // ProdEndDt < now
		"01-03-2026",
		"02-03-2026",
		"03-03-2026",
		"ZCAD", // non-RPOL -> extension needed
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	// No dates should change in this branch.
	for i := cfg.FirstBlocProcessColIndex; i <= cfg.LastBlocProcessColIndex; i++ {
		if got := updatedRow[i]; got != row[i] {
			t.Fatalf("date column %d changed: got %q, want %q", i, got, row[i])
		}
	}
	if got, want := remarks, "No changes made; extension needed, 4 day buffer used"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
	if strings.Contains(remarks, "Unchanged:") {
		t.Fatalf("remarks must not include unchanged fields, got %q", remarks)
	}
}

func TestApplyRulesToRow_prodEndBeforeCurrentDate_nonRPOL_usesFourDayBufferWhenChainFits(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"PrePolish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	row := []string{
		"19-03-2026", // ProdEndDt < now (20-03-2026) => extension-needed scenario
		"01-03-2026", // ZCAD
		"02-03-2026", // ZCAM
		"03-03-2026", // PrePolish
		"ZCAD",       // Bloc (non-RPOL)
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got, want := updatedRow[0], "23-03-2026"; got != want {
		t.Fatalf("ProdEndDt after 4-day buffer: got %q, want %q", got, want)
	}

	if got, want := updatedRow[1], "20-03-2026"; got != want {
		t.Fatalf("ZCAD updated date: got %q, want %q", got, want)
	}
	if got, want := updatedRow[2], "21-03-2026"; got != want {
		t.Fatalf("ZCAM updated date: got %q, want %q", got, want)
	}
	if got, want := updatedRow[3], "23-03-2026"; got != want {
		t.Fatalf("PrePolish updated date: got %q, want %q", got, want)
	}

	if got, want := remarks, "Updated: ZCAD,ZCAM,PrePolish; 4 day buffer used"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
}

func TestApplyRulesToRow_mainScheduling_breakStopsOnFirstNonUpdate(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// ProdEndDt >= now triggers main scheduling.
	// First iteration updates ZCAD to currentDate (Fri 20-Mar-2026).
	// Second column ZCAM is already >= CurrentDate (23-03-2026), so scanning stops.
	row := []string{
		"30-03-2026", // ProdEndDt
		"01-03-2026", // ZCAD
		"23-03-2026", // ZCAM (break happens here)
		"05-03-2026", // Polish (unchanged)
		"ZCAD",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got := updatedRow[1]; got != "20-03-2026" {
		t.Fatalf("ZCAD updated date: got %q, want %q", got, "20-03-2026")
	}
	if got := updatedRow[2]; got != "23-03-2026" {
		t.Fatalf("ZCAM should be unchanged (break): got %q, want %q", got, "23-03-2026")
	}
	if got := updatedRow[3]; got != "05-03-2026" {
		t.Fatalf("Polish should be unchanged after break: got %q, want %q", got, "05-03-2026")
	}
	if !strings.Contains(remarks, "changes") {
		t.Fatalf("remarks should mention changes made, got %q", remarks)
	}
	if strings.Contains(remarks, "Unchanged:") {
		t.Fatalf("remarks must not include unchanged fields, got %q", remarks)
	}
}

func TestApplyRulesToRow_mainScheduling_keepSameDateForEqualExistingDates(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// All three process columns have the same existing date (01-03-2026),
	// so they should all be updated to the same new date (currentDate).
	row := []string{
		"30-03-2026", // ProdEndDt
		"01-03-2026", // ZCAD
		"01-03-2026", // ZCAM
		"01-03-2026", // Polish
		"ZCAD",       // Bloc
	}

	updatedRow, _, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	// If the original process completion dates were the same for consecutive
	// columns, then the updated values should stay the same as well.
	want := "20-03-2026"
	for i := cfg.FirstBlocProcessColIndex; i <= cfg.LastBlocProcessColIndex; i++ {
		if got := updatedRow[i]; got != want {
			t.Fatalf("date column %d: got %q, want %q", i, got, want)
		}
	}
}

func TestApplyRulesToRow_mainScheduling_stopOnProcessDateAtOrAfterNow(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// ProdEndDt >= now triggers main scheduling.
	// ZCAD is < now, so it should be updated to currentDate (Fri 20-Mar-2026).
	// ZCAM is >= now (Sun 22-Mar-2026), so we must stop and leave it unchanged.
	row := []string{
		"30-03-2026", // ProdEndDt
		"01-03-2026", // ZCAD (< now)
		"22-03-2026", // ZCAM (>= now) => stop here
		"05-03-2026", // Polish (< now but must remain unchanged due to stop)
		"ZCAD",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got := updatedRow[1]; got != "20-03-2026" {
		t.Fatalf("ZCAD updated date: got %q, want %q", got, "20-03-2026")
	}
	if got := updatedRow[2]; got != "22-03-2026" {
		t.Fatalf("ZCAM should be unchanged (stop): got %q, want %q", got, "22-03-2026")
	}
	if got := updatedRow[3]; got != "05-03-2026" {
		t.Fatalf("Polish should be unchanged after stop: got %q, want %q", got, "05-03-2026")
	}
	if got, want := remarks, "Updated: ZCAD; changes made"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
}

func TestApplyRulesToRow_mainScheduling_gteNowButBeforePrevUpdatedDate_bumpsAndContinues(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Mid",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             5,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  4,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// ZCAD and ZCAM/Mid drive prevUpdatedDate to 21-03-2026. Polish is 20-03-2026
	// (at/after run date) but still before 21-03, so Case-2 else bumps it to
	// calendar(prevUpdatedDate+1) snapped to a business day (23-03-2026 Mon).
	row := []string{
		"30-03-2026", // ProdEndDt
		"01-03-2026", // ZCAD
		"19-03-2026", // ZCAM
		"19-03-2026", // Mid (same original date as ZCAM)
		"20-03-2026", // Polish (same calendar day as now; out of order vs chain)
		"ZCAD",       // Bloc
	}

	wantPolish := formatDDMMYYYY(adjustBusinessDays(dateOnlyUTC(time.Date(2026, 3, 22, 0, 0, 0, 0, time.UTC)), 0, nil))

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got := updatedRow[1]; got != "20-03-2026" {
		t.Fatalf("ZCAD updated date: got %q, want %q", got, "20-03-2026")
	}
	if got := updatedRow[2]; got != "21-03-2026" {
		t.Fatalf("ZCAM updated date: got %q, want %q", got, "21-03-2026")
	}
	if got := updatedRow[3]; got != "21-03-2026" {
		t.Fatalf("Mid updated date: got %q, want %q", got, "21-03-2026")
	}
	if got := updatedRow[4]; got != wantPolish {
		t.Fatalf("Polish bumped date: got %q, want %q", got, wantPolish)
	}
	if !strings.Contains(remarks, "Polish") || !strings.Contains(remarks, "changes made") {
		t.Fatalf("remarks: got %q", remarks)
	}
}

func TestApplyRulesToRow_mainScheduling_finalSuccessRemarksUpdatedUsesChangesMade(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// ProdEndDt is set such that the updated last process date does not
	// trigger the undo+extension-needed path.
	row := []string{
		"30-03-2026", // ProdEndDt
		"01-03-2026", // ZCAD
		"01-03-2026", // ZCAM
		"01-03-2026", // Polish
		"ZCAD",       // Bloc
	}

	_, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got, want := remarks, "Updated: ZCAD,ZCAM,Polish; changes made"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
}

func TestApplyRulesToRow_mainScheduling_finalUndoWhenLastUpdatedExceedsProdEndDt(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// ProdEndDt is set such that even after a 4-day buffer is applied, the
	// updated last process date (20-03-2026) still exceeds ProdEndDt, triggering
	// undo+extension-needed.
	row := []string{
		"15-03-2026", // ProdEndDt (before updated current business day; +4 => 19-03-2026 but undo keeps original)
		"01-03-2026", // ZCAD
		"01-03-2026", // ZCAM
		"01-03-2026", // Polish (last)
		"ZCAD",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got, want := updatedRow[0], "19-03-2026"; got != want {
		t.Fatalf("ProdEndDt should keep extended value after buffer+undo: got %q, want %q", got, want)
	}

	// Undo: all updated process columns should be restored to originals.
	for i := cfg.FirstBlocProcessColIndex; i <= cfg.LastBlocProcessColIndex; i++ {
		if got := updatedRow[i]; got != row[i] {
			t.Fatalf("date column %d after undo: got %q, want %q", i, got, row[i])
		}
	}
	if strings.Contains(remarks, "Updated") {
		t.Fatalf("remarks must not indicate updates when changes were undone, got %q", remarks)
	}
	if got, want := remarks, "No changes made; extension needed, 4 day buffer used"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
	if strings.Contains(remarks, "Unchanged:") {
		t.Fatalf("remarks must not include unchanged fields, got %q", remarks)
	}
}

func TestApplyRulesToRow_extensionNeeded_usesFourDayBufferWhenChainFits(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"PrePolish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	row := []string{
		"21-03-2026", // ProdEndDt (>= now but < final updated PrePolish)
		"01-03-2026", // ZCAD
		"02-03-2026", // ZCAM
		"03-03-2026", // PrePolish
		"ZCAD",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got, want := updatedRow[0], "25-03-2026"; got != want {
		t.Fatalf("ProdEndDt after 4-day buffer: got %q, want %q", got, want)
	}

	if got, want := updatedRow[1], "20-03-2026"; got != want {
		t.Fatalf("ZCAD updated date: got %q, want %q", got, want)
	}
	if got, want := updatedRow[2], "21-03-2026"; got != want {
		t.Fatalf("ZCAM updated date: got %q, want %q", got, want)
	}
	if got, want := updatedRow[3], "23-03-2026"; got != want {
		t.Fatalf("PrePolish updated date: got %q, want %q", got, want)
	}

	if got, want := remarks, "Updated: ZCAD,ZCAM,PrePolish; 4 day buffer used"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
}

func TestApplyRulesToRow_mainScheduling_skipInvalidProcessDates(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"PrePolish",
		"FanukSetting",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             3,
		FirstBlocProcessColIndex: 1,
		LastBlocProcessColIndex:  2,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"RPOL": {"PrePolish"},
	}

	// ProdEndDt >= now triggers main scheduling.
	// Both process completion dates are the sentinel/invalid date and should remain unchanged.
	row := []string{
		"25-03-2026", // ProdEndDt
		"01-01-1900", // PrePolish (invalid/null sentinel)
		"01-01-1900", // FanukSetting (invalid/null sentinel)
		"RPOL",       // Bloc
	}

	updatedRow, _, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	if got := updatedRow[1]; got != "01-01-1900" {
		t.Fatalf("PrePolish should be unchanged when invalid: got %q, want %q", got, "01-01-1900")
	}
	if got := updatedRow[2]; got != "01-01-1900" {
		t.Fatalf("FanukSetting should be unchanged when invalid: got %q, want %q", got, "01-01-1900")
	}
}

func TestApplyRulesToRow_mainScheduling_filingAndPrePolishSameDayAllowed(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"Filing",
		"PFMG",
		"PrePolish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1, // scanStart = Filing
		LastBlocProcessColIndex:  3, // scanEnd = PrePolish
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	// Bloc maps to a process start at Filing.
	processMap := process_map.ProcessMap{
		"RFIL": {"Filing"},
	}

	row := []string{
		"30-03-2026", // ProdEndDt >= now triggers main scheduling.
		"01-03-2026", // Filing (< now)
		"01-01-1900", // PFMG invalid -> skipped (so Filing and PrePolish become consecutive updated steps)
		"01-03-2026", // PrePolish (< now)
		"RFIL",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	// Current business day for Fri 20-Mar-2026 is the same day.
	if got := updatedRow[1]; got != "20-03-2026" {
		t.Fatalf("Filing updated date: got %q, want %q", got, "20-03-2026")
	}

	// Filing and PrePolish are allowed to be on the same day, so PrePolish
	// should not be forced to prev+1.
	if got := updatedRow[3]; got != "20-03-2026" {
		t.Fatalf("PrePolish updated date: got %q, want %q", got, "20-03-2026")
	}

	// Ensure skipped invalid column remains unchanged.
	if got := updatedRow[2]; got != "01-01-1900" {
		t.Fatalf("PFMG should be unchanged (invalid): got %q, want %q", got, "01-01-1900")
	}

	if got, want := remarks, "Updated: Filing,PrePolish; changes made"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
}

func TestApplyRulesToRow_mainScheduling_scanStartInvalid_noUpdatesBeforeStarted_breaksWithNoChangesMade(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC) // Friday

	header := []string{
		"ProdEndDt",
		"ZCAD",
		"ZCAM",
		"Polish",
		"Bloc",
	}

	cfg := RulesConfig{
		ProdEndDtColIndex:        0,
		BLOCColIndex:             4,
		FirstBlocProcessColIndex: 1, // scanStart
		LastBlocProcessColIndex:  3,
		NullDateYearWindowX:      5,
		RemarksExtensionNeeded:   "extension needed",
	}

	processMap := process_map.ProcessMap{
		"ZCAD": {"ZCAD"},
	}

	// ProdEndDt >= now triggers main scheduling.
	// scanStart (ZCAD at col=1) is invalid/null sentinel, so started=false.
	// First valid process date (ZCAM at col=2) is already >= CurrentDate,
	// so we stop before any updates.
	row := []string{
		"30-03-2026", // ProdEndDt
		"01-01-1900", // ZCAD invalid -> scanStart invalid => started=false
		"23-03-2026", // ZCAM >= now (Fri 20-Mar-2026)
		"05-03-2026", // Polish (should remain unchanged because break happens earlier)
		"ZCAD",       // Bloc
	}

	updatedRow, remarks, err := ApplyRulesToRow(header, row, cfg, processMap, now, nil)
	if err != nil {
		t.Fatalf("ApplyRulesToRow: %v", err)
	}

	// No process columns should change.
	for i := cfg.FirstBlocProcessColIndex; i <= cfg.LastBlocProcessColIndex; i++ {
		if got, want := updatedRow[i], row[i]; got != want {
			t.Fatalf("process column %d changed: got %q, want %q", i, got, want)
		}
	}

	// Remarks must reflect that no columns were updated.
	if got, want := remarks, "No changes made"; got != want {
		t.Fatalf("remarks: got %q, want %q", got, want)
	}
}
