package cleanup

import (
	"bytes"
	"encoding/csv"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestRunStream_appendsRemarksColumnToOutputHeader(t *testing.T) {
	input := "A,B\n1,2\n"

	var out bytes.Buffer
	_, _, err := RunStream(strings.NewReader(input), &out, nil)
	if err != nil {
		t.Fatalf("RunStream: %v", err)
	}

	reader := csv.NewReader(bytes.NewReader(out.Bytes()))
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}

	if len(records) != 2 { // header + 1 data row
		t.Fatalf("expected header + 1 data row, got %d records", len(records))
	}
	wantHeader := []string{"A", "B", "Remarks"}
	if len(records[0]) != len(wantHeader) {
		t.Fatalf("header column count: got %d, want %d", len(records[0]), len(wantHeader))
	}
	for i := range wantHeader {
		if records[0][i] != wantHeader[i] {
			t.Fatalf("header[%d]: got %q, want %q", i, records[0][i], wantHeader[i])
		}
	}
}

func TestRunStream_appendsEmptyRemarksForEachInputRow(t *testing.T) {
	input := "" +
		"A,B\n" +
		"1,2\n" +
		"3,4\n"

	var out bytes.Buffer
	_, _, err := RunStream(strings.NewReader(input), &out, nil)
	if err != nil {
		t.Fatalf("RunStream: %v", err)
	}

	reader := csv.NewReader(bytes.NewReader(out.Bytes()))
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}

	if len(records) != 3 { // header + 2 data rows
		t.Fatalf("expected header + 2 data rows, got %d records", len(records))
	}

	// Each output row should have an extra column, and the new column should be empty.
	if got := records[1][2]; got != "" {
		t.Fatalf("row1 remarks: got %q, want empty", got)
	}
	if got := records[2][2]; got != "" {
		t.Fatalf("row2 remarks: got %q, want empty", got)
	}
}

func TestRun_doesNotCreateOutputFileWhenInputHasNoRecords(t *testing.T) {
	dir := t.TempDir()
	inputPath := filepath.Join(dir, "input.csv")
	outputPath := filepath.Join(dir, "output.csv")

	if err := os.WriteFile(inputPath, []byte(""), 0600); err != nil {
		t.Fatalf("write input: %v", err)
	}

	_, _, err := Run(inputPath, outputPath, nil)
	if err == nil {
		t.Fatal("Run expected to fail on empty input, got nil error")
	}

	if _, statErr := os.Stat(outputPath); statErr == nil {
		t.Fatalf("output file must not exist when Run fails, but %q exists", outputPath)
	} else if !os.IsNotExist(statErr) {
		t.Fatalf("stat output file: %v", statErr)
	}
}

type bufferLogger struct {
	messages []string
}

func (b *bufferLogger) Log(msg string) {
	b.messages = append(b.messages, msg)
}

func (b *bufferLogger) Close() error {
	return nil
}

type failingWriter struct{}

func (failingWriter) Write(p []byte) (n int, err error) {
	return 0, errors.New("write failed")
}

func TestRunStream_logsMidProcessWhenWriteFails(t *testing.T) {
	input := "A,B\n1,2\n"
	log := &bufferLogger{}

	_, _, err := RunStream(strings.NewReader(input), failingWriter{}, log)
	if err == nil {
		t.Fatal("RunStream expected to fail when writer Write fails")
	}

	var found bool
	for _, m := range log.messages {
		if strings.Contains(m, "mid-process") {
			found = true
			break
		}
	}
	if !found {
		t.Fatalf("expected a mid-process log message, got %v", log.messages)
	}
}

