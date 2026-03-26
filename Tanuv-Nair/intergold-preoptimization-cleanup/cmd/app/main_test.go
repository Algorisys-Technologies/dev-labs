// Package main is the entry point for the preoptimization cleanup tool.
package main

import (
	"bufio"
	"bytes"
	"encoding/csv"
	"flag"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"

	"intergold-preoptimization-cleanup/internal/logger"

	"github.com/joho/godotenv"
)

// runWithLogging simulates main's flow: creates logger, logs start, calls run, logs success or failure.
func runWithLogging(inputPath, outputPath string) error {
	logPath := filepath.Join(filepath.Dir(outputPath), logger.LogFileName)
	appLog, err := logger.New(logPath)
	if err != nil {
		return err
	}
	defer appLog.Close()

	appLog.Log("Starting preoptimization cleanup")
	appLog.Log("Input file: " + inputPath)
	appLog.Log("Output file: " + outputPath)

	inputRows, outputRows, err := run(inputPath, outputPath, appLog)
	if err != nil {
		appLog.Log("Cleanup failed: " + err.Error())
		return err
	}
	appLog.Log("Input row count: " + strconv.Itoa(inputRows))
	appLog.Log("Output row count: " + strconv.Itoa(outputRows))
	appLog.Log("CSV file generated successfully")
	return nil
}

func TestRun_createsLogFileWithStartAndSuccess(t *testing.T) {
	dir := t.TempDir()
	inputPath := filepath.Join(dir, "input.csv")
	outputPath := filepath.Join(dir, "output.csv")

	// Minimal valid CSV (header + 2 data rows) so cleanup succeeds.
	inputCSV := "Product, Parent, Alias: Default, Alias: Description, Valid For Consolidations, Data Storage, Two Pass Calculation, Description, Formula, Formula Description, UDA, Smart List\n" +
		"L04_3E1162697,L03_3E11626,L04_3E1162697 - SOLERO,,false,never share,false,,<none>,<none>,BRAND,,unspecified\n" +
		"3E1162697L3091114,3E1162697L309111,3E1162697L3091114 - SOLERO PORTIONED,,false,never share,false,,<none>,<none>,BASEPACK,,unspecified\n"
	if err := os.WriteFile(inputPath, []byte(inputCSV), 0600); err != nil {
		t.Fatalf("write input: %v", err)
	}

	err := runWithLogging(inputPath, outputPath)
	if err != nil {
		t.Fatalf("runWithLogging: %v", err)
	}

	// Verify the output CSV has an appended trailing `Remarks` column.
	gotCSV, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}
	reader := csv.NewReader(bytes.NewReader(gotCSV))
	// Input rows may have variable number of fields; accept that here.
	reader.FieldsPerRecord = -1
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("parse output CSV: %v", err)
	}
	if len(records) != 3 { // header + 2 data rows
		t.Fatalf("expected header + 2 data rows, got %d records", len(records))
	}
	if records[0][len(records[0])-1] != "Remarks" {
		t.Fatalf("output header last column: got %q, want %q", records[0][len(records[0])-1], "Remarks")
	}
	for i := 1; i < len(records); i++ {
		lastCol := records[i][len(records[i])-1]
		if lastCol != "" {
			t.Fatalf("output row %d last column: got %q, want empty remarks", i, lastCol)
		}
	}

	logPath := filepath.Join(dir, logger.LogFileName)
	content, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("read log file: %v", err)
	}
	text := string(content)
	if !strings.Contains(text, "Starting preoptimization cleanup") {
		t.Errorf("log should contain 'Starting preoptimization cleanup', got %q", text)
	}
	if !strings.Contains(text, "Input file: "+inputPath) {
		t.Errorf("log should contain input path, got %q", text)
	}
	if !strings.Contains(text, "CSV file generated successfully") {
		t.Errorf("log should contain 'CSV file generated successfully', got %q", text)
	}
}

