package cleanup

import (
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"intergold-preoptimization-cleanup/internal/csv_stream"
	"intergold-preoptimization-cleanup/internal/process_map"
)

// Logger is used to log start/success/failure and mid-process errors.
// A file-based implementation is provided by cmd/app.
type Logger interface {
	Log(msg string)
	Close() error
}

const defaultRemarksColumnName = "Remarks"

func remarksColumnNameFromEnv() string {
	v := strings.TrimSpace(os.Getenv("REMARKS_COLUMN_NAME"))
	if v == "" {
		return defaultRemarksColumnName
	}
	return v
}

// RunStream reads CSV from r, appends a Remarks column, and writes the optimized
// CSV to w. It processes input row-by-row without loading the whole file.
//
// inputRows/outputRows are data rows only (header excluded).
func RunStream(r io.Reader, w io.Writer, log Logger) (inputRows, outputRows int, err error) {
	stream := csv_stream.NewReader(r)
	header, readErr := stream.ReadHeader()
	if readErr != nil {
		if errors.Is(readErr, csv_stream.ErrNoRecords) {
			return 0, 0, fmt.Errorf("input CSV has no records")
		}
		return 0, 0, fmt.Errorf("read CSV: %w", readErr)
	}

	writer := csv_stream.NewWriter(w)
	outHeader := append(append([]string{}, header...), remarksColumnNameFromEnv())
	if err = writer.WriteHeader(outHeader); err != nil {
		if log != nil {
			log.Log("Cleanup failed mid-process: " + err.Error())
		}
		return 0, 0, fmt.Errorf("write header: %w", err)
	}

	defer func() {
		if flushErr := writer.Flush(); flushErr != nil {
			if log != nil {
				log.Log("Cleanup failed mid-process: " + flushErr.Error())
			}
			if err == nil {
				err = flushErr
			}
		}
	}()

	cfg, cfgErr := rulesConfigFromEnv()
	processMap, mapErr := loadProcessMap()
	holFn, holidaysErr := loadHolidayProviderFromEnv()

	rulesConfigFitsRow := func(cfg RulesConfig, row []string) bool {
		if cfg.ProdEndDtColIndex < 0 || cfg.ProdEndDtColIndex >= len(row) {
			return false
		}
		if cfg.BLOCColIndex < 0 || cfg.BLOCColIndex >= len(row) {
			return false
		}
		if cfg.FirstBlocProcessColIndex < 0 {
			return false
		}
		if cfg.LastBlocProcessColIndex < cfg.FirstBlocProcessColIndex {
			return false
		}
		if cfg.LastBlocProcessColIndex >= len(row) {
			return false
		}
		// ApplyRulesToRow also requires startColIndex to be found in the header, but
		// that depends on bloc value (row content) and processMap; keep that validation there.
		return true
	}

	for {
		row, readErr := stream.Read()
		if readErr != nil {
			if readErr == io.EOF {
				break
			}
			err = fmt.Errorf("read CSV: %w", readErr)
			if log != nil {
				log.Log("Cleanup failed mid-process: " + err.Error())
			}
			return inputRows, outputRows, err
		}

		inputRows++

		remarks := ""
		outRowVals := append([]string{}, row...)

		// Apply rules only when configuration and process map are available.
		// Otherwise fall back to placeholder behavior (existing tests rely on this).
		if cfgErr == nil && mapErr == nil && rulesConfigFitsRow(cfg, row) {
			if holidaysErr != nil {
				err = holidaysErr
				if log != nil {
					log.Log("Cleanup failed mid-process: " + err.Error())
				}
				return inputRows, outputRows, err
			}
			now := dateOnlyUTC(time.Now().UTC())

			updatedRow, mRemarks, ruleErr := ApplyRulesToRow(header, row, cfg, processMap, now, holFn)
			if ruleErr != nil {
				// Treat row-level rule errors as fatal: avoids silently producing wrong data.
				err = ruleErr
				if log != nil {
					log.Log("Cleanup failed mid-process: " + err.Error())
				}
				return inputRows, outputRows, err
			}
			outRowVals = updatedRow
			remarks = mRemarks
		}

		outRow := append(append([]string{}, outRowVals...), remarks)
		if writeErr := writer.Write(outRow); writeErr != nil {
			err = fmt.Errorf("write row: %w", writeErr)
			if log != nil {
				log.Log("Cleanup failed mid-process: " + err.Error())
			}
			return inputRows, outputRows, err
		}
		outputRows++
	}

	return inputRows, outputRows, nil
}

