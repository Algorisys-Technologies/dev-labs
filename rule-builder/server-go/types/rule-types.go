package types

// Operator type (string enum equivalent)
type Operator string

const (
	OperatorGreaterThan Operator = ">"
	OperatorLessThan    Operator = "<"
	OperatorEqual       Operator = "="
	OperatorNotEqual    Operator = "!="
	OperatorContains    Operator = "contains"
)

// Condition struct
type Condition struct {
	Field    string      `json:"field"`
	Operator Operator    `json:"operator"`
	Value    interface{} `json:"value"`
}

// RuleGroup struct
type RuleGroup struct {
	ID         string      `json:"id"`
	Type       string      `json:"type"` // AND, OR, NOT, XOR
	Conditions []Condition `json:"conditions"`
	Groups     []RuleGroup `json:"groups"`
}

// ReturnValueSpec struct
type ReturnValueSpec struct {
	Type  string      `json:"type"`  // constant, object, property, expression
	Value interface{} `json:"value"` // can hold any type
}

// Rule struct
type Rule struct {
	ID           string           `json:"id"`
	Name         string           `json:"name"`
	Groups       []RuleGroup      `json:"groups"`
	SuccessValue *ReturnValueSpec `json:"successValue,omitempty"`
	FailureValue *ReturnValueSpec `json:"failureValue,omitempty"`
}
