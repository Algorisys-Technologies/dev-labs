// Package logger provides a file-based logger that writes timestamped lines.
package logger

import (
	"os"
	"path/filepath"
	"regexp"
	"testing"
)

// TestNew_createsLogFile writes a line and verifies the file exists with timestamped content.
func TestNew_createsLogFile(t *testing.T) {
	dir := t.TempDir()
	logPath := filepath.Join(dir, LogFileName)

	l, err := New(logPath)
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	defer l.Close()

	l.Log("test message")

	if err := l.Close(); err != nil {
		t.Fatalf("Close: %v", err)
	}

	content, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("read log file: %v", err)
	}
	// Format: 2006-01-02 15:04:05 message
	tsPattern := regexp.MustCompile(`^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} test message\n$`)
	if !tsPattern.Match(content) {
		t.Errorf("log content: got %q, want timestamp + 'test message'", string(content))
	}
}

// TestNew_appendsToExistingFile verifies that a second logger instance appends to the same file.
func TestNew_appendsToExistingFile(t *testing.T) {
	dir := t.TempDir()
	logPath := filepath.Join(dir, LogFileName)

	l1, err := New(logPath)
	if err != nil {
		t.Fatalf("New (first): %v", err)
	}
	l1.Log("first")
	l1.Close()

	l2, err := New(logPath)
	if err != nil {
		t.Fatalf("New (second): %v", err)
	}
	l2.Log("second")
	l2.Close()

	content, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("read log file: %v", err)
	}
	lines := regexp.MustCompile(`\n`).Split(string(content), -1)
	if len(lines) < 2 {
		t.Fatalf("expected at least 2 lines, got %d", len(lines))
	}
	if !regexp.MustCompile(`first`).MatchString(lines[0]) {
		t.Errorf("first line should contain 'first': %q", lines[0])
	}
	if !regexp.MustCompile(`second`).MatchString(lines[1]) {
		t.Errorf("second line should contain 'second': %q", lines[1])
	}
}

// TestNew_createsDirectoryIfMissing verifies that the logger creates parent directories when needed.
func TestNew_createsDirectoryIfMissing(t *testing.T) {
	dir := t.TempDir()
	logPath := filepath.Join(dir, "subdir", "nested", LogFileName)

	l, err := New(logPath)
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	l.Log("created")
	l.Close()

	if _, err := os.Stat(logPath); os.IsNotExist(err) {
		t.Errorf("log file was not created at %s", logPath)
	}
}