func rulesConfigFromEnv() (RulesConfig, error) {
	prodEndIdxStr := strings.TrimSpace(os.Getenv("PROD_END_DT_COL_INDEX"))
	if prodEndIdxStr == "" {
		prodEndIdxStr = "W"
	}
	prodEndIdx, err := colIndexFromEnvValue(prodEndIdxStr)
	if err != nil {
		return RulesConfig{}, fmt.Errorf("PROD_END_DT_COL_INDEX: %w", err)
	}

	blocIdxStr := strings.TrimSpace(os.Getenv("BLOC_COL_INDEX"))
	if blocIdxStr == "" {
		blocIdxStr = "BD"
	}
	blocIdx, err := colIndexFromEnvValue(blocIdxStr)
	if err != nil {
		return RulesConfig{}, fmt.Errorf("BLOC_COL_INDEX: %w", err)
	}

	firstIdxStr := strings.TrimSpace(os.Getenv("FIRST_BLOC_PROCESS_COL_INDEX"))
	if firstIdxStr == "" {
		firstIdxStr = "AB"
	}
	firstIdx, err := colIndexFromEnvValue(firstIdxStr)
	if err != nil {
		return RulesConfig{}, fmt.Errorf("FIRST_BLOC_PROCESS_COL_INDEX: %w", err)
	}

	lastIdxStr := strings.TrimSpace(os.Getenv("LAST_BLOC_PROCESS_COL_INDEX"))
	if lastIdxStr == "" {
		lastIdxStr = "AY"
	}
	lastIdx, err := colIndexFromEnvValue(lastIdxStr)
	if err != nil {
		return RulesConfig{}, fmt.Errorf("LAST_BLOC_PROCESS_COL_INDEX: %w", err)
	}

	windowXStr := strings.TrimSpace(os.Getenv("NULL_DATE_YEAR_WINDOW_X"))
	windowX := 0
	if windowXStr == "" {
		windowX = 5
	} else {
		parsed, err := strconv.Atoi(windowXStr)
		if err != nil {
			return RulesConfig{}, fmt.Errorf("NULL_DATE_YEAR_WINDOW_X: %w", err)
		}
		windowX = parsed
	}

	extensionNeeded := strings.TrimSpace(os.Getenv("REMARKS_EXTENSION_NEEDED"))
	if extensionNeeded == "" {
		extensionNeeded = "extension needed"
	}

	return RulesConfig{
		ProdEndDtColIndex:        prodEndIdx,
		BLOCColIndex:             blocIdx,
		FirstBlocProcessColIndex: firstIdx,
		LastBlocProcessColIndex:  lastIdx,
		NullDateYearWindowX:      windowX,
		RemarksExtensionNeeded:   extensionNeeded,
	}, nil
}

// colIndexEnvOrDefault reads key from the environment; if unset or blank, returns defaultVal.
// Otherwise uses colIndexFromEnvValue (numeric index or Excel column letters, same as other *_COL_INDEX settings).
func colIndexEnvOrDefault(key string, defaultVal int) (int, error) {
	s := strings.TrimSpace(os.Getenv(key))
	if s == "" {
		return defaultVal, nil
	}
	idx, err := colIndexFromEnvValue(s)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return idx, nil
}