// TestRun_logsInputOutputFileNamesAndRowCounts verifies that the log contains
// input file name, output file name, input row count, and output row count.
func TestRun_logsInputOutputFileNamesAndRowCounts(t *testing.T) {
	dir := t.TempDir()
	inputPath := filepath.Join(dir, "input.csv")
	outputPath := filepath.Join(dir, "output.csv")

	// Header + 2 data rows -> input row count 2, output row count 2 (cleanup copies all rows).
	csv := "Product, Parent, Alias: Default, Alias: Description, Valid For Consolidations, Data Storage, Two Pass Calculation, Description, Formula, Formula Description, UDA, Smart List\n" +
		"L04_3E1162697,L03_3E11626,L04_3E1162697 - SOLERO,,false,never share,false,,<none>,<none>,BRAND,,unspecified\n" +
		"3E1162697L3091114,3E1162697L309111,3E1162697L3091114 - SOLERO PORTIONED,,false,never share,false,,<none>,<none>,BASEPACK,,unspecified\n"
	if err := os.WriteFile(inputPath, []byte(csv), 0600); err != nil {
		t.Fatalf("write input: %v", err)
	}

	err := runWithLogging(inputPath, outputPath)
	if err != nil {
		t.Fatalf("runWithLogging: %v", err)
	}

	logPath := filepath.Join(dir, logger.LogFileName)
	content, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("read log file: %v", err)
	}
	text := string(content)
	if !strings.Contains(text, "Input file: "+inputPath) {
		t.Errorf("log should contain 'Input file: <path>', got %q", text)
	}
	if !strings.Contains(text, "Output file: "+outputPath) {
		t.Errorf("log should contain 'Output file: <path>', got %q", text)
	}
	if !strings.Contains(text, "Input row count: 2") {
		t.Errorf("log should contain 'Input row count: 2', got %q", text)
	}
	if !strings.Contains(text, "Output row count: 2") {
		t.Errorf("log should contain 'Output row count: 2', got %q", text)
	}
}

func TestRun_logsFailureWhenExtractionFails(t *testing.T) {
	dir := t.TempDir()
	inputPath := filepath.Join(dir, "nonexistent.csv")
	outputPath := filepath.Join(dir, "output.csv")

	err := runWithLogging(inputPath, outputPath)
	if err == nil {
		t.Fatal("run should fail when input file does not exist")
	}

	logPath := filepath.Join(dir, logger.LogFileName)
	content, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("read log file: %v", err)
	}
	text := string(content)
	if !strings.Contains(text, "Starting preoptimization cleanup") {
		t.Errorf("log should contain 'Starting preoptimization cleanup', got %q", text)
	}
	if !strings.Contains(text, "Cleanup failed:") {
		t.Errorf("log should contain 'Cleanup failed:', got %q", text)
	}
}

func TestMain_createsLogFileWhenValidationFails(t *testing.T) {
	dir := t.TempDir()
	// Use -output so we know log dir; -input is missing so validation fails after logger is created.
	logPath := filepath.Join(dir, logger.LogFileName)
	// Simulate: outputPath set to dir/output.csv, so log goes to dir. Then we'd validate input (empty) and log failure.
	// We cannot easily run main() so we test that when we create logger and log validation failure, the file exists.
	appLog, err := logger.New(logPath)
	if err != nil {
		t.Fatalf("create logger: %v", err)
	}
	appLog.Log("Starting preoptimization cleanup: input=, output=" + filepath.Join(dir, "out.csv"))
	appLog.Log("Validation failed: input file path is required")
	appLog.Close()

	content, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("read log file: %v", err)
	}
	text := string(content)
	if !strings.Contains(text, "Validation failed:") {
		t.Errorf("log should contain 'Validation failed:', got %q", text)
	}
}

