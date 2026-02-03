package models

import (
	"encoding/json"
	"fmt"
)

type ChoreFrequency struct {
	Days    int
	Hours   int
	Minutes int
	Seconds int
}

func (f ChoreFrequency) String() string {
	return fmt.Sprintf("P%02dDT%02dH%02dM%02dS", f.Days, f.Hours, f.Minutes, f.Seconds)
}

func (f ChoreFrequency) MarshalJSON() ([]byte, error) {
	return json.Marshal(f.String())
}

type ChoreStartTime struct {
	Year   int
	Month  int
	Day    int
	Hour   int
	Minute int
	Second int
}

func (s ChoreStartTime) String() string {
	return fmt.Sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", s.Year, s.Month, s.Day, s.Hour, s.Minute, s.Second)
}

func (s ChoreStartTime) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.String())
}

type Chore struct {
	Name          string         `json:"Name"`
	StartTime     ChoreStartTime `json:"StartTime"`
	DSTSensitive  bool           `json:"DSTSensitive"`
	Active        bool           `json:"Active"`
	ExecutionMode string         `json:"ExecutionMode"` // SingleCommit, MultipleCommit
	Frequency     ChoreFrequency `json:"Frequency"`
	Tasks         []*ChoreTask   `json:"Tasks"`
}

// ChoreTask represents a task within a TM1 Chore
type ChoreTask struct {
	Step        int                 `json:"Step"`
	ProcessName string              `json:"-"`
	Parameters  []map[string]string `json:"Parameters"`
}

func (t *ChoreTask) MarshalJSON() ([]byte, error) {
	m := map[string]interface{}{
		"Step":               t.Step,
		"Process@odata.bind": fmt.Sprintf("Processes('%s')", t.ProcessName),
	}
	if t.Parameters != nil {
		m["Parameters"] = t.Parameters
	}
	return json.Marshal(m)
}

// NewChore creates a new Chore instance
func NewChore(name string) *Chore {
	return &Chore{
		Name:          name,
		ExecutionMode: "MultipleCommit",
		Active:        false,
	}
}

// MapToTM1Body converts the Chore object to a TM1-compatible JSON body
func (c *Chore) MapToTM1Body() (string, error) {
	jsonBytes, err := json.Marshal(c)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
