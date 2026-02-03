package optimus

import (
	"math/rand"
	"time"

	"tm1go/pkg/services"
)

// Executor interface for dimension order optimization
type Executor interface {
	Execute() (*OptimusResult, error)
}

// OptipyzerExecutor evaluates a specific dimension order
type OptipyzerExecutor struct {
	tm1                         *services.TM1Service
	cubeName                    string
	viewNames                   []string
	processName                 string
	displayedDimensionOrder     []string
	executions                  int
	measureDimensionOnlyNumeric bool
}

func NewOptipyzerExecutor(tm1 *services.TM1Service, cubeName string, viewNames []string, processName string, displayedDimensionOrder []string, executions int, measureDimensionOnlyNumeric bool) *OptipyzerExecutor {
	return &OptipyzerExecutor{
		tm1:                         tm1,
		cubeName:                    cubeName,
		viewNames:                   viewNames,
		processName:                 processName,
		displayedDimensionOrder:     displayedDimensionOrder,
		executions:                  executions,
		measureDimensionOnlyNumeric: measureDimensionOnlyNumeric,
	}
}

func (e *OptipyzerExecutor) EvaluatePermutation(permutation []string, retrieveRam bool) (*PermutationResult, error) {
	// 1. Reorder cube dimensions
	err := e.tm1.Cubes.UpdateStorageDimensionOrder(e.cubeName, permutation)
	if err != nil {
		return nil, err
	}

	result := NewPermutationResult(Iterations, e.cubeName, e.viewNames, e.processName, permutation)

	// 2. Execute Views/Processes multiple times to get median
	for i := 0; i < e.executions; i++ {
		// Clear cache before each execution to get accurate cold-start times
		e.ClearCubeCache()

		for _, viewName := range e.viewNames {
			start := time.Now()
			_, err := e.tm1.Cells.ExecuteView(e.cubeName, viewName, true)
			if err != nil {
				return nil, err
			}
			elapsed := time.Since(start).Seconds()
			result.QueryTimesByView[viewName] = append(result.QueryTimesByView[viewName], elapsed)
		}

		if e.processName != "" {
			start := time.Now()
			// Assuming a simple process execution for now
			_, err := e.tm1.Processes.Execute(e.processName, nil)
			if err != nil {
				return nil, err
			}
			elapsed := time.Since(start).Seconds()
			result.ProcessTimesByProcess[e.processName] = append(result.ProcessTimesByProcess[e.processName], elapsed)
		}
	}

	if retrieveRam {
		// Simplified RAM retrieval
		result.RamUsage = 1.0 // Placeholder
	}

	return result, nil
}

func (e *OptipyzerExecutor) ClearCubeCache() {
	// TM1 utility to clear cube cache by re-writing a property or similar
	// Usually involves CubeLoadUp or dummy data write
}

// OriginalOrderExecutor establishes the baseline
type OriginalOrderExecutor struct {
	*OptipyzerExecutor
	originalDimensionOrder []string
}

func NewOriginalOrderExecutor(tm1 *services.TM1Service, cubeName string, viewNames []string, processName string, dimensions []string, executions int, measureDimensionOnlyNumeric bool, originalOrder []string) *OriginalOrderExecutor {
	return &OriginalOrderExecutor{
		OptipyzerExecutor:      NewOptipyzerExecutor(tm1, cubeName, viewNames, processName, dimensions, executions, measureDimensionOnlyNumeric),
		originalDimensionOrder: originalOrder,
	}
}

func (e *OriginalOrderExecutor) Execute() (*PermutationResult, error) {
	return e.EvaluatePermutation(e.originalDimensionOrder, true)
}

// MainExecutor orchestrates the optimization search
type MainExecutor struct {
	tm1                         *services.TM1Service
	cubeName                    string
	viewNames                   []string
	processName                 string
	dimensions                  []string
	executions                  int
	measureDimensionOnlyNumeric bool
	fast                        bool
	dimensionsToExclude         []string
}

func NewMainExecutor(tm1 *services.TM1Service, cubeName string, viewNames []string, processName string, dimensions []string, executions int, measureDimensionOnlyNumeric bool, fast bool, dimensionsToExclude []string) *MainExecutor {
	return &MainExecutor{
		tm1:                         tm1,
		cubeName:                    cubeName,
		viewNames:                   viewNames,
		processName:                 processName,
		dimensions:                  dimensions,
		executions:                  executions,
		measureDimensionOnlyNumeric: measureDimensionOnlyNumeric,
		fast:                        fast,
		dimensionsToExclude:         dimensionsToExclude,
	}
}

func (e *MainExecutor) Execute() (*OptimusResult, error) {
	result := NewOptimusResult(e.cubeName)

	// 1. Get baseline
	originalExecutor := NewOriginalOrderExecutor(e.tm1, e.cubeName, e.viewNames, e.processName, e.dimensions, e.executions, e.measureDimensionOnlyNumeric, e.dimensions)
	baseline, err := originalExecutor.Execute()
	if err != nil {
		return nil, err
	}
	result.PermutationResults = append(result.PermutationResults, baseline)

	// 2. Search logic (Random swaps for now as a placeholder for the full search)
	currentOrder := make([]string, len(e.dimensions))
	copy(currentOrder, e.dimensions)

	for i := 0; i < 5; i++ { // Limit to 5 iterations for demo
		newOrder := e.SwapRandom(currentOrder)
		evaluator := NewOptipyzerExecutor(e.tm1, e.cubeName, e.viewNames, e.processName, e.dimensions, e.executions, e.measureDimensionOnlyNumeric)
		res, err := evaluator.EvaluatePermutation(newOrder, false)
		if err != nil {
			return nil, err
		}
		result.PermutationResults = append(result.PermutationResults, res)
		currentOrder = newOrder
	}

	return result, nil
}

func (e *MainExecutor) SwapRandom(order []string) []string {
	newOrder := make([]string, len(order))
	copy(newOrder, order)
	i1 := rand.Intn(len(order))
	i2 := rand.Intn(len(order))
	newOrder[i1], newOrder[i2] = newOrder[i2], newOrder[i1]
	return newOrder
}
