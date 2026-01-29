package mdx

import (
	"fmt"
	"strings"
)

// CrossJoinMdxSet represents a CROSSJOIN of multiple sets
type CrossJoinMdxSet struct {
	Sets []MdxSet
}

func NewCrossJoinMdxSet(sets ...MdxSet) *CrossJoinMdxSet {
	return &CrossJoinMdxSet{Sets: sets}
}

func (s *CrossJoinMdxSet) ToMdx() string {
	if len(s.Sets) == 0 {
		return "{}"
	}
	if len(s.Sets) == 1 {
		return s.Sets[0].ToMdx()
	}
	res := s.Sets[0].ToMdx()
	for i := 1; i < len(s.Sets); i++ {
		res = fmt.Sprintf("CROSSJOIN(%s, %s)", res, s.Sets[i].ToMdx())
	}
	return res
}

// TuplesSet represents a set consisting of specific tuples
type TuplesSet struct {
	Tuples []*MdxTuple
}

func NewTuplesSet(tuples ...*MdxTuple) *TuplesSet {
	return &TuplesSet{Tuples: tuples}
}

func (s *TuplesSet) ToMdx() string {
	if len(s.Tuples) == 0 {
		return "{}"
	}
	names := make([]string, len(s.Tuples))
	for i, t := range s.Tuples {
		names[i] = t.ToMdx()
	}
	return fmt.Sprintf("{%s}", strings.Join(names, ","))
}

// MultiUnionSet represents a union of multiple sets
type MultiUnionSet struct {
	Sets            []MdxSet
	AllowDuplicates bool
}

func NewMultiUnionSet(allowDuplicates bool, sets ...MdxSet) *MultiUnionSet {
	return &MultiUnionSet{Sets: sets, AllowDuplicates: allowDuplicates}
}

func (s *MultiUnionSet) ToMdx() string {
	if len(s.Sets) == 0 {
		return "{}"
	}
	if len(s.Sets) == 1 {
		return s.Sets[0].ToMdx()
	}

	funcName := "UNION"
	allFlag := ""
	if s.AllowDuplicates {
		allFlag = ", ALL"
	}

	res := s.Sets[0].ToMdx()
	for i := 1; i < len(s.Sets); i++ {
		res = fmt.Sprintf("%s(%s, %s%s)", funcName, res, s.Sets[i].ToMdx(), allFlag)
	}
	return res
}
