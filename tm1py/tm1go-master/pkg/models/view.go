package models

import (
	"encoding/json"
	"fmt"
)

// View is a base interface for TM1 Views
type View interface {
	GetCube() string
	GetName() string
	MapToTM1Body() (string, error)
}

// MDXView represents a TM1 MDX View object
type MDXView struct {
	CubeName string `json:"CubeName"`
	Name     string `json:"Name"`
	MDX      string `json:"MDX"`
}

func (v *MDXView) GetCube() string { return v.CubeName }
func (v *MDXView) GetName() string { return v.Name }

// MapToTM1Body converts the MDXView object to a TM1-compatible JSON body
func (v *MDXView) MapToTM1Body() (string, error) {
	body := struct {
		Type string `json:"@odata.type"`
		Name string `json:"Name"`
		MDX  string `json:"MDX"`
	}{
		Type: "ibm.tm1.api.v1.MDXView",
		Name: v.Name,
		MDX:  v.MDX,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// NativeView represents a TM1 Native View object
type NativeView struct {
	CubeName             string                `json:"CubeName"`
	Name                 string                `json:"Name"`
	SuppressEmptyColumns bool                  `json:"SuppressEmptyColumns"`
	SuppressEmptyRows    bool                  `json:"SuppressEmptyRows"`
	FormatString         string                `json:"FormatString"`
	Titles               []*ViewTitleSelection `json:"Titles"`
	Columns              []*ViewAxisSelection  `json:"Columns"`
	Rows                 []*ViewAxisSelection  `json:"Rows"`
}

func (v *NativeView) GetCube() string { return v.CubeName }
func (v *NativeView) GetName() string { return v.Name }

// MapToTM1Body converts the NativeView object to a TM1-compatible JSON body
func (v *NativeView) MapToTM1Body() (string, error) {
	body := struct {
		Type                 string                `json:"@odata.type"`
		Name                 string                `json:"Name"`
		SuppressEmptyColumns bool                  `json:"SuppressEmptyColumns"`
		SuppressEmptyRows    bool                  `json:"SuppressEmptyRows"`
		FormatString         string                `json:"FormatString"`
		Titles               []*ViewTitleSelection `json:"Titles"`
		Columns              []*ViewAxisSelection  `json:"Columns"`
		Rows                 []*ViewAxisSelection  `json:"Rows"`
	}{
		Type:                 "ibm.tm1.api.v1.NativeView",
		Name:                 v.Name,
		SuppressEmptyColumns: v.SuppressEmptyColumns,
		SuppressEmptyRows:    v.SuppressEmptyRows,
		FormatString:         v.FormatString,
		Titles:               v.Titles,
		Columns:              v.Columns,
		Rows:                 v.Rows,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ViewAxisSelection describes what is selected in a dimension on an axis
type ViewAxisSelection struct {
	DimensionName string  `json:"-"`
	HierarchyName string  `json:"-"`
	Subset        *Subset `json:"Subset,omitempty"`
}

func (v *ViewAxisSelection) MarshalJSON() ([]byte, error) {
	hierarchyName := v.HierarchyName
	if hierarchyName == "" {
		hierarchyName = v.DimensionName
	}
	if v.Subset != nil && v.Subset.Name != "" {
		return json.Marshal(map[string]string{
			"Subset@odata.bind": fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')/Subsets('%s')", v.DimensionName, hierarchyName, v.Subset.Name),
		})
	}
	return json.Marshal(map[string]interface{}{
		"Subset": v.Subset,
	})
}

// ViewTitleSelection describes what is selected in a dimension on the view title
type ViewTitleSelection struct {
	DimensionName string  `json:"-"`
	HierarchyName string  `json:"-"`
	Subset        *Subset `json:"Subset,omitempty"`
	Selected      string  `json:"-"`
}

func (v *ViewTitleSelection) MarshalJSON() ([]byte, error) {
	hierarchyName := v.HierarchyName
	if hierarchyName == "" {
		hierarchyName = v.DimensionName
	}
	m := make(map[string]interface{})
	if v.Subset != nil && v.Subset.Name != "" {
		m["Subset@odata.bind"] = fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')/Subsets('%s')", v.DimensionName, hierarchyName, v.Subset.Name)
	} else {
		m["Subset"] = v.Subset
	}
	m["Selected@odata.bind"] = fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')/Elements('%s')", v.DimensionName, hierarchyName, v.Selected)
	return json.Marshal(m)
}
