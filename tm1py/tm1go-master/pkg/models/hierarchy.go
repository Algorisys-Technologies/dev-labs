package models

import (
	"encoding/json"
)

// Hierarchy represents a TM1 Hierarchy object
type Hierarchy struct {
	Name              string              `json:"Name"`
	DimensionName     string              `json:"DimensionName,omitempty"`
	Elements          []*Element          `json:"Elements,omitempty"`
	ElementAttributes []*ElementAttribute `json:"ElementAttributes,omitempty"`
	Edges             []*Edge             `json:"Edges,omitempty"`
	Subsets           []*Subset           `json:"Subsets,omitempty"`
	Structure         int                 `json:"Structure,omitempty"`
	DefaultMember     string              `json:"DefaultMember,omitempty"`
}

// Edge represents a parent-child relationship in a TM1 Hierarchy
type Edge struct {
	ParentName    string  `json:"ParentName"`
	ComponentName string  `json:"ComponentName"`
	Weight        float64 `json:"Weight"`
}

// NewHierarchy creates a new Hierarchy instance
func NewHierarchy(name string, dimensionName string) *Hierarchy {
	return &Hierarchy{
		Name:          name,
		DimensionName: dimensionName,
	}
}

// MapToTM1Body converts the Hierarchy object to a TM1-compatible JSON body
func (h *Hierarchy) MapToTM1Body() (string, error) {
	// TM1 uses a specific format for Hierarchy creation/update
	type tm1Hierarchy struct {
		Name              string              `json:"Name"`
		Elements          []*Element          `json:"Elements,omitempty"`
		Edges             []*Edge             `json:"Edges,omitempty"`
		ElementAttributes []*ElementAttribute `json:"ElementAttributes,omitempty"`
	}

	body := tm1Hierarchy{
		Name:              h.Name,
		Elements:          h.Elements,
		Edges:             h.Edges,
		ElementAttributes: h.ElementAttributes,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
