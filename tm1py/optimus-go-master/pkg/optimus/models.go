package optimus

import (
	"strings"
)

// ExecutionMode represents the stage of the optimization process
type ExecutionMode int

const (
	OriginalOrder ExecutionMode = iota
	Iterations
	Result
)

func (e ExecutionMode) String() string {
	switch e {
	case OriginalOrder:
		return "Original Order"
	case Iterations:
		return "Iterations"
	case Result:
		return "Result"
	default:
		return "Unknown"
	}
}

// ParseExecutionMode converts a string to an ExecutionMode
func ParseExecutionMode(val string) ExecutionMode {
	switch strings.ToLower(val) {
	case "original_order", "original order":
		return OriginalOrder
	case "iterations":
		return Iterations
	case "result":
		return Result
	default:
		return OriginalOrder
	}
}

// PermutationResult tracks the results of a single dimension order permutation
type PermutationResult struct {
	Mode                  ExecutionMode
	CubeName              string
	ViewNames             []string
	ProcessName           string
	DimensionOrder        []string
	QueryTimesByView      map[string][]float64
	ProcessTimesByProcess map[string][]float64
	RamUsage              float64
	RamPercentageChange   float64
	ResetCounter          bool
}

func NewPermutationResult(mode ExecutionMode, cubeName string, viewNames []string, processName string, dimensionOrder []string) *PermutationResult {
	return &PermutationResult{
		Mode:                  mode,
		CubeName:              cubeName,
		ViewNames:             viewNames,
		ProcessName:           processName,
		DimensionOrder:        dimensionOrder,
		QueryTimesByView:      make(map[string][]float64),
		ProcessTimesByProcess: make(map[string][]float64),
	}
}

// OptimusResult aggregates all permutation results for a cube
type OptimusResult struct {
	CubeName           string
	PermutationResults []*PermutationResult
}

func NewOptimusResult(cubeName string) *OptimusResult {
	return &OptimusResult{
		CubeName:           cubeName,
		PermutationResults: make([]*PermutationResult, 0),
	}
}
