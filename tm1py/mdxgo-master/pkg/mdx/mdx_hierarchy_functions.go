package mdx

import (
	"fmt"
	"strings"
)

// Chaining methods for MdxHierarchySet

func (s *MdxHierarchySet) FilterByAttribute(attributeName string, values []string, operator string) *MdxHierarchySet {
	if operator == "" {
		operator = "="
	}
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			hier := s.Hierarchy
			if hier == "" {
				hier = s.Dimension
			}
			var conditions []string
			for _, v := range values {
				conditions = append(conditions, fmt.Sprintf("%s.%s.CurrentMember.[%s] %s '%s'", Normalize(s.Dimension), Normalize(hier), attributeName, operator, v))
			}
			return fmt.Sprintf("FILTER(%s, %s)", s.ToMdx(), strings.Join(conditions, " OR "))
		},
	}
}

func (s *MdxHierarchySet) Tm1Sort(ascending bool) *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			order := "ASC"
			if !ascending {
				order = "DESC"
			}
			return fmt.Sprintf("TM1SORT(%s, %s)", s.ToMdx(), order)
		},
	}
}

func (s *MdxHierarchySet) Head(count int) *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			return fmt.Sprintf("HEAD(%s, %d)", s.ToMdx(), count)
		},
	}
}

func (s *MdxHierarchySet) Tail(count int) *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			return fmt.Sprintf("TAIL(%s, %d)", s.ToMdx(), count)
		},
	}
}

func (s *MdxHierarchySet) Union(other *MdxHierarchySet, allowDuplicates bool) *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			allFlag := ""
			if allowDuplicates {
				allFlag = ", ALL"
			}
			return fmt.Sprintf("UNION(%s, %s%s)", s.ToMdx(), other.ToMdx(), allFlag)
		},
	}
}

func (s *MdxHierarchySet) Intersect(other *MdxHierarchySet) *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			return fmt.Sprintf("INTERSECT(%s, %s)", s.ToMdx(), other.ToMdx())
		},
	}
}

func (s *MdxHierarchySet) Except(other *MdxHierarchySet) *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			return fmt.Sprintf("EXCEPT(%s, %s)", s.ToMdx(), other.ToMdx())
		},
	}
}

func (s *MdxHierarchySet) Hierarchize() *MdxHierarchySet {
	return &MdxHierarchySet{
		Dimension: s.Dimension,
		Hierarchy: s.Hierarchy,
		mdxFunc: func() string {
			return fmt.Sprintf("HIERARCHIZE(%s)", s.ToMdx())
		},
	}
}
