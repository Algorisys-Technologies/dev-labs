package utils

import "strings"

// IsNull checks if a string value is empty or represents a "NULL" value.
func IsNull(value string) bool {
	trimmed := strings.TrimSpace(value)
	return trimmed == "" || strings.EqualFold(trimmed, "NULL")
}
