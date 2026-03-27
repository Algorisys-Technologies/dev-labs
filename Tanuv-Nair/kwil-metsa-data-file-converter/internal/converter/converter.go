package converter

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Convert reads the txt file at inputPath, applies all transformations,
// and writes the result as CSV to outputPath.
func Convert(inputPath, outputPath string) error {
	raw, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("reading input file: %w", err)
	}

	rows, err := parse(raw)
	if err != nil {
		return err
	}

	rows = transform(rows)

	return writeCSV(outputPath, rows)
}

// parse uses a proper CSV reader so quoted fields are handled correctly.
// It also strips a UTF-8 BOM if present.
func parse(raw []byte) ([][]string, error) {
	// Strip UTF-8 BOM (EF BB BF) if present
	if len(raw) >= 3 && raw[0] == 0xEF && raw[1] == 0xBB && raw[2] == 0xBF {
		raw = raw[3:]
	}

	content := strings.ReplaceAll(string(raw), "\r\n", "\n")
	content = strings.ReplaceAll(content, "\r", "\n")
	content = strings.TrimRight(content, "\n")

	if content == "" {
		return nil, fmt.Errorf("input file is empty")
	}

	reader := csv.NewReader(strings.NewReader(content))
	reader.FieldsPerRecord = -1
	reader.LazyQuotes = true

	rows, err := reader.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("parsing CSV: %w", err)
	}

	if len(rows) < 2 {
		return nil, fmt.Errorf("input file must contain at least 2 rows")
	}

	return rows, nil
}

// transform applies the business rules:
//  1. Remove the column header from Column L (index 11) in Row 1.
//  2. Move ALL month values from Row 2 into Row 1 starting at Column L.
//  3. Delete Row 2.
func transform(rows [][]string) [][]string {
	const colL = 11

	row1 := rows[0]
	row2 := rows[1]

	for len(row1) < colL {
		row1 = append(row1, "")
	}

	row1 = row1[:colL]
	row1 = append(row1, row2...)

	rows[0] = row1

	return append(rows[:1], rows[2:]...)
}

// writeCSV creates the output file and writes rows in CSV format.
// The output directory is created automatically if it does not exist.
func writeCSV(outputPath string, rows [][]string) error {
	if dir := filepath.Dir(outputPath); dir != "." {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return fmt.Errorf("creating output directory: %w", err)
		}
	}

	f, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("creating output file: %w", err)
	}
	defer f.Close()

	w := csv.NewWriter(f)
	for _, row := range rows {
		if err := w.Write(row); err != nil {
			return fmt.Errorf("writing CSV row: %w", err)
		}
	}
	w.Flush()
	return w.Error()
}
