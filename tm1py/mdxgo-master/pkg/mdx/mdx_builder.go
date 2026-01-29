package mdx

import (
	"fmt"
	"strings"
)

// MdxAxis represents an axis in an MDX query
type MdxAxis struct {
	Tuples   []*MdxTuple
	Sets     []MdxSet
	NonEmpty bool
}

func NewMdxAxis() *MdxAxis {
	return &MdxAxis{}
}

func (a *MdxAxis) ToMdx() string {
	var mdxSets []string
	for _, s := range a.Sets {
		mdxSets = append(mdxSets, s.ToMdx())
	}
	for _, t := range a.Tuples {
		mdxSets = append(mdxSets, t.ToMdx())
	}

	res := ""
	if len(mdxSets) == 0 {
		res = "{}"
	} else if len(mdxSets) == 1 {
		res = mdxSets[0]
	} else {
		// Crossjoin all sets and tuples on this axis
		res = mdxSets[0]
		for i := 1; i < len(mdxSets); i++ {
			res = fmt.Sprintf("CROSSJOIN(%s, %s)", res, mdxSets[i])
		}
	}

	if a.NonEmpty {
		res = "NON EMPTY " + res
	}
	return res
}

// MdxBuilder represents the main MDX query builder
type MdxBuilder struct {
	Cube              string
	Axes              map[int]*MdxAxis
	Where             *MdxTuple
	CalculatedMembers []*CalculatedMember
}

func NewMdxBuilder(cube string) *MdxBuilder {
	return &MdxBuilder{
		Cube:  strings.Trim(cube, "[]"),
		Axes:  make(map[int]*MdxAxis),
		Where: NewMdxTuple(),
	}
}

func (b *MdxBuilder) AddSetToAxis(axis int, set MdxSet) *MdxBuilder {
	if _, ok := b.Axes[axis]; !ok {
		b.Axes[axis] = NewMdxAxis()
	}
	b.Axes[axis].Sets = append(b.Axes[axis].Sets, set)
	return b
}

func (b *MdxBuilder) AddMemberToWhere(member MemberExpression) *MdxBuilder {
	b.Where.Members = append(b.Where.Members, member)
	return b
}

func (b *MdxBuilder) WithMember(member *CalculatedMember) *MdxBuilder {
	b.CalculatedMembers = append(b.CalculatedMembers, member)
	return b
}

func (b *MdxBuilder) SetNonEmpty(axis int, nonEmpty bool) *MdxBuilder {
	if _, ok := b.Axes[axis]; !ok {
		b.Axes[axis] = NewMdxAxis()
	}
	b.Axes[axis].NonEmpty = nonEmpty
	return b
}

func (b *MdxBuilder) ToMdx() string {
	var sb strings.Builder

	// WITH clause for calculated members
	if len(b.CalculatedMembers) > 0 {
		sb.WriteString("WITH ")
		for _, m := range b.CalculatedMembers {
			sb.WriteString(m.ToMdx())
			sb.WriteString(" ")
		}
	}

	sb.WriteString("SELECT ")

	// Axes
	axisCount := len(b.Axes)
	for i := 0; i < axisCount; i++ {
		if axis, ok := b.Axes[i]; ok {
			sb.WriteString(axis.ToMdx())
			sb.WriteString(fmt.Sprintf(" ON %d", i))
			if i < axisCount-1 {
				sb.WriteString(", ")
			}
		}
	}

	sb.WriteString(fmt.Sprintf(" FROM [%s]", b.Cube))

	// WHERE clause
	if len(b.Where.Members) > 0 {
		sb.WriteString(" WHERE ")
		sb.WriteString(b.Where.ToMdx())
	}

	return sb.String()
}
