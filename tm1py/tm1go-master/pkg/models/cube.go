package models

import (
	"encoding/json"
	"fmt"
)

// Cube represents a TM1 Cube object
type Cube struct {
	Name       string   `json:"Name"`
	Dimensions []string `json:"Dimensions"`
	Rules      string   `json:"Rules,omitempty"`
}

// NewCube creates a new Cube instance
func NewCube(name string, dimensions []string, rules string) *Cube {
	return &Cube{
		Name:       name,
		Dimensions: dimensions,
		Rules:      rules,
	}
}

// MapToTM1Body converts the Cube object to a TM1-compatible JSON body
func (c *Cube) MapToTM1Body() (string, error) {
	type tm1Cube struct {
		Name               string   `json:"Name"`
		DimensionsBind     []string `json:"Dimensions@odata.bind"`
		Rules              string   `json:"Rules,omitempty"`
	}

	binds := make([]string, len(c.Dimensions))
	for i, dim := range c.Dimensions {
		binds[i] = fmt.Sprintf("Dimensions('%s')", dim)
	}

	body := tm1Cube{
		Name:           c.Name,
		DimensionsBind: binds,
		Rules:          c.Rules,
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
