// Package main is the entry point for the preoptimization cleanup tool.
package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"intergold-preoptimization-cleanup/internal/cleanup"
	"intergold-preoptimization-cleanup/internal/config"
	"intergold-preoptimization-cleanup/internal/logger"

	"github.com/joho/godotenv"
)

type noOpLogger struct{}

func (n *noOpLogger) Log(_ string) {}

func (n *noOpLogger) Close() error { return nil }

func loggingEnabled() bool {
	v := strings.TrimSpace(strings.ToLower(os.Getenv("ENABLE_LOGGING")))
	if v == "" {
		return true
	}
	switch v {
	case "true", "1", "yes", "on":
		return true
	default:
		return false
	}
}

func main() {
	args, err := parseArgs(flag.CommandLine, os.Args[1:])
	if err != nil {
		flag.Usage()
		log.Fatal(err)
	}

	// Resolve bare filenames against the executable's directory so that default
	// file lookups succeed regardless of the process working directory.
	exeDir, err := config.ExecutableDir()
	if err != nil {
		log.Fatalf("cannot resolve executable directory: %v", err)
	}
	args.inputPath = resolveRelativeToExeDir(args.inputPath, exeDir)
	args.outputPath = resolveRelativeToExeDir(args.outputPath, exeDir)
	args.processMapPath = resolveRelativeToExeDir(args.processMapPath, exeDir)
	args.holidayMasterPath = resolveRelativeToExeDir(args.holidayMasterPath, exeDir)
	args.envFilePath = resolveRelativeToExeDir(args.envFilePath, exeDir)

	// Load dotenv file if present so env-based configuration works out of the box.
	// Missing dotenv file is not an error.
	dotEnvMissing, err := loadDotEnvFileIfPresent(args.envFilePath)
	if err != nil {
		log.Fatalf("load env file: %v", err)
	}

	// Process map and holiday paths come only from flags or defaults,
	// not from environment variables or .env (cleanup still receives paths via Setenv below).
	_ = os.Unsetenv("PROCESS_MAP_CSV_PATH")
	_ = os.Unsetenv("HOLIDAYS_CSV_PATH")

	inputPath := args.inputPath
	outputPath := args.outputPath
	processMapPath := resolveProcessMapPath(args.processMapPath, "preoptimization_process_map.csv")
	holidayPath := resolveHolidayMasterPath(args.holidayMasterPath, "Holiday_master.csv")

	// Derive output path so we know where to create the log file (same dir as output CSV).
	if outputPath == "" && inputPath != "" {
		if ext := len(inputPath) - 4; ext > 0 && inputPath[ext:] == ".csv" {
			outputPath = inputPath[:ext] + "_preoptimization_cleanup.csv"
		} else {
			outputPath = inputPath + "_preoptimization_cleanup.csv"
		}
	}

	var appLog cleanup.Logger = &noOpLogger{}
	if loggingEnabled() {
		// Create log file in all cases (success or failure) so every run is recorded.
		logPath, err := resolveDefaultLogPath()
		if err != nil {
			log.Fatalf("cannot resolve log path: %v", err)
		}
		fileLogger, err := logger.New(logPath)
		if err != nil {
			log.Fatalf("cannot create log file: %v", err)
		}
		appLog = fileLogger
	}
	defer appLog.Close()

	if dotEnvMissing {
		for _, line := range dotEnvMissingLogLines(args.envFilePath) {
			appLog.Log(line)
		}
	}

	appLog.Log("Starting preoptimization cleanup")
	appLog.Log("Input file: " + inputPath)
	appLog.Log("Output file: " + outputPath)
	appLog.Log("Process map file: " + processMapPath)

	if err := config.ValidateInputPath(processMapPath); err != nil {
		appLog.Log("Validation failed: process map: " + err.Error())
		log.Fatalf("process map: %v", err)
	}
	_ = os.Setenv("PROCESS_MAP_CSV_PATH", processMapPath)

	if err := config.ValidateInputPath(holidayPath); err != nil {
		appLog.Log("Validation failed: holiday master: " + err.Error())
		log.Fatalf("holiday master: %v", err)
	}
	_ = os.Setenv("HOLIDAYS_CSV_PATH", holidayPath)
	appLog.Log("Holiday master file: " + holidayPath)

	if err := config.ValidateInputPath(inputPath); err != nil {
		appLog.Log("Validation failed: " + err.Error())
		log.Fatalf("invalid input: %v", err)
	}

	if inputRows, outputRows, err := run(inputPath, outputPath, appLog); err != nil {
		appLog.Log("Cleanup failed: " + err.Error())
		log.Fatalf("cleanup failed: %v", err)
	} else {
		appLog.Log("Input row count: " + strconv.Itoa(inputRows))
		appLog.Log("Output row count: " + strconv.Itoa(outputRows))
	}

	appLog.Log("CSV file generated successfully")
}

