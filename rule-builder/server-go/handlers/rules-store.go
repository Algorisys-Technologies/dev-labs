package handlers

import (
	"fmt"
	"strings"

	"server-go/types"

	"github.com/expr-lang/expr"
)

// Global store
var Rules []types.Rule

// --- Utility: Evaluate single condition ---
func EvaluateCondition(cond types.Condition, input map[string]interface{}) bool {
	left, leftOk := input[cond.Field]
	right := cond.Value

	if !leftOk {
		return false
	}

	switch cond.Operator {
	case types.OperatorGreaterThan:
		return CompareNumbers(left, right, ">")
	case types.OperatorLessThan:
		return CompareNumbers(left, right, "<")
	case types.OperatorEqual:
		return fmt.Sprintf("%v", left) == fmt.Sprintf("%v", right)
	case types.OperatorNotEqual:
		return fmt.Sprintf("%v", left) != fmt.Sprintf("%v", right)
	case types.OperatorContains:
		return strings.Contains(fmt.Sprintf("%v", left), fmt.Sprintf("%v", right))
	default:
		return false
	}
}

// Helper: Compare numbers safely
func CompareNumbers(a interface{}, b interface{}, op string) bool {
	af, aok := ToFloat(a)
	bf, bok := ToFloat(b)
	if !aok || !bok {
		return false
	}

	switch op {
	case ">":
		return af > bf
	case "<":
		return af < bf
	default:
		return false
	}
}

// Convert to float64 for numeric comparison
func ToFloat(val interface{}) (float64, bool) {
	switch v := val.(type) {
	case int:
		return float64(v), true
	case int32:
		return float64(v), true
	case int64:
		return float64(v), true
	case float32:
		return float64(v), true
	case float64:
		return v, true
	default:
		return 0, false
	}
}

// --- Recursive group evaluation ---
func EvaluateGroup(group types.RuleGroup, input map[string]interface{}) bool {
	condResults := []bool{}
	for _, c := range group.Conditions {
		condResults = append(condResults, EvaluateCondition(c, input))
	}

	groupResults := []bool{}
	for _, g := range group.Groups {
		groupResults = append(groupResults, EvaluateGroup(g, input))
	}

	results := append(condResults, groupResults...)

	switch group.Type {
	case "AND":
		for _, r := range results {
			if !r {
				return false
			}
		}
		return true
	case "OR":
		for _, r := range results {
			if r {
				return true
			}
		}
		return false
	case "NOT":
		if len(results) == 1 {
			return !results[0]
		}
		return false
	case "XOR":
		count := 0
		for _, r := range results {
			if r {
				count++
			}
		}
		return count == 1
	default:
		return false
	}
}

// Evaluate return spec
func EvaluateReturnSpec(spec *types.ReturnValueSpec, input map[string]interface{}) interface{} {
	switch spec.Type {
	case "constant":
		return spec.Value
	case "object":
		return spec.Value // assuming it's already a map or struct
	case "property":
		if val, ok := input[fmt.Sprintf("%v", spec.Value)]; ok {
			return val
		}
		return nil
	case "expression":
		// Use expr-lang for safe evaluation
		program, err := expr.Compile(fmt.Sprintf("%v", spec.Value), expr.Env(input))
		if err != nil {
			fmt.Println("Expression compile error:", err)
			return nil
		}

		output, err := expr.Run(program, input)
		if err != nil {
			fmt.Println("Expression run error:", err)
			return nil
		}
		return output
	default:
		return nil
	}
}

// --- Evaluate rule ---
func EvaluateRule(rule types.Rule, input map[string]interface{}) interface{} {
	if len(rule.Groups) == 0 {
		return nil
	}

	boolResult := EvaluateGroup(rule.Groups[0], input)
	if boolResult {
		if rule.SuccessValue != nil {
			return EvaluateReturnSpec(rule.SuccessValue, input)
		}
		return true
	} else {
		if rule.FailureValue != nil {
			return EvaluateReturnSpec(rule.FailureValue, input)
		}
		return false
	}
}

// --- Rule store ---
type RuleStore struct{}

func (rs RuleStore) Save(rule types.Rule) types.Rule {
	for _, r := range Rules {
		if r.ID == rule.ID {
			return rule
		}
	}
	Rules = append(Rules, rule)
	return rule
}

func (rs RuleStore) List() []types.Rule {
	return Rules
}

func (rs RuleStore) Get(id string) *types.Rule {
	for _, r := range Rules {
		if r.ID == id {
			return &r
		}
	}
	return nil
}
