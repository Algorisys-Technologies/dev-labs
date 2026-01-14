package models

type Sandbox struct {
	Name                      string `json:"Name"`
	IncludeInSandboxDimension bool   `json:"IncludeInSandboxDimension"`
	IsLoaded                  bool   `json:"IsLoaded,omitempty"`
	IsActive                  bool   `json:"IsActive,omitempty"`
	IsQueued                  bool   `json:"IsQueued,omitempty"`
}

func (s *Sandbox) MapToTM1Body() map[string]interface{} {
	return map[string]interface{}{
		"Name":                      s.Name,
		"IncludeInSandboxDimension": s.IncludeInSandboxDimension,
	}
}
