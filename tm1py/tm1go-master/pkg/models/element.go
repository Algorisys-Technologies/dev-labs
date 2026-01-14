package models

import (
	"encoding/json"
)

// Element represents a TM1 Element object
type Element struct {
	Name       string   `json:"Name"`
	Type       string   `json:"Type"` // Numeric, String, Consolidated
	UniqueName string   `json:"UniqueName,omitempty"`
	Index      int      `json:"Index,omitempty"`
	Attributes []string `json:"Attributes,omitempty"`
}

// NewElement creates a new Element instance
func NewElement(name string, elementType string) *Element {
	return &Element{
		Name: name,
		Type: elementType,
	}
}

// MapToTM1Body converts the Element object to a TM1-compatible JSON body
func (e *Element) MapToTM1Body() (string, error) {
	body := struct {
		Name string `json:"Name"`
		Type string `json:"Type"`
	}{
		Name: e.Name,
		Type: e.Type,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
