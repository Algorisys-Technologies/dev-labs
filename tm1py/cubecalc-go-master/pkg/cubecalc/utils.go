package cubecalc

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// GenerateDatesFromRows converts row elements into time.Time objects.
// Supports:
// - Standard date strings (e.g., '2024-03-31')
// - Quarter formats (e.g., '2024-Q1', '2024Q1') -> last day of quarter
// - YearMonth formats (e.g., '2024-01', '202401') -> last day of month
func GenerateDatesFromRows(rows []string) ([]time.Time, error) {
	dates := make([]time.Time, 0, len(rows))

	for _, row := range rows {
		element := strings.TrimSpace(row)
		if element == "" {
			return nil, fmt.Errorf("empty date value in row")
		}

		upper := strings.ToUpper(element)

		// Handle Quarter formats: YYYY-Q1, YYYYQ1
		if strings.Contains(upper, "Q") {
			cleaned := strings.NewReplacer("-", "", " ", "").Replace(upper)
			if len(cleaned) >= 6 && cleaned[4] == 'Q' {
				year, err := strconv.Atoi(cleaned[:4])
				if err == nil {
					q, err := strconv.Atoi(cleaned[5:])
					if err == nil && q >= 1 && q <= 4 {
						month := time.Month(q * 3)
						lastDay := LastDayOfMonth(year, month)
						dates = append(dates, time.Date(year, month, lastDay, 0, 0, 0, 0, time.UTC))
						continue
					}
				}
			}
		}

		// Handle YearMonth formats: YYYYMM or YYYY-MM
		digitsOnly := regexp.MustCompile(`\D`).ReplaceAllString(element, "")
		if len(digitsOnly) >= 6 {
			year, _ := strconv.Atoi(digitsOnly[:4])
			month, _ := strconv.Atoi(digitsOnly[4:6])
			if month >= 1 && month <= 12 {
				lastDay := LastDayOfMonth(year, time.Month(month))
				dates = append(dates, time.Date(year, time.Month(month), lastDay, 0, 0, 0, 0, time.UTC))
				continue
			}
		}

		// Fallback: full date parsing
		formats := []string{"2006-01-02", "02-01-2006", "01/02/2006", time.RFC3339, "2006-01-02T15:04:05Z"}
		var parsed bool
		for _, f := range formats {
			t, err := time.Parse(f, element)
			if err == nil {
				dates = append(dates, t)
				parsed = true
				break
			}
		}
		if !parsed {
			// Try dateutil-like flexibility (just year/month/day)
			t, err := time.Parse("2/1/2006", element)
			if err == nil {
				dates = append(dates, t)
				parsed = true
			}
		}

		if !parsed {
			return nil, fmt.Errorf("unrecognized date format: %s", element)
		}
	}

	return dates, nil
}

// LastDayOfMonth returns the last day of a given month and year
func LastDayOfMonth(year int, month time.Month) int {
	return time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
}
