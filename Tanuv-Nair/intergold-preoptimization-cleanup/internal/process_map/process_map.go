// Package process_map parses the process-map CSV used to map a process code to
// the corresponding "process completion date column name".
package process_map

import (
	"encoding/csv"
	"fmt"
	"io"
	"strings"
)

// ProcessMap maps the process code (key column) to one or more values
// (value column). Duplicate keys are preserved in encounter order.
type ProcessMap map[string][]string

// Parse reads a process-map CSV from r.
//
// Behavior:
// - Skips the first row as a header.
// - Uses keyColIdx as the key column and valColIdx as the value column (0-based).
// - Trims whitespace around both key and value.
// - Skips fully empty rows.
// - Returns an error if any non-empty data row has a blank key or blank value.
func Parse(r io.Reader, keyColIdx, valColIdx int) (ProcessMap, error) {
	if keyColIdx < 0 || valColIdx < 0 {
		return nil, fmt.Errorf("process map: column indices must be non-negative")
	}
	if keyColIdx == valColIdx {
		return nil, fmt.Errorf("process map: key and value column indices must differ")
	}
	needCols := keyColIdx + 1
	if valColIdx+1 > needCols {
		needCols = valColIdx + 1
	}

	cr := csv.NewReader(r)
	cr.FieldsPerRecord = -1

	// Skip header row.
	if _, err := cr.Read(); err != nil {
		if err == io.EOF {
			return nil, fmt.Errorf("process map: missing header")
		}
		return nil, fmt.Errorf("process map: read header: %w", err)
	}

	out := make(ProcessMap)
	rowNum := 1 // header row

	for {
		rec, err := cr.Read()
		if err != nil {
			if err == io.EOF {
				break
			}
			return nil, fmt.Errorf("process map: read row %d: %w", rowNum+1, err)
		}
		rowNum++

		if len(rec) == 0 {
			continue
		}

		if len(rec) < needCols {
			return nil, fmt.Errorf("process map: row %d must have at least %d columns", rowNum, needCols)
		}

		key := strings.TrimSpace(rec[keyColIdx])
		val := strings.TrimSpace(rec[valColIdx])

		// Skip completely empty rows.
		if key == "" && val == "" {
			continue
		}

		if key == "" {
			return nil, fmt.Errorf("process map: row %d has blank key", rowNum)
		}
		if val == "" {
			return nil, fmt.Errorf("process map: row %d has blank value", rowNum)
		}

		// Column 1 may contain a comma-separated list of mapped values inside
		// a single CSV field (e.g. "HandSetting, MicroSetting").
		parts := strings.Split(val, ",")
		for i := range parts {
			parts[i] = strings.TrimSpace(parts[i])
			if parts[i] == "" {
				return nil, fmt.Errorf("process map: row %d has blank value item", rowNum)
			}
			out[key] = append(out[key], parts[i])
		}
	}

	return out, nil
}