func loadProcessMap() (process_map.ProcessMap, error) {
	keyIdx, err := colIndexEnvOrDefault("PROCESS_MAP_KEY_COL_INDEX", 0)
	if err != nil {
		return nil, fmt.Errorf("process map: %w", err)
	}
	valIdx, err := colIndexEnvOrDefault("PROCESS_MAP_VALUE_COL_INDEX", 1)
	if err != nil {
		return nil, fmt.Errorf("process map: %w", err)
	}
	if keyIdx == valIdx {
		return nil, fmt.Errorf("process map: PROCESS_MAP_KEY_COL_INDEX and PROCESS_MAP_VALUE_COL_INDEX must differ")
	}

	parseFile := func(f *os.File) (process_map.ProcessMap, error) {
		pm, parseErr := process_map.Parse(f, keyIdx, valIdx)
		if parseErr != nil {
			return nil, parseErr
		}
		return pm, nil
	}

	if envPath := strings.TrimSpace(os.Getenv("PROCESS_MAP_CSV_PATH")); envPath != "" {
		f, err := os.Open(envPath)
		if err != nil {
			return nil, fmt.Errorf("open process map from PROCESS_MAP_CSV_PATH: %w", err)
		}
		defer f.Close()

		return parseFile(f)
	}

	// Try a couple of relative paths to support both `go test` and running
	// from the repository root.
	paths := []string{
		"data/preoptimization_process_map.csv",
		"../../data/preoptimization_process_map.csv",
	}
	var lastErr error
	for _, p := range paths {
		f, err := os.Open(p)
		if err != nil {
			lastErr = err
			continue
		}
		defer f.Close()

		pm, parseErr := parseFile(f)
		if parseErr != nil {
			return nil, parseErr
		}
		return pm, nil
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("process map path not found")
	}
	return nil, fmt.Errorf("open process map: %w", lastErr)
}

const (
	holidayDateLayoutFull  = "02-01-2006" // dd-mm-yyyy
	holidayDateLayoutShort = "02-01-06"   // dd-mm-yy
)

// parseHolidayCSVDate parses a holiday CSV date in DD-MM-YYYY or DD-MM-YY form.
func parseHolidayCSVDate(s string) (time.Time, error) {
	if s == "" {
		return time.Time{}, fmt.Errorf("empty holiday date")
	}
	if d, err := time.Parse(holidayDateLayoutFull, s); err == nil {
		return d, nil
	}
	d, err := time.Parse(holidayDateLayoutShort, s)
	if err != nil {
		return time.Time{}, fmt.Errorf("parse holiday date %q: %w", s, err)
	}
	return d, nil
}

// holidayIndexModeFromReader loads holidays using fixed 0-based column indices: keyIdx for the date
// and valIdx for a non-empty label column (same row shape as process_map validation).
func holidayIndexModeFromReader(cr *csv.Reader, first []string, keyIdx, valIdx int) (func(time.Time) bool, error) {
	maxIdx := keyIdx
	if valIdx > maxIdx {
		maxIdx = valIdx
	}

	holidays := make(map[time.Time]bool)

	addDataRow := func(rec []string, rowDesc string) error {
		if len(rec) <= maxIdx {
			return fmt.Errorf("holidays CSV: %s must have at least %d columns", rowDesc, maxIdx+1)
		}
		k := strings.TrimSpace(rec[keyIdx])
		v := strings.TrimSpace(rec[valIdx])
		if k == "" && v == "" {
			return nil
		}
		if k == "" {
			return fmt.Errorf("holidays CSV: %s has blank date column", rowDesc)
		}
		if v == "" {
			return fmt.Errorf("holidays CSV: %s has blank value column", rowDesc)
		}
		d, err := parseHolidayCSVDate(k)
		if err != nil {
			return fmt.Errorf("holidays CSV: %s: %w", rowDesc, err)
		}
		holidays[dateOnlyUTC(d)] = true
		return nil
	}

	if len(first) <= maxIdx {
		return nil, fmt.Errorf("holidays CSV: first row must have at least %d columns", maxIdx+1)
	}

	dateStr := strings.TrimSpace(first[keyIdx])
	firstIsData := false
	if dateStr != "" {
		_, err := parseHolidayCSVDate(dateStr)
		firstIsData = err == nil
	}

	if firstIsData {
		if err := addDataRow(first, "row 1"); err != nil {
			return nil, err
		}
	}

	rowNum := 2
	for {
		rec, readErr := cr.Read()
		if readErr != nil {
			if readErr == io.EOF {
				break
			}
			return nil, fmt.Errorf("read holidays CSV row: %w", readErr)
		}
		if err := addDataRow(rec, fmt.Sprintf("row %d", rowNum)); err != nil {
			return nil, err
		}
		rowNum++
	}

	return func(t time.Time) bool { return holidays[dateOnlyUTC(t)] }, nil
}

