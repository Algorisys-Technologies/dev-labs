package models

import (
	"encoding/json"
)

// Process represents a TM1 Process object
type Process struct {
	Name              string              `json:"Name"`
	HasSecurityAccess bool                `json:"HasSecurityAccess"`
	PrologProcedure   string              `json:"PrologProcedure"`
	MetadataProcedure string              `json:"MetadataProcedure"`
	DataProcedure     string              `json:"DataProcedure"`
	EpilogProcedure   string              `json:"EpilogProcedure"`
	DataSource        ProcessDataSource   `json:"DataSource"`
	Parameters        []*ProcessParameter `json:"Parameters"`
	Variables         []*ProcessVariable  `json:"Variables"`
	UIData            string              `json:"UIData,omitempty"`
	VariablesUIData   []string            `json:"VariablesUIData,omitempty"`
}

// ProcessDataSource represents the data source of a TM1 Process
type ProcessDataSource struct {
	Type                    string `json:"Type"` // None, ASCII, ODBC, TM1CubeView, TM1DimensionSubset, JSON
	ASCIIDecimalSeparator   string `json:"asciiDecimalSeparator,omitempty"`
	ASCIIDelimiterChar      string `json:"asciiDelimiterChar,omitempty"`
	ASCIIDelimiterType      string `json:"asciiDelimiterType,omitempty"`
	ASCIIHeaderRecords      int    `json:"asciiHeaderRecords,omitempty"`
	ASCIIQuoteCharacter     string `json:"asciiQuoteCharacter,omitempty"`
	ASCIIThousandSeparator  string `json:"asciiThousandSeparator,omitempty"`
	DataSourceNameForClient string `json:"dataSourceNameForClient,omitempty"`
	DataSourceNameForServer string `json:"dataSourceNameForServer,omitempty"`
	UserName                string `json:"userName,omitempty"`
	Password                string `json:"password,omitempty"`
	Query                   string `json:"query,omitempty"`
	UsesUnicode             bool   `json:"usesUnicode,omitempty"`
	View                    string `json:"view,omitempty"`
	Subset                  string `json:"subset,omitempty"`
}

// ProcessParameter represents a parameter of a TM1 Process
type ProcessParameter struct {
	Name   string      `json:"Name"`
	Prompt string      `json:"Prompt"`
	Value  interface{} `json:"Value"`
	Type   string      `json:"Type"` // String, Numeric
}

// ProcessVariable represents a variable of a TM1 Process
type ProcessVariable struct {
	Name      string `json:"Name"`
	Type      string `json:"Type"` // String, Numeric
	Position  int    `json:"Position"`
	StartByte int    `json:"StartByte,omitempty"`
	EndByte   int    `json:"EndByte,omitempty"`
}

// NewProcess creates a new Process instance
func NewProcess(name string) *Process {
	return &Process{
		Name: name,
		DataSource: ProcessDataSource{
			Type: "None",
		},
	}
}

// MapToTM1Body converts the Process object to a TM1-compatible JSON body
func (p *Process) MapToTM1Body() (string, error) {
	jsonBytes, err := json.Marshal(p)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