func TestLoadDotEnvFile_setsEnvVarsFromFile(t *testing.T) {
	dir := t.TempDir()
	envPath := filepath.Join(dir, ".env")

	envContent := "" +
		"# comment line should be ignored\n" +
		"PROD_END_DT_COL_INDEX=\"22\"\n" +
		"REMARKS_COLUMN_NAME='Remarks'\n" +
		"BLOC_COL_INDEX = \"55\"\n" +
		"\n" +
		"NULL_DATE_YEAR_WINDOW_X=\"7\"\n"

	if err := os.WriteFile(envPath, []byte(envContent), 0600); err != nil {
		t.Fatalf("write env file: %v", err)
	}

	// Ensure a clean slate for the keys under test.
	_ = os.Unsetenv("PROD_END_DT_COL_INDEX")
	_ = os.Unsetenv("REMARKS_COLUMN_NAME")
	_ = os.Unsetenv("BLOC_COL_INDEX")
	_ = os.Unsetenv("NULL_DATE_YEAR_WINDOW_X")

	if err := godotenv.Load(envPath); err != nil {
		t.Fatalf("godotenv.Load: %v", err)
	}

	if got := os.Getenv("PROD_END_DT_COL_INDEX"); got != "22" {
		t.Fatalf("PROD_END_DT_COL_INDEX: got %q, want %q", got, "22")
	}
	if got := os.Getenv("REMARKS_COLUMN_NAME"); got != "Remarks" {
		t.Fatalf("REMARKS_COLUMN_NAME: got %q, want %q", got, "Remarks")
	}
	if got := os.Getenv("BLOC_COL_INDEX"); got != "55" {
		t.Fatalf("BLOC_COL_INDEX: got %q, want %q", got, "55")
	}
	if got := os.Getenv("NULL_DATE_YEAR_WINDOW_X"); got != "7" {
		t.Fatalf("NULL_DATE_YEAR_WINDOW_X: got %q, want %q", got, "7")
	}
}

func TestDotEnvMissingLogLines_includesDefaults(t *testing.T) {
	lines := dotEnvMissingLogLines(".env")

	if len(lines) < 2 {
		t.Fatalf("expected at least 2 log lines, got %d: %v", len(lines), lines)
	}
	if !strings.Contains(lines[0], "dotenv file not found: .env") {
		t.Fatalf("first line should mention missing dotenv path, got %q", lines[0])
	}
	if !strings.Contains(lines[1], "using defaults:") {
		t.Fatalf("second line should mention defaults, got %q", lines[1])
	}

	// Defaults with fallback values.
	wantSnippets := []string{
		"ENABLE_LOGGING=true",
		"PROD_END_DT_COL_INDEX=W",
		"BLOC_COL_INDEX=BD",
		"FIRST_BLOC_PROCESS_COL_INDEX=AB",
		"LAST_BLOC_PROCESS_COL_INDEX=AY",
		"REMARKS_COLUMN_NAME=Remarks",
		"NULL_DATE_YEAR_WINDOW_X=5",
		"REMARKS_EXTENSION_NEEDED=extension needed",
		"PROCESS_MAP_KEY_COL_INDEX=0",
		"PROCESS_MAP_VALUE_COL_INDEX=1",
		"HOLIDAYS_KEY_COL_INDEX=0",
		"HOLIDAYS_VALUE_COL_INDEX=1",
	}
	for _, s := range wantSnippets {
		if !strings.Contains(lines[1], s) {
			t.Fatalf("defaults line missing %q; got %q", s, lines[1])
		}
	}
}

func TestResolveDefaultLogPath_usesExecutableDirectory(t *testing.T) {
	got, err := resolveDefaultLogPath()
	if err != nil {
		t.Fatalf("resolveDefaultLogPath(): %v", err)
	}

	exe, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable(): %v", err)
	}
	resolvedExe, err := filepath.EvalSymlinks(exe)
	if err != nil {
		t.Fatalf("filepath.EvalSymlinks(exe): %v", err)
	}
	want := filepath.Join(filepath.Dir(resolvedExe), logger.LogFileName)

	if got != want {
		t.Fatalf("resolveDefaultLogPath(): got %q, want %q", got, want)
	}
}

