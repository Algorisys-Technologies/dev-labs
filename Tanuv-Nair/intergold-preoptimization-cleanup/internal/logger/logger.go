// Package logger provides a file-based logger that writes timestamped lines.
package logger

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// LogFileName is the default name of the log file.
const LogFileName = "intergold-preoptimization-cleanup.log"

const timeFormat = "2006-01-02 15:04:05"

// Logger writes timestamped log lines to a file.
type Logger struct {
	file *os.File
}

// New creates or appends to the log file at logPath. Parent directories are created if missing.
func New(logPath string) (*Logger, error) {
	dir := filepath.Dir(logPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("create log directory: %w", err)
	}
	f, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return nil, fmt.Errorf("open log file: %w", err)
	}
	return &Logger{file: f}, nil
}

// Log writes a single line with timestamp and message.
func (l *Logger) Log(msg string) {
	ts := time.Now().Format(timeFormat)
	line := ts + " " + msg + "\n"
	_, _ = l.file.WriteString(line)
}

// Close flushes and closes the log file.
func (l *Logger) Close() error {
	if l.file == nil {
		return nil
	}
	err := l.file.Close()
	l.file = nil
	return err
}
