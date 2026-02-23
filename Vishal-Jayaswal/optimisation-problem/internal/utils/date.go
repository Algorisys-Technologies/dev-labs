package utils

import (
	"fmt"
	"strings"
	"time"
)

func ParseDate(value string) (time.Time, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return time.Time{}, fmt.Errorf("empty date string")
	}

	layouts := []string{
		"02-01-06",   // dd-mm-yy
		"02-01-2006", // dd-mm-yyyy
		"02/01/06",   // dd/mm/yy
		"02/01/2006", // dd/mm/yyyy
		"2006-01-02", // yyyy-mm-dd
		"01-02-06",   // mm-dd-yy
		"01-02-2006", // mm-dd-yyyy
		time.RFC3339,
	}

	var lastErr error
	for _, layout := range layouts {
		t, err := time.Parse(layout, value)
		if err == nil {
			return t, nil
		}
		lastErr = err
	}

	return time.Time{}, fmt.Errorf("invalid date format '%s': %w", value, lastErr)
}