func TestRunStream_appendsRemarksEvenIfInputAlreadyHasRemarksColumn(t *testing.T) {
	input := "A,Remarks\n1,existing\n"

	var out bytes.Buffer
	_, _, err := RunStream(strings.NewReader(input), &out, nil)
	if err != nil {
		t.Fatalf("RunStream: %v", err)
	}

	reader := csv.NewReader(bytes.NewReader(out.Bytes()))
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}

	if len(records) != 2 {
		t.Fatalf("expected header + 1 data row, got %d records", len(records))
	}

	wantHeader := []string{"A", "Remarks", "Remarks"}
	if len(records[0]) != len(wantHeader) {
		t.Fatalf("header column count: got %d, want %d", len(records[0]), len(wantHeader))
	}
	for i := range wantHeader {
		if records[0][i] != wantHeader[i] {
			t.Fatalf("header[%d]: got %q, want %q", i, records[0][i], wantHeader[i])
		}
	}

	// Appended remarks column should be empty by default.
	if got := records[1][2]; got != "" {
		t.Fatalf("appended remarks: got %q, want empty", got)
	}
}

func TestRunStream_withDefaultEnvConfigAndShortHeader_fallsBackToPlaceholderBehavior(t *testing.T) {
	// Ensure defaults apply (via rulesConfigFromEnv fallbacks) but the input CSV is too small
	// for those indices. The cleanup should fall back to placeholder behavior instead of erroring.
	t.Setenv("PROD_END_DT_COL_INDEX", "")
	t.Setenv("BLOC_COL_INDEX", "")
	t.Setenv("FIRST_BLOC_PROCESS_COL_INDEX", "")
	t.Setenv("LAST_BLOC_PROCESS_COL_INDEX", "")
	t.Setenv("NULL_DATE_YEAR_WINDOW_X", "")
	t.Setenv("REMARKS_EXTENSION_NEEDED", "")
	t.Setenv("REMARKS_COLUMN_NAME", "")

	dir := t.TempDir()
	processMapPath := filepath.Join(dir, "process_map.csv")
	if err := os.WriteFile(processMapPath, []byte("Process,PPC Module Description\nRPOL,Polish\n"), 0600); err != nil {
		t.Fatalf("write process map csv: %v", err)
	}
	t.Setenv("PROCESS_MAP_CSV_PATH", processMapPath)

	emptyHolidaysPath := filepath.Join(dir, "no_holidays.csv")
	if err := os.WriteFile(emptyHolidaysPath, []byte("Date,Status\n"), 0600); err != nil {
		t.Fatalf("write empty holidays csv: %v", err)
	}
	t.Setenv("HOLIDAYS_CSV_PATH", emptyHolidaysPath)

	input := "A,B\n1,2\n"
	var out bytes.Buffer
	_, _, err := RunStream(strings.NewReader(input), &out, nil)
	if err != nil {
		t.Fatalf("RunStream: %v", err)
	}

	reader := csv.NewReader(bytes.NewReader(out.Bytes()))
	reader.FieldsPerRecord = -1
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}
	if len(records) != 2 {
		t.Fatalf("expected header + 1 data row, got %d records", len(records))
	}
	if got := records[0][len(records[0])-1]; got != "Remarks" {
		t.Fatalf("output header last column: got %q, want %q", got, "Remarks")
	}
	if got := records[1][len(records[1])-1]; got != "" {
		t.Fatalf("output remarks should be empty in placeholder mode, got %q", got)
	}
}

