// Package config provides CLI input validation and configuration.
package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestNormalizePath_trimLeadingAndTrailingSpaces(t *testing.T) {
	got := NormalizePath("  /path/to/file.csv  ")
	want := "/path/to/file.csv"
	if got != want {
		t.Errorf("NormalizePath(%q) = %q, want %q", "  /path/to/file.csv  ", got, want)
	}
}

func TestNormalizePath_stripsSurroundingDoubleQuotes(t *testing.T) {
	got := NormalizePath(`"C:\path with spaces\file.csv"`)
	want := `C:\path with spaces\file.csv`
	if got != want {
		t.Errorf("NormalizePath(%q) = %q, want %q", `"C:\path with spaces\file.csv"`, got, want)
	}
}

func TestNormalizePath_stripsSurroundingSingleQuotes(t *testing.T) {
	got := NormalizePath(`'/path with spaces/file.csv'`)
	want := `/path with spaces/file.csv`
	if got != want {
		t.Errorf("NormalizePath(%q) = %q, want %q", `'/path with spaces/file.csv'`, got, want)
	}
}

func TestNormalizePath_trimAndQuotesCombined(t *testing.T) {
	got := NormalizePath(`  "C:\path with spaces\file.csv"  `)
	want := `C:\path with spaces\file.csv`
	if got != want {
		t.Errorf("NormalizePath(%q) = %q, want %q", `  "C:\path with spaces\file.csv"  `, got, want)
	}
}

func TestValidateInputPath_acceptsPathWithSpaceInName(t *testing.T) {
	dir := t.TempDir()
	pathWithSpace := filepath.Join(dir, "my file.csv")
	if err := os.WriteFile(pathWithSpace, []byte("a,b\n"), 0600); err != nil {
		t.Fatalf("create temp file: %v", err)
	}
	if err := ValidateInputPath(pathWithSpace); err != nil {
		t.Errorf("ValidateInputPath(path with space) = %v, want nil", err)
	}
}

func TestExecutableDir_nonEmpty(t *testing.T) {
	dir, err := ExecutableDir()
	if err != nil {
		t.Fatalf("ExecutableDir: %v", err)
	}
	if dir == "" {
		t.Fatal("ExecutableDir: empty path")
	}
	if !filepath.IsAbs(dir) {
		t.Fatalf("ExecutableDir: want absolute path, got %q", dir)
	}
}

func TestValidateInputPath_rejectsNonCSVExtension(t *testing.T) {
	dir := t.TempDir()
	xlsxPath := filepath.Join(dir, "data.xlsx")
	if err := os.WriteFile(xlsxPath, []byte("xlsx content"), 0600); err != nil {
		t.Fatalf("create temp file: %v", err)
	}
	err := ValidateInputPath(xlsxPath)
	if err == nil {
		t.Fatal("ValidateInputPath(.xlsx) expected error, got nil")
	}
	if !strings.Contains(err.Error(), ".csv") || !strings.Contains(err.Error(), ".xlsx") {
		t.Errorf("error should mention CSV and extension; got %q", err.Error())
	}
}