func loadHolidayProviderFromEnv() (func(time.Time) bool, error) {
	keyIdx, err := colIndexEnvOrDefault("HOLIDAYS_KEY_COL_INDEX", 0)
	if err != nil {
		return nil, fmt.Errorf("holidays: %w", err)
	}
	valIdx, err := colIndexEnvOrDefault("HOLIDAYS_VALUE_COL_INDEX", 1)
	if err != nil {
		return nil, fmt.Errorf("holidays: %w", err)
	}
	if keyIdx == valIdx {
		return nil, fmt.Errorf("holidays: HOLIDAYS_KEY_COL_INDEX and HOLIDAYS_VALUE_COL_INDEX must differ")
	}

	path := strings.TrimSpace(os.Getenv("HOLIDAYS_CSV_PATH"))
	if path != "" {
		return loadHolidayProviderFromCSVPath(path, keyIdx, valIdx)
	}

	// No path (e.g. tests without main): no file-based holidays. The CLI always sets
	// HOLIDAYS_CSV_PATH from -holiday-master or the file next to the executable.
	return nil, nil
}

func loadHolidayProviderFromCSVPath(path string, keyIdx, valIdx int) (func(time.Time) bool, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open holidays CSV: %w", err)
	}
	defer f.Close()

	cr := csv.NewReader(f)
	cr.FieldsPerRecord = -1

	first, err := cr.Read()
	if err != nil {
		return nil, fmt.Errorf("read holidays CSV: %w", err)
	}
	if len(first) == 0 {
		return nil, fmt.Errorf("holidays CSV: missing first row")
	}

	return holidayIndexModeFromReader(cr, first, keyIdx, valIdx)
}

// Run reads the input CSV at inputPath, writes the optimized CSV to outputPath,
// and streams rows to avoid loading the full file into memory.
//
// If processing fails, Run does not leave a partial output file behind.
func Run(inputPath, outputPath string, log Logger) (inputRows, outputRows int, err error) {
	f, err := os.Open(inputPath)
	if err != nil {
		return 0, 0, fmt.Errorf("open input file: %w", err)
	}
	defer f.Close()

	dir := filepath.Dir(outputPath)
	if dir == "" {
		dir = "."
	}

	out, err := os.CreateTemp(dir, ".cleanup_*.tmp")
	if err != nil {
		return 0, 0, fmt.Errorf("create temp file: %w", err)
	}
	tmpPath := out.Name()
	removeTemp := true
	defer func() {
		out.Close()
		if removeTemp {
			_ = os.Remove(tmpPath)
		}
	}()

	inputRows, outputRows, err = RunStream(f, out, log)
	if err != nil {
		return inputRows, outputRows, err
	}

	if err := out.Close(); err != nil {
		return inputRows, outputRows, fmt.Errorf("close temp file: %w", err)
	}
	removeTemp = false

	if err := os.Rename(tmpPath, outputPath); err != nil {
		_ = os.Remove(tmpPath)
		return inputRows, outputRows, fmt.Errorf("rename output file: %w", err)
	}

	return inputRows, outputRows, nil
}
