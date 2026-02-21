package utils

import (
	"fmt"
	"strings"
	"time"
)

func ParseDate(value string) (time.Time, error) {
	layout := "02/01/2006"

	t, err := time.Parse(layout, strings.TrimSpace(value))
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid date format '%s': %w", value, err)
	}

	return t, nil
}
