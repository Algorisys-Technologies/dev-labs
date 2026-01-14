package models

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestChoreMarshal(t *testing.T) {
	chore := &Chore{
		Name:          "TestChore",
		Active:        true,
		ExecutionMode: "MultipleCommit",
		Frequency:     ChoreFrequency{Days: 1, Hours: 2, Minutes: 3, Seconds: 4},
		StartTime:     ChoreStartTime{Year: 2024, Month: 1, Day: 1, Hour: 12, Minute: 0, Second: 0},
	}

	body, err := chore.MapToTM1Body()
	if err != nil {
		t.Fatalf("Failed to map to body: %v", err)
	}

	// Verify specific fields in JSON
	if !strings.Contains(body, `"Frequency":"P01DT02H03M04S"`) {
		t.Errorf("Frequency not formatted correctly: %s", body)
	}
	if !strings.Contains(body, `"StartTime":"2024-01-01T12:00:00Z"`) {
		t.Errorf("StartTime not formatted correctly: %s", body)
	}

	var raw map[string]interface{}
	if err := json.Unmarshal([]byte(body), &raw); err != nil {
		t.Fatalf("Failed to unmarshal result: %v", err)
	}

	if raw["Name"] != "TestChore" {
		t.Errorf("Name = %v, want TestChore", raw["Name"])
	}
}