// run performs preoptimization cleanup using the provided logger. The caller is responsible for
// logging success or failure; run only returns the row counts and error. It is exported for testing.
func run(inputPath, outputPath string, appLog cleanup.Logger) (inputRows, outputRows int, err error) {
	return cleanup.Run(inputPath, outputPath, appLog)
}

// resolveRelativeToExeDir resolves a bare filename against exeDir so that
// default file lookups are relative to the executable's location rather than
// the process working directory. Absolute paths and paths that already contain
// a directory separator are returned unchanged.
func resolveRelativeToExeDir(path, exeDir string) string {
	if path == "" || filepath.IsAbs(path) {
		return path
	}
	if filepath.Dir(path) == "." {
		return filepath.Join(exeDir, path)
	}
	return path
}

// resolveProcessMapPath returns the process map path: flag if set, else default.
func resolveProcessMapPath(flagVal, defaultPath string) string {
	if flagVal != "" {
		return flagVal
	}
	return defaultPath
}

// resolveHolidayMasterPath returns the holiday master path: flag if set, else default.
func resolveHolidayMasterPath(flagVal, defaultPath string) string {
	if flagVal != "" {
		return flagVal
	}
	return defaultPath
}

func loadDotEnvFileIfPresent(path string) (missing bool, err error) {
	if _, err := os.Stat(path); err != nil {
		if os.IsNotExist(err) {
			return true, nil
		}
		return false, err
	}
	if err := godotenv.Load(path); err != nil {
		return false, err
	}
	return false, nil
}

func resolveDefaultLogPath() (string, error) {
	exeDir, err := config.ExecutableDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(exeDir, logger.LogFileName), nil
}

func dotEnvMissingLogLines(path string) []string {
	defaults := map[string]string{
		"ENABLE_LOGGING":               "true",
		"PROD_END_DT_COL_INDEX":        "W",
		"BLOC_COL_INDEX":               "BD",
		"FIRST_BLOC_PROCESS_COL_INDEX": "AB",
		"LAST_BLOC_PROCESS_COL_INDEX":  "AY",
		"REMARKS_COLUMN_NAME":          "Remarks",
		"NULL_DATE_YEAR_WINDOW_X":      "5",
		"REMARKS_EXTENSION_NEEDED":     "extension needed",
		"PROCESS_MAP_KEY_COL_INDEX":    "0",
		"PROCESS_MAP_VALUE_COL_INDEX":  "1",
		"HOLIDAYS_KEY_COL_INDEX":       "0",
		"HOLIDAYS_VALUE_COL_INDEX":     "1",
	}
	keys := make([]string, 0, len(defaults))
	for k := range defaults {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	pairs := make([]string, 0, len(keys))
	for _, k := range keys {
		pairs = append(pairs, k+"="+defaults[k])
	}

	return []string{
		"dotenv file not found: " + path,
		"using defaults: " + strings.Join(pairs, ", "),
	}
}

type appArgs struct {
	inputPath         string
	outputPath        string
	processMapPath    string
	holidayMasterPath string
	envFilePath       string
}

func parseArgs(fs *flag.FlagSet, args []string) (appArgs, error) {
	var a appArgs
	fs.StringVar(&a.inputPath, "input", "ppc-data.csv", "path to the input data file")
	fs.StringVar(&a.inputPath, "i", "ppc-data.csv", "path to the input data file")
	fs.StringVar(&a.outputPath, "output", "", "path to the output file (optional, default: derived from input)")
	fs.StringVar(&a.outputPath, "o", "", "path to the output file (optional, default: derived from input)")
	fs.StringVar(&a.processMapPath, "process-map", "preoptimization_process_map.csv", "path to preoptimization_process_map.csv")
	fs.StringVar(&a.holidayMasterPath, "holiday-master", "Holiday_master.csv", "path to Holiday_master.csv")
	fs.StringVar(&a.envFilePath, "env-file", ".env", "path to dotenv file (optional; default: .env)")

	if err := fs.Parse(args); err != nil {
		return appArgs{}, err
	}

	a.inputPath = config.NormalizePath(a.inputPath)
	a.outputPath = config.NormalizePath(a.outputPath)
	a.processMapPath = config.NormalizePath(a.processMapPath)
	a.holidayMasterPath = config.NormalizePath(a.holidayMasterPath)
	a.envFilePath = config.NormalizePath(a.envFilePath)

	if a.inputPath == "" {
		return appArgs{}, fmt.Errorf("input file path is required")
	}
	return a, nil
}
