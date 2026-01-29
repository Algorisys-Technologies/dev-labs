package mdx

import (
	"fmt"
	"strings"
)

// Order represents MDX ORDER flags
type Order int

const (
	ASC Order = iota + 1
	DESC
	BASC
	BDESC
)

func (o Order) String() string {
	switch o {
	case ASC:
		return "ASC"
	case DESC:
		return "DESC"
	case BASC:
		return "BASC"
	case BDESC:
		return "BDESC"
	default:
		return ""
	}
}

// DescFlag represents MDX DESCENDANTS flags
type DescFlag int

const (
	SELF DescFlag = iota + 1
	AFTER
	BEFORE
	BEFORE_AND_AFTER
	SELF_AND_AFTER
	SELF_AND_BEFORE
	SELF_BEFORE_AFTER
	LEAVES
)

func (d DescFlag) String() string {
	switch d {
	case SELF:
		return "SELF"
	case AFTER:
		return "AFTER"
	case BEFORE:
		return "BEFORE"
	case BEFORE_AND_AFTER:
		return "BEFORE_AND_AFTER"
	case SELF_AND_AFTER:
		return "SELF_AND_AFTER"
	case SELF_AND_BEFORE:
		return "SELF_AND_BEFORE"
	case SELF_BEFORE_AFTER:
		return "SELF_BEFORE_AFTER"
	case LEAVES:
		return "LEAVES"
	default:
		return ""
	}
}

// ElementType represents TM1 element types
type ElementType int

const (
	NUMERIC ElementType = iota + 1
	STRING
	CONSOLIDATED
)

func (e ElementType) String() string {
	switch e {
	case NUMERIC:
		return "Numeric"
	case STRING:
		return "String"
	case CONSOLIDATED:
		return "Consolidated"
	default:
		return ""
	}
}

// Normalize ensures TM1 object names are properly escaped with brackets
func Normalize(name string) string {
	if name == "" {
		return ""
	}
	if strings.HasPrefix(name, "[") && strings.HasSuffix(name, "]") {
		return name
	}
	return fmt.Sprintf("[%s]", name)
}

// FormatUniqueName constructs a unique name from dimension, hierarchy, and element
func FormatUniqueName(dimension, hierarchy, element string) string {
	if hierarchy == "" || hierarchy == dimension {
		return fmt.Sprintf("[%s].[%s]", dimension, element)
	}
	return fmt.Sprintf("[%s].[%s].[%s]", dimension, hierarchy, element)
}
