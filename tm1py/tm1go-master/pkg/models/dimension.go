package models

type Dimension struct {
	Name        string      `json:"Name"`
	Hierarchies []Hierarchy `json:"Hierarchies"`
}

type Hierarchy struct {
	Name          string    `json:"Name"`
	DimensionName string    `json:"DimensionName"`
	Elements      []Element `json:"Elements,omitempty"`
}

type Element struct {
	Name string `json:"Name"`
	Type string `json:"Type"` // Numeric, String, Consolidated
}
