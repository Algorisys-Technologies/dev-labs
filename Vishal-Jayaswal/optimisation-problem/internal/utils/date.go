package utils

import (
	"fmt"
	"time"
)

func ParseDate(value string) (time.Time, error) {
	if IsNull(value) {
		return time.Time{}, fmt.Errorf("empty or NULL date string")
	}

	layouts := []string{
		"1/2/06 15:04",     // m/d/yy hh:mm (e.g. 2/18/26 00:00)
		"1/2/06",           // m/d/yy
		"01/02/06",         // mm/dd/yy (Fallback e.g. 02/09/26)
		"01/02/06 15:04",   // mm/dd/yy hh:mm
		"01-02-06",         // mm-dd-yy
		"02/01/06",         // dd/mm/yy
		"02-01-06",         // dd-mm-yy
		"2006-01-02",       // yyyy-mm-dd
		"2006-01-02 15:04", // yyyy-mm-dd hh:mm
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