func TestRunStream_appliesBlocSchedulingRules_whenProdEndBeforeCurrentDate_andBlocIsRPOL(t *testing.T) {
	// Set deterministic config so the rule engine can locate the relevant columns.
	t.Setenv("PROD_END_DT_COL_INDEX", "0")
	t.Setenv("BLOC_COL_INDEX", "4")
	t.Setenv("FIRST_BLOC_PROCESS_COL_INDEX", "1")
	t.Setenv("LAST_BLOC_PROCESS_COL_INDEX", "3")
	t.Setenv("NULL_DATE_YEAR_WINDOW_X", "100")
	t.Setenv("REMARKS_EXTENSION_NEEDED", "extension needed")
	t.Setenv("REMARKS_COLUMN_NAME", "Remarks")

	dir := t.TempDir()
	processMapPath := filepath.Join(dir, "process_map.csv")
	if err := os.WriteFile(processMapPath, []byte("Process,PPC Module Description\nRPOL,Polish\n"), 0600); err != nil {
		t.Fatalf("write process map csv: %v", err)
	}
	t.Setenv("PROCESS_MAP_CSV_PATH", processMapPath)

	emptyHolidaysPath := filepath.Join(dir, "no_holidays.csv")
	if err := os.WriteFile(emptyHolidaysPath, []byte("Date,Status\n"), 0600); err != nil {
		t.Fatalf("write empty holidays csv: %v", err)
	}
	t.Setenv("HOLIDAYS_CSV_PATH", emptyHolidaysPath)

	now := dateOnlyUTC(time.Now().UTC())
	prodEnd := now.AddDate(0, 0, -10)
	prodEndStr := prodEnd.Format(processDateLayout)

	// Mapped column set to CurrentDate as a business day (not calendar +1).
	expectedPolish := formatDDMMYYYY(adjustBusinessDays(now, 0, nil))

	input := strings.Join([]string{
		"ProdEndDt,ZCAD,ZCAM,Polish,Bloc",
		// ProdEndDt < now, Bloc == RPOL => Polish should be updated.
		prodEndStr + ",01-01-2020,01-01-2020,01-01-1900,RPOL",
		"",
	}, "\n")

	var out bytes.Buffer
	_, _, err := RunStream(strings.NewReader(input), &out, nil)
	if err != nil {
		t.Fatalf("RunStream: %v", err)
	}

	reader := csv.NewReader(bytes.NewReader(out.Bytes()))
	reader.FieldsPerRecord = -1
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}
	if len(records) != 2 {
		t.Fatalf("expected header + 1 data row, got %d records", len(records))
	}

	// Output columns: input columns + trailing Remarks.
	gotPolish := records[1][3]
	if gotPolish != expectedPolish {
		t.Fatalf("Polish: got %q, want %q", gotPolish, expectedPolish)
	}
	gotRemarks := records[1][5]
	if !strings.Contains(gotRemarks, "Updated") {
		t.Fatalf("remarks should indicate update, got %q", gotRemarks)
	}
}

func TestLoadHolidayProviderFromCSVPath_noHeader_singleColumn(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	path := filepath.Join(dir, "holidays.csv")
	if err := os.WriteFile(path, []byte("25-02-2026,H\n26-02-2026,H\n"), 0600); err != nil {
		t.Fatalf("write holidays csv: %v", err)
	}

	provider, err := loadHolidayProviderFromCSVPath(path, 0, 1)
	if err != nil {
		t.Fatalf("loadHolidayProviderFromCSVPath: %v", err)
	}
	if provider(time.Date(2026, 2, 25, 0, 0, 0, 0, time.UTC)) != true {
		t.Fatalf("expected 25-02-2026 to be a holiday")
	}
	if provider(time.Date(2026, 2, 24, 0, 0, 0, 0, time.UTC)) != false {
		t.Fatalf("expected 24-02-2026 to be not a holiday")
	}
}

func TestLoadHolidayProviderFromCSVPath_dateInSecondColumn(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	path := filepath.Join(dir, "holidays.csv")
	if err := os.WriteFile(path, []byte("Name,Date\nX,25-02-2026\nY,26-02-2026\n"), 0600); err != nil {
		t.Fatalf("write holidays csv: %v", err)
	}

	// Date column is index 1; label column index 0 (both required non-empty per row).
	provider, err := loadHolidayProviderFromCSVPath(path, 1, 0)
	if err != nil {
		t.Fatalf("loadHolidayProviderFromCSVPath: %v", err)
	}
	if provider(time.Date(2026, 2, 25, 0, 0, 0, 0, time.UTC)) != true {
		t.Fatalf("expected 25-02-2026 to be a holiday")
	}
	if provider(time.Date(2026, 2, 24, 0, 0, 0, 0, time.UTC)) != false {
		t.Fatalf("expected 24-02-2026 to be not a holiday")
	}
}

