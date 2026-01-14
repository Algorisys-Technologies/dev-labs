package mdx

import (
	"fmt"
	"strings"
)

// MdxSet is the interface for all MDX sets
type MdxSet interface {
	ToMdx() string
}

// MdxTuple represents a tuple of members in MDX
type MdxTuple struct {
	Members []MemberExpression
}

func NewMdxTuple(members ...MemberExpression) *MdxTuple {
	return &MdxTuple{Members: members}
}

func (t *MdxTuple) UniqueName() string {
	return t.ToMdx()
}

func (t *MdxTuple) ToMdx() string {
	if len(t.Members) == 0 {
		return "()"
	}
	if len(t.Members) == 1 {
		return t.Members[0].UniqueName()
	}
	names := make([]string, len(t.Members))
	for i, m := range t.Members {
		names[i] = m.UniqueName()
	}
	return fmt.Sprintf("(%s)", strings.Join(names, ","))
}

// MdxPropertiesTuple represents a tuple of dimension properties
type MdxPropertiesTuple struct {
	Properties []*DimensionProperty
}

func NewMdxPropertiesTuple(properties ...*DimensionProperty) *MdxPropertiesTuple {
	return &MdxPropertiesTuple{Properties: properties}
}

func (t *MdxPropertiesTuple) ToMdx() string {
	if len(t.Properties) == 0 {
		return "()"
	}
	if len(t.Properties) == 1 {
		return t.Properties[0].UniqueName()
	}
	names := make([]string, len(t.Properties))
	for i, p := range t.Properties {
		names[i] = p.UniqueName()
	}
	return fmt.Sprintf("(%s)", strings.Join(names, ","))
}