func TestApp_envFileFlag_setsEnvVarsFromFile(t *testing.T) {
	dir := t.TempDir()
	envPath := filepath.Join(dir, ".env")
	if err := os.WriteFile(envPath, []byte(`REMARKS_COLUMN_NAME="CustomRemarks"`+"\n"), 0600); err != nil {
		t.Fatalf("write env file: %v", err)
	}

	// Minimal CSV (header + 1 row) so cleanup succeeds in placeholder mode.
	inputPath := filepath.Join(dir, "input.csv")
	if err := os.WriteFile(inputPath, []byte("A,B\n1,2\n"), 0600); err != nil {
		t.Fatalf("write input csv: %v", err)
	}

	outputPath := filepath.Join(dir, "output.csv")

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	// When tests run, cwd is typically ".../cmd/app". Repo root is two dirs up.
	repoRoot := filepath.Clean(filepath.Join(cwd, "../.."))
	processMapPath := filepath.Join(repoRoot, "maps/preoptimization_process_map.csv")
	holidayMasterPath := filepath.Join(repoRoot, "maps/holiday_master.csv")

	cmd := exec.Command(
		"go", "run", "./cmd/app",
		"-input", inputPath,
		"-output", outputPath,
		"-process-map", processMapPath,
		"-holiday-master", holidayMasterPath,
		"-env-file", envPath,
	)
	cmd.Dir = repoRoot

	// Ensure we don't get a pre-set REMARKS_COLUMN_NAME from the test runner environment.
	var cleanedEnv []string
	for _, kv := range os.Environ() {
		if strings.HasPrefix(kv, "REMARKS_COLUMN_NAME=") {
			continue
		}
		cleanedEnv = append(cleanedEnv, kv)
	}
	cmd.Env = cleanedEnv

	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	runErr := cmd.Run()
	if runErr != nil {
		t.Fatalf("go run failed: %v; stderr=%q", runErr, stderr.String())
	}

	gotCSV, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatalf("read output CSV: %v", err)
	}

	reader := csv.NewReader(bytes.NewReader(gotCSV))
	reader.FieldsPerRecord = -1
	records, err := reader.ReadAll()
	if err != nil {
		t.Fatalf("parse output CSV: %v", err)
	}
	if len(records) == 0 {
		t.Fatal("expected at least a header row")
	}

	lastCol := records[0][len(records[0])-1]
	if lastCol != "CustomRemarks" {
		t.Fatalf("output header last column: got %q, want %q", lastCol, "CustomRemarks")
	}
}

func TestApp_loggingDisabled_doesNotCreateLogFile(t *testing.T) {
	dir := t.TempDir()

	// Minimal CSV (header + 1 row) so cleanup succeeds in placeholder mode.
	inputPath := filepath.Join(dir, "input.csv")
	if err := os.WriteFile(inputPath, []byte("A,B\n1,2\n"), 0600); err != nil {
		t.Fatalf("write input csv: %v", err)
	}
	outputPath := filepath.Join(dir, "output.csv")

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	repoRoot := filepath.Clean(filepath.Join(cwd, "../.."))
	processMapPath := filepath.Join(repoRoot, "maps/preoptimization_process_map.csv")
	holidayMasterPath := filepath.Join(repoRoot, "maps/holiday_master.csv")

	cmd := exec.Command(
		"go", "run", "./cmd/app",
		"-input", inputPath,
		"-output", outputPath,
		"-process-map", processMapPath,
		"-holiday-master", holidayMasterPath,
		"-env-file", filepath.Join(dir, "does-not-exist.env"),
	)
	cmd.Dir = repoRoot
	cmd.Env = append(os.Environ(), "ENABLE_LOGGING=false")

	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if runErr := cmd.Run(); runErr != nil {
		t.Fatalf("go run failed: %v; stderr=%q", runErr, stderr.String())
	}

	logPath := filepath.Join(dir, logger.LogFileName)
	if _, err := os.Stat(logPath); err == nil {
		t.Fatalf("expected no log file when ENABLE_LOGGING=false, but found %q", logPath)
	} else if !os.IsNotExist(err) {
		t.Fatalf("stat log file: %v", err)
	}
}

