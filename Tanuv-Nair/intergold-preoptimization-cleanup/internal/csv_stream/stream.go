// Package csv_stream provides reusable CSV row-by-row streaming so callers
// can process large CSV inputs without loading the entire file into memory.
package csv_stream

import (
	"encoding/csv"
	"errors"
	"io"
)

// utf8BOM is the UTF-8 byte order mark (EF BB BF). Some tools (e.g. Excel on Windows)
// prepend it to CSV files; we strip it so the first header cell is "Product" not "\ufeffProduct".
var utf8BOM = []byte{0xEF, 0xBB, 0xBF}

// bomReader wraps an io.Reader and strips the UTF-8 BOM from the start of the stream if present.
type bomReader struct {
	r    io.Reader
	done bool
	buf  []byte
}

func newBOMReader(r io.Reader) io.Reader {
	return &bomReader{r: r}
}

func (b *bomReader) Read(p []byte) (n int, err error) {
	if !b.done {
		b.done = true
		peek := make([]byte, len(utf8BOM))
		nn, readErr := io.ReadFull(b.r, peek)
		if readErr != nil && readErr != io.ErrUnexpectedEOF {
			return 0, readErr
		}
		hasBOM := nn == len(utf8BOM)
		if hasBOM {
			for i := range utf8BOM {
				if peek[i] != utf8BOM[i] {
					hasBOM = false
					break
				}
			}
		}
		if hasBOM {
			b.buf = nil
		} else {
			b.buf = peek[:nn]
		}
	}
	if len(b.buf) > 0 {
		n = copy(p, b.buf)
		b.buf = b.buf[n:]
		return n, nil
	}
	return b.r.Read(p)
}

// ErrNoRecords is returned when the CSV has no records (e.g. empty input).
var ErrNoRecords = errors.New("csv_stream: no records")

// Reader streams CSV rows from an io.Reader one row at a time.
// Call ReadHeader once to consume the first row, then call Read in a loop until io.EOF.
// If the input starts with the UTF-8 BOM, it is stripped so the first column is parsed correctly.
type Reader struct {
	csv *csv.Reader
}

// NewReader returns a Reader that reads from r.
// The underlying CSV reader allows variable fields per record.
// Input that starts with the UTF-8 byte order mark (BOM) is supported on all platforms.
func NewReader(r io.Reader) *Reader {
	c := csv.NewReader(newBOMReader(r))
	c.FieldsPerRecord = -1
	return &Reader{csv: c}
}

// ReadHeader reads and returns the first row (header).
// Returns ErrNoRecords if the input is empty.
func (r *Reader) ReadHeader() ([]string, error) {
	row, err := r.csv.Read()
	if err != nil {
		if err == io.EOF {
			return nil, ErrNoRecords
		}
		return nil, err
	}
	return row, nil
}

// Read reads the next data row. Returns io.EOF when there are no more rows.
func (r *Reader) Read() ([]string, error) {
	return r.csv.Read()
}

// Writer streams CSV rows to an io.Writer one row at a time.
// Call WriteHeader once, then Write for each data row, then Flush when done.
type Writer struct {
	csv *csv.Writer
}

// NewWriter returns a Writer that writes to w.
func NewWriter(w io.Writer) *Writer {
	return &Writer{csv: csv.NewWriter(w)}
}

// WriteHeader writes the first row (header). Call once before any Write.
func (w *Writer) WriteHeader(header []string) error {
	return w.csv.Write(header)
}

// Write writes one data row.
func (w *Writer) Write(record []string) error {
	return w.csv.Write(record)
}

// Flush writes any buffered data to the underlying io.Writer. Call when done writing.
func (w *Writer) Flush() error {
	w.csv.Flush()
	return w.csv.Error()
}
