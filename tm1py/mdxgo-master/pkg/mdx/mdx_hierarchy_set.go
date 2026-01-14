package mdx

import (
	"fmt"
	"strings"
)

// MdxHierarchySet represents a set that operates on a specific hierarchy
type MdxHierarchySet struct {
	Dimension string
	Hierarchy string
	mdxFunc   func() string
}

func (s *MdxHierarchySet) ToMdx() string {
	if s.mdxFunc != nil {
		return s.mdxFunc()
	}
	return "{}"
}

// Factory methods (returning specialized sets)

func NewTm1SubsetAllHierarchySet(dimension, hierarchy string) *MdxHierarchySet {
	dim := Normalize(dimension)
	hier := hierarchy
	if hier == "" {
		hier = dimension
	}
	hierNorm := Normalize(hier)

	return &MdxHierarchySet{
		Dimension: dimension,
		Hierarchy: hier,
		mdxFunc: func() string {
			return fmt.Sprintf("TM1SUBSETALL(%s.%s)", dim, hierNorm)
		},
	}
}

func NewAllMembersHierarchySet(dimension, hierarchy string) *MdxHierarchySet {
	dim := Normalize(dimension)
	hier := hierarchy
	if hier == "" {
		hier = dimension
	}
	hierNorm := Normalize(hier)

	return &MdxHierarchySet{
		Dimension: dimension,
		Hierarchy: hier,
		mdxFunc: func() string {
			return fmt.Sprintf("%s.%s.AllMembers", dim, hierNorm)
		},
	}
}

func NewChildrenHierarchySet(member MemberExpression) *MdxHierarchySet {
	return &MdxHierarchySet{
		mdxFunc: func() string {
			return fmt.Sprintf("%s.Children", member.UniqueName())
		},
	}
}

func NewTm1SubsetToSetHierarchySet(dimension, hierarchy, subset string) *MdxHierarchySet {
	dim := Normalize(dimension)
	hier := hierarchy
	if hier == "" {
		hier = dimension
	}
	hierNorm := Normalize(hier)

	return &MdxHierarchySet{
		Dimension: dimension,
		Hierarchy: hier,
		mdxFunc: func() string {
			return fmt.Sprintf("TM1SubsetToSet(%s.%s, '%s')", dim, hierNorm, subset)
		},
	}
}

func NewElementsHierarchySet(members ...MemberExpression) *MdxHierarchySet {
	if len(members) == 0 {
		return &MdxHierarchySet{mdxFunc: func() string { return "{}" }}
	}
	return &MdxHierarchySet{
		mdxFunc: func() string {
			names := make([]string, len(members))
			for i, m := range members {
				names[i] = m.UniqueName()
			}
			return fmt.Sprintf("{%s}", strings.Join(names, ","))
		},
	}
}

func NewDescendantsHierarchySet(member MemberExpression, level int, flag DescFlag) *MdxHierarchySet {
	return &MdxHierarchySet{
		mdxFunc: func() string {
			f := ""
			if flag != 0 {
				f = ", " + flag.String()
			}
			return fmt.Sprintf("DESCENDANTS(%s, %d%s)", member.UniqueName(), level, f)
		},
	}
}

// More specialized sets can be added here...