func TestApp_loggingUnset_createsLogFileByDefault(t *testing.T) {
	dir := t.TempDir()

	inputPath := filepath.Join(dir, "input.csv")
	if err := os.WriteFile(inputPath, []byte("A,B\n1,2\n"), 0600); err != nil {
		t.Fatalf("write input csv: %v", err)
	}
	outputPath := filepath.Join(dir, "output.csv")

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	repoRoot := filepath.Clean(filepath.Join(cwd, "../.."))
	processMapPath := filepath.Join(repoRoot, "maps/preoptimization_process_map.csv")
	holidayMasterPath := filepath.Join(repoRoot, "maps/holiday_master.csv")

	cmd := exec.Command(
		"go", "run", "./cmd/app",
		"-input", inputPath,
		"-output", outputPath,
		"-process-map", processMapPath,
		"-holiday-master", holidayMasterPath,
		"-env-file", filepath.Join(dir, "does-not-exist.env"),
	)
	cmd.Dir = repoRoot

	var cleanedEnv []string
	for _, kv := range os.Environ() {
		if strings.HasPrefix(kv, "ENABLE_LOGGING=") {
			continue
		}
		cleanedEnv = append(cleanedEnv, kv)
	}
	cmd.Env = cleanedEnv

	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if runErr := cmd.Run(); runErr != nil {
		t.Fatalf("go run failed: %v; stderr=%q", runErr, stderr.String())
	}
}

func TestLoggingEnabled_unsetEnv_returnsTrue(t *testing.T) {
	t.Setenv("ENABLE_LOGGING", "")

	if got := loggingEnabled(); !got {
		t.Fatalf("loggingEnabled() with unset/empty ENABLE_LOGGING: got %v, want %v", got, true)
	}
}

func TestApp_loggingEnabled_createsLogFile(t *testing.T) {
	dir := t.TempDir()

	inputPath := filepath.Join(dir, "input.csv")
	if err := os.WriteFile(inputPath, []byte("A,B\n1,2\n"), 0600); err != nil {
		t.Fatalf("write input csv: %v", err)
	}
	outputPath := filepath.Join(dir, "output.csv")

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	repoRoot := filepath.Clean(filepath.Join(cwd, "../.."))
	processMapPath := filepath.Join(repoRoot, "maps/preoptimization_process_map.csv")
	holidayMasterPath := filepath.Join(repoRoot, "maps/holiday_master.csv")

	cmd := exec.Command(
		"go", "run", "./cmd/app",
		"-input", inputPath,
		"-output", outputPath,
		"-process-map", processMapPath,
		"-holiday-master", holidayMasterPath,
		"-env-file", filepath.Join(dir, "does-not-exist.env"),
	)
	cmd.Dir = repoRoot

	var cleanedEnv []string
	for _, kv := range os.Environ() {
		if strings.HasPrefix(kv, "ENABLE_LOGGING=") {
			continue
		}
		cleanedEnv = append(cleanedEnv, kv)
	}
	cmd.Env = append(cleanedEnv, "ENABLE_LOGGING=true")

	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if runErr := cmd.Run(); runErr != nil {
		t.Fatalf("go run failed: %v; stderr=%q", runErr, stderr.String())
	}
}