func TestLoadHolidayProviderFromEnv_loadsFixtureWhenPathSet(t *testing.T) {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	repoRoot := filepath.Clean(filepath.Join(cwd, "../.."))
	masterPath := filepath.Join(repoRoot, "maps/holiday_master.csv")
	fi, statErr := os.Stat(masterPath)
	if statErr != nil || fi.IsDir() {
		t.Skip("no repo maps/holiday_master.csv fixture")
	}

	t.Setenv("HOLIDAYS_CSV_PATH", masterPath)
	t.Setenv("HOLIDAYS_KEY_COL_INDEX", "")
	t.Setenv("HOLIDAYS_VALUE_COL_INDEX", "")

	holFn, err := loadHolidayProviderFromEnv()
	if err != nil {
		t.Fatalf("loadHolidayProviderFromEnv: %v", err)
	}
	if holFn == nil {
		t.Fatalf("expected holiday provider")
	}
	republic := time.Date(2026, 1, 26, 0, 0, 0, 0, time.UTC)
	if !holFn(republic) {
		t.Fatalf("expected 26-01-2026 to be a holiday from holiday master")
	}
}

func TestLoadHolidayProviderFromCSVPath_mixedDateFormats(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	path := filepath.Join(dir, "holidays.csv")
	content := "Date,Holiday_status\n04-03-26,Holi\n26-01-2026,Republic Day\n"
	if err := os.WriteFile(path, []byte(content), 0600); err != nil {
		t.Fatalf("write holidays csv: %v", err)
	}

	provider, err := loadHolidayProviderFromCSVPath(path, 0, 1)
	if err != nil {
		t.Fatalf("loadHolidayProviderFromCSVPath: %v", err)
	}
	holi := time.Date(2026, 3, 4, 0, 0, 0, 0, time.UTC)
	if !provider(holi) {
		t.Fatalf("expected 04-03-26 to be a holiday (2026-03-04)")
	}
	republic := time.Date(2026, 1, 26, 0, 0, 0, 0, time.UTC)
	if !provider(republic) {
		t.Fatalf("expected 26-01-2026 to be a holiday")
	}
	if provider(time.Date(2026, 2, 1, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("expected 01-02-2026 to not be a holiday")
	}
}

func TestLoadProcessMap_usesPROCESS_MAP_CSV_PATHEnvVar(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "preoptimization_process_map.csv")

	// RPOL is "Polish" in the real fixture. We override it to ensure the env var
	// path is actually used.
	content := "" +
		"Process,PPC Module Description\n" +
		"RPOL,NotARealColumn\n"
	if err := os.WriteFile(path, []byte(content), 0600); err != nil {
		t.Fatalf("write process map fixture: %v", err)
	}

	t.Setenv("PROCESS_MAP_CSV_PATH", path)
	pm, err := loadProcessMap()
	if err != nil {
		t.Fatalf("loadProcessMap: %v", err)
	}

	got := pm["RPOL"]
	if len(got) != 1 || got[0] != "NotARealColumn" {
		t.Fatalf("RPOL mapping: got %v, want [NotARealColumn]", got)
	}
}

func TestLoadProcessMap_customColumnIndices(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "preoptimization_process_map.csv")
	content := "" +
		"A,B,Process,PPC\n" +
		"x,x,RPOL,NotARealColumn\n"
	if err := os.WriteFile(path, []byte(content), 0600); err != nil {
		t.Fatalf("write process map fixture: %v", err)
	}

	t.Setenv("PROCESS_MAP_CSV_PATH", path)
	t.Setenv("PROCESS_MAP_KEY_COL_INDEX", "C")
	t.Setenv("PROCESS_MAP_VALUE_COL_INDEX", "D")

	pm, err := loadProcessMap()
	if err != nil {
		t.Fatalf("loadProcessMap: %v", err)
	}
	got := pm["RPOL"]
	if len(got) != 1 || got[0] != "NotARealColumn" {
		t.Fatalf("RPOL mapping: got %v, want [NotARealColumn]", got)
	}
}
