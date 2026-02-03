package models

type BreakpointType string

const (
	BreakpointData BreakpointType = "ProcessDebugContextDataBreakpoint"
	BreakpointLine BreakpointType = "ProcessDebugContextLineBreakpoint"
	BreakpointLock BreakpointType = "ProcessDebugContextLockBreakpoint"
)

type HitMode string

const (
	HitAlways         HitMode = "BreakAlways"
	HitEqual          HitMode = "BreakEqual"
	HitGreaterOrEqual HitMode = "BreakGreaterOrEqual"
)

type ProcessDebugBreakpoint struct {
	ID           int            `json:"ID"`
	Type         BreakpointType `json:"@odata.type"`
	Enabled      bool           `json:"Enabled"`
	HitMode      HitMode        `json:"HitMode"`
	HitCount     int            `json:"HitCount"`
	Expression   string         `json:"Expression"`
	VariableName string         `json:"VariableName,omitempty"` // For Data Breakpoint
	ProcessName  string         `json:"ProcessName,omitempty"`  // For Line Breakpoint
	Procedure    string         `json:"Procedure,omitempty"`    // For Line Breakpoint
	LineNumber   int            `json:"LineNumber,omitempty"`   // For Line Breakpoint
	ObjectName   string         `json:"ObjectName,omitempty"`   // For Lock Breakpoint
	ObjectType   string         `json:"ObjectType,omitempty"`   // For Lock Breakpoint
	LockMode     string         `json:"LockMode,omitempty"`     // For Lock Breakpoint
}