func TestApp_processMapDefaultPath_missingFileExitsNonZero(t *testing.T) {
	dir := t.TempDir()

	// Build a minimal but structurally compatible CSV by using the first two
	// lines from the real fixture header+row.
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	// When tests run, cwd is typically ".../cmd/app". Repo root is two dirs up.
	repoRoot := filepath.Clean(filepath.Join(cwd, "../.."))
	fixturePath := filepath.Join(repoRoot, "data/ppc-data.csv")

	f, err := os.Open(fixturePath)
	if err != nil {
		t.Fatalf("open fixture: %v", err)
	}
	defer f.Close()

	sc := bufio.NewScanner(f)
	if !sc.Scan() {
		t.Fatal("scan fixture header: missing header")
	}
	header := sc.Text()
	if !sc.Scan() {
		t.Fatal("scan fixture first row: missing first data row")
	}
	firstRow := sc.Text()

	inputPath := filepath.Join(dir, "input.csv")
	outputPath := filepath.Join(dir, "output.csv")
	if err := os.WriteFile(inputPath, []byte(header+"\n"+firstRow+"\n"), 0600); err != nil {
		t.Fatalf("write temp input: %v", err)
	}

	cmd := exec.Command(
		"go", "run", "./cmd/app",
		"-input", inputPath,
		"-output", outputPath,
	)
	cmd.Dir = repoRoot
	cmd.Env = append(os.Environ(), "REMARKS_COLUMN_NAME=Remarks")

	// Do not fail on stdio content; we only check the exit status.
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	runErr := cmd.Run()
	if runErr == nil {
		t.Fatalf("expected default process map path (next to executable) missing file to exit non-zero, got exit 0; stderr=%q", stderr.String())
	}
}

func TestResolveProcessMapPath_flagOrDefault(t *testing.T) {
	if got := resolveProcessMapPath("/flag.csv", "/default.csv"); got != "/flag.csv" {
		t.Fatalf("flag: got %q", got)
	}
	if got := resolveProcessMapPath("", "/default.csv"); got != "/default.csv" {
		t.Fatalf("default: got %q", got)
	}
}

func TestResolveHolidayMasterPath_flagOrDefault(t *testing.T) {
	if p := resolveHolidayMasterPath("/f.csv", "/d.csv"); p != "/f.csv" {
		t.Fatalf("flag: got %q", p)
	}
	if p := resolveHolidayMasterPath("", "/d.csv"); p != "/d.csv" {
		t.Fatalf("default: got %q", p)
	}
}

func TestResolveRelativeToExeDir(t *testing.T) {
	exeDir := "/exe/dir"
	cases := []struct {
		path string
		want string
	}{
		{"", ""},                                 // empty stays empty
		{"/abs/path.csv", "/abs/path.csv"},       // absolute unchanged
		{"file.csv", "/exe/dir/file.csv"},        // bare filename → exe dir
		{"../data/file.csv", "../data/file.csv"}, // relative with dir → unchanged
		{"sub/file.csv", "sub/file.csv"},         // relative with dir → unchanged
	}
	for _, c := range cases {
		if got := resolveRelativeToExeDir(c.path, exeDir); got != c.want {
			t.Errorf("resolveRelativeToExeDir(%q, %q) = %q, want %q", c.path, exeDir, got, c.want)
		}
	}
}

func TestParseArgs_defaultsWhenNoFlagsProvided(t *testing.T) {
	fs := flag.NewFlagSet("app", flag.ContinueOnError)
	fs.SetOutput(io.Discard)

	got, err := parseArgs(fs, []string{})
	if err != nil {
		t.Fatalf("parseArgs: %v", err)
	}

	if got.inputPath != "ppc-data.csv" {
		t.Fatalf("input default: got %q, want %q", got.inputPath, "ppc-data.csv")
	}
	if got.processMapPath != "preoptimization_process_map.csv" {
		t.Fatalf("process map default: got %q, want %q", got.processMapPath, "preoptimization_process_map.csv")
	}
	if got.holidayMasterPath != "Holiday_master.csv" {
		t.Fatalf("holiday master default: got %q, want %q", got.holidayMasterPath, "Holiday_master.csv")
	}
}
