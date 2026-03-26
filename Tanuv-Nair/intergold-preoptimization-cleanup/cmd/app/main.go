// Package main is the entry point for the preoptimization cleanup tool.
package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
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

	// Load dotenv file if present so env-based configuration works out of the box.
	// Missing dotenv file is not an error.
	_ = loadDotEnvFileIfPresent(args.envFilePath)

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
		var logDir string
		if outputPath != "" {
			logDir = filepath.Dir(outputPath)
		} else {
			logDir, _ = os.Getwd()
		}
		logPath := filepath.Join(logDir, logger.LogFileName)
		fileLogger, err := logger.New(logPath)
		if err != nil {
			log.Fatalf("cannot create log file: %v", err)
		}
		appLog = fileLogger
	}
	defer appLog.Close()

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

func loadDotEnvFileIfPresent(path string) error {
	if _, err := os.Stat(path); err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	return godotenv.Load(path)
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
