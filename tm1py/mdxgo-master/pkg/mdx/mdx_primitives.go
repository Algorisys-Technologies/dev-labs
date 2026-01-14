package mdx

import (
	"fmt"
	"strings"
)

// MemberExpression is the interface for MDX member expressions
type MemberExpression interface {
	UniqueName() string
}

// Member represents a specific element in a hierarchy
type Member struct {
	Dimension string
	Hierarchy string
	Element   string
}

func NewMember(dimension, hierarchy, element string) *Member {
	return &Member{
		Dimension: strings.Trim(dimension, "[]"),
		Hierarchy: strings.Trim(hierarchy, "[]"),
		Element:   strings.Trim(element, "[]"),
	}
}

func (m *Member) UniqueName() string {
	if m.Hierarchy == "" || m.Hierarchy == m.Dimension {
		return fmt.Sprintf("[%s].[%s]", m.Dimension, m.Element)
	}
	return fmt.Sprintf("[%s].[%s].[%s]", m.Dimension, m.Hierarchy, m.Element)
}

// CurrentMember represents the CURRENTMEMBER expression in MDX
type CurrentMember struct {
	Dimension string
	Hierarchy string
}

func NewCurrentMember(dimension, hierarchy string) *CurrentMember {
	return &CurrentMember{
		Dimension: strings.Trim(dimension, "[]"),
		Hierarchy: strings.Trim(hierarchy, "[]"),
	}
}

func (m *CurrentMember) UniqueName() string {
	if m.Hierarchy == "" || m.Hierarchy == m.Dimension {
		return fmt.Sprintf("[%s].CurrentMember", m.Dimension)
	}
	return fmt.Sprintf("[%s].[%s].CurrentMember", m.Dimension, m.Hierarchy)
}

// DimensionProperty represents an attribute or property of a member
type DimensionProperty struct {
	Dimension string
	Hierarchy string
	Attribute string
}

func NewDimensionProperty(dimension, hierarchy, attribute string) *DimensionProperty {
	return &DimensionProperty{
		Dimension: strings.Trim(dimension, "[]"),
		Hierarchy: strings.Trim(hierarchy, "[]"),
		Attribute: strings.Trim(attribute, "[]"),
	}
}

func (p *DimensionProperty) UniqueName() string {
	if p.Hierarchy == "" || p.Hierarchy == p.Dimension {
		return fmt.Sprintf("[%s].[%s]", p.Dimension, p.Attribute)
	}
	return fmt.Sprintf("[%s].[%s].[%s]", p.Dimension, p.Hierarchy, p.Attribute)
}

// CalculatedMember represents a member defined by a calculation
type CalculatedMember struct {
	Dimension   string
	Hierarchy   string
	Element     string
	Calculation string
}

func NewCalculatedMember(dimension, hierarchy, element, calculation string) *CalculatedMember {
	return &CalculatedMember{
		Dimension:   strings.Trim(dimension, "[]"),
		Hierarchy:   strings.Trim(hierarchy, "[]"),
		Element:     strings.Trim(element, "[]"),
		Calculation: calculation,
	}
}

func (m *CalculatedMember) UniqueName() string {
	if m.Hierarchy == "" || m.Hierarchy == m.Dimension {
		return fmt.Sprintf("[%s].[%s]", m.Dimension, m.Element)
	}
	return fmt.Sprintf("[%s].[%s].[%s]", m.Dimension, m.Hierarchy, m.Element)
}

func (m *CalculatedMember) ToMdx() string {
	return fmt.Sprintf("MEMBER %s AS %s", m.UniqueName(), m.Calculation)
}
