// Package config provides CLI input validation and configuration.
package config

import (
"fmt"
"os"
"path/filepath"
"strings"
)

// NormalizePath trims leading and trailing spaces and removes one layer of
// surrounding double or single quotes. This helps when paths with spaces
// are passed with quotes or extra whitespace (e.g. from Windows shells or scripts).
func NormalizePath(path string) string {
	s := strings.TrimSpace(path)
	if len(s) >= 2 {
		if (s[0] == '"' && s[len(s)-1] == '"') || (s[0] == '\'' && s[len(s)-1] == '\'') {
return s[1 : len(s)-1]
}
}
return s
}

// ValidateInputPath checks that path exists and is a readable .txt file.
func ValidateInputPath(path string) error {
info, err := os.Stat(path)
if err != nil {
if os.IsNotExist(err) {
return fmt.Errorf("input file not found: %s", path)
}
return fmt.Errorf("input path: %w", err)
}
if info.IsDir() {
return fmt.Errorf("input path is a directory, not a file: %s", path)
}
if strings.ToLower(filepath.Ext(path)) != ".txt" {
return fmt.Errorf("input must be a TXT file (.txt), got %s", filepath.Ext(path))
}
return nil
}
