package models

import (
	"encoding/json"
	"fmt"
)

// Subset represents a TM1 Subset object
type Subset struct {
	Name          string   `json:"Name"`
	DimensionName string   `json:"DimensionName"`
	HierarchyName string   `json:"HierarchyName,omitempty"`
	Alias         string   `json:"Alias,omitempty"`
	Expression    string   `json:"Expression,omitempty"`
	Elements      []string `json:"Elements,omitempty"`
}

// NewSubset creates a new Subset instance
func NewSubset(name, dimensionName, hierarchyName string, expression string, elements []string) *Subset {
	if hierarchyName == "" {
		hierarchyName = dimensionName
	}
	return &Subset{
		Name:          name,
		DimensionName: dimensionName,
		HierarchyName: hierarchyName,
		Expression:    expression,
		Elements:      elements,
	}
}

// IsDynamic returns true if the subset has an MDX expression
func (s *Subset) IsDynamic() bool {
	return s.Expression != ""
}

// MapToTM1Body converts the Subset object to a TM1-compatible JSON body
func (s *Subset) MapToTM1Body() (string, error) {
	if s.IsDynamic() {
		return s.mapToTM1BodyDynamic()
	}
	return s.mapToTM1BodyStatic()
}

func (s *Subset) mapToTM1BodyDynamic() (string, error) {
	body := struct {
		Name          string `json:"Name"`
		Alias         string `json:"Alias,omitempty"`
		HierarchyBind string `json:"Hierarchy@odata.bind"`
		Expression    string `json:"Expression"`
	}{
		Name:          s.Name,
		Alias:         s.Alias,
		HierarchyBind: fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')", s.DimensionName, s.HierarchyName),
		Expression:    s.Expression,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func (s *Subset) mapToTM1BodyStatic() (string, error) {
	type tm1StaticSubset struct {
		Name          string   `json:"Name"`
		Alias         string   `json:"Alias,omitempty"`
		HierarchyBind string   `json:"Hierarchy@odata.bind"`
		ElementsBind  []string `json:"Elements@odata.bind,omitempty"`
	}

	binds := make([]string, len(s.Elements))
	for i, elem := range s.Elements {
		binds[i] = fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')/Elements('%s')", s.DimensionName, s.HierarchyName, elem)
	}

	body := tm1StaticSubset{
		Name:          s.Name,
		Alias:         s.Alias,
		HierarchyBind: fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')", s.DimensionName, s.HierarchyName),
		ElementsBind:  binds,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
