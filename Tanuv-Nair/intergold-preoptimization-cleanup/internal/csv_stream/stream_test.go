// Package csv_stream provides reusable CSV row-by-row streaming.
package csv_stream

import (
	"bytes"
	"io"
	"strings"
	"testing"
)

func TestReader_ReadHeader_returnsFirstRow(t *testing.T) {
	input := "A,B,C\n1,2,3\n4,5,6"
	r := NewReader(strings.NewReader(input))
	header, err := r.ReadHeader()
	if err != nil {
		t.Fatalf("ReadHeader: %v", err)
	}
	want := []string{"A", "B", "C"}
	if len(header) != 3 || header[0] != want[0] || header[1] != want[1] || header[2] != want[2] {
		t.Errorf("header: got %v, want %v", header, want)
	}
}

// utf8BOMString is the UTF-8 BOM as a string; prepended by some tools (e.g. Excel) to CSV files.
const utf8BOMString = "\ufeff"

func TestReader_ReadHeader_stripsUTF8BOMFromFirstField(t *testing.T) {
	input := utf8BOMString + "Product,Alias,UDA\nval1,val2,val3"
	r := NewReader(strings.NewReader(input))
	header, err := r.ReadHeader()
	if err != nil {
		t.Fatalf("ReadHeader: %v", err)
	}
	if header[0] != "Product" {
		t.Errorf("first header field with BOM: got %q, want Product", header[0])
	}
	if len(header) != 3 || header[1] != "Alias" || header[2] != "UDA" {
		t.Errorf("header: got %v", header)
	}
	row, err := r.Read()
	if err != nil {
		t.Fatalf("Read: %v", err)
	}
	if len(row) != 3 || row[0] != "val1" || row[1] != "val2" || row[2] != "val3" {
		t.Errorf("first row: got %v", row)
	}
}

func TestReader_Read_returnsRowsUntilEOF(t *testing.T) {
	input := "A,B\n1,2\n3,4"
	r := NewReader(strings.NewReader(input))
	if _, err := r.ReadHeader(); err != nil {
		t.Fatalf("ReadHeader: %v", err)
	}
	row1, err := r.Read()
	if err != nil {
		t.Fatalf("Read first row: %v", err)
	}
	if len(row1) != 2 || row1[0] != "1" || row1[1] != "2" {
		t.Errorf("row 1: got %v, want [1 2]", row1)
	}
	row2, err := r.Read()
	if err != nil {
		t.Fatalf("Read second row: %v", err)
	}
	if len(row2) != 2 || row2[0] != "3" || row2[1] != "4" {
		t.Errorf("row 2: got %v, want [3 4]", row2)
	}
	_, err = r.Read()
	if err != io.EOF {
		t.Errorf("expected io.EOF after last row, got %v", err)
	}
}

func TestReader_ReadHeader_returnsErrorOnEmptyInput(t *testing.T) {
	r := NewReader(strings.NewReader(""))
	_, err := r.ReadHeader()
	if err == nil {
		t.Error("expected error for empty input, got nil")
	}
	if err != ErrNoRecords {
		t.Errorf("expected ErrNoRecords, got %v", err)
	}
}

func TestReader_ReadHeader_allowsVariableFieldsPerRecord(t *testing.T) {
	input := "a,b\n1,2,3\n4,5"
	r := NewReader(strings.NewReader(input))
	header, err := r.ReadHeader()
	if err != nil {
		t.Fatalf("ReadHeader: %v", err)
	}
	if len(header) != 2 {
		t.Errorf("header: got %v", header)
	}
	row1, err := r.Read()
	if err != nil {
		t.Fatalf("Read: %v", err)
	}
	if len(row1) != 3 || row1[2] != "3" {
		t.Errorf("row 1 (variable fields): got %v", row1)
	}
	row2, err := r.Read()
	if err != nil {
		t.Fatalf("Read: %v", err)
	}
	if len(row2) != 2 {
		t.Errorf("row 2: got %v", row2)
	}
}

func TestWriter_WriteHeader_and_Write_produceValidCSV(t *testing.T) {
	var buf bytes.Buffer
	w := NewWriter(&buf)
	header := []string{"A", "B", "C"}
	if err := w.WriteHeader(header); err != nil {
		t.Fatalf("WriteHeader: %v", err)
	}
	if err := w.Write([]string{"1", "2", "3"}); err != nil {
		t.Fatalf("Write row 1: %v", err)
	}
	if err := w.Write([]string{"4", "5", "6"}); err != nil {
		t.Fatalf("Write row 2: %v", err)
	}
	if err := w.Flush(); err != nil {
		t.Fatalf("Flush: %v", err)
	}
	got := buf.String()
	want := "A,B,C\n1,2,3\n4,5,6\n"
	if got != want {
		t.Errorf("output: got %q, want %q", got, want)
	}
}

func TestWriter_writtenCSV_isReadableByReader(t *testing.T) {
	var buf bytes.Buffer
	w := NewWriter(&buf)
	_ = w.WriteHeader([]string{"X", "Y"})
	_ = w.Write([]string{"a", "b"})
	_ = w.Write([]string{"c", "d"})
	_ = w.Flush()

	r := NewReader(bytes.NewReader(buf.Bytes()))
	h, err := r.ReadHeader()
	if err != nil {
		t.Fatalf("ReadHeader: %v", err)
	}
	if len(h) != 2 || h[0] != "X" || h[1] != "Y" {
		t.Errorf("header: got %v", h)
	}
	row1, _ := r.Read()
	if len(row1) != 2 || row1[0] != "a" || row1[1] != "b" {
		t.Errorf("row1: got %v", row1)
	}
	row2, _ := r.Read()
	if len(row2) != 2 || row2[0] != "c" || row2[1] != "d" {
		t.Errorf("row2: got %v", row2)
	}
}
