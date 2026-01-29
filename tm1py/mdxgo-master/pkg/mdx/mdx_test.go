package mdx

import (
	"strings"
	"testing"
)

func TestMemberUniqueName(t *testing.T) {
	m := NewMember("Dim1", "Hier1", "Elem1")
	if got := m.UniqueName(); got != "[Dim1].[Hier1].[Elem1]" {
		t.Errorf("UniqueName() = %v, want [Dim1].[Hier1].[Elem1]", got)
	}

	m2 := NewMember("Dim1", "Dim1", "Elem1")
	if got := m2.UniqueName(); got != "[Dim1].[Elem1]" {
		t.Errorf("UniqueName() = %v, want [Dim1].[Elem1]", got)
	}
}

func TestMdxHierarchySetFunctions(t *testing.T) {
	s := NewTm1SubsetAllHierarchySet("Region", "")
	s2 := s.FilterByAttribute("Type", []string{"Country"}, "=").Tm1Sort(true)

	got := s2.ToMdx()
	if !strings.Contains(got, "FILTER(TM1SUBSETALL([Region].[Region])") {
		t.Errorf("ToMdx() format wrong: %v", got)
	}
	if !strings.Contains(got, "TM1SORT") {
		t.Errorf("ToMdx() should contain TM1SORT: %v", got)
	}
}

func TestMdxBuilder(t *testing.T) {
	b := NewMdxBuilder("Sales")
	rows := NewTm1SubsetAllHierarchySet("Region", "")
	cols := NewElementsHierarchySet(NewMember("Year", "", "2024"))

	b.AddSetToAxis(1, rows)
	b.AddSetToAxis(0, cols)
	b.SetNonEmpty(1, true)

	got := b.ToMdx()
	expected := "SELECT {[Year].[2024]} ON 0, NON EMPTY TM1SUBSETALL([Region].[Region]) ON 1 FROM [Sales]"

	if got != expected {
		t.Errorf("ToMdx() = %v, want %v", got, expected)
	}
}

func TestCalculatedMember(t *testing.T) {
	cm := NewCalculatedMember("Measures", "", "Variance", "[Measures].[Actual] - [Measures].[Budget]")
	b := NewMdxBuilder("Sales")
	b.WithMember(cm)
	b.AddSetToAxis(0, NewElementsHierarchySet(cm))

	got := b.ToMdx()
	if !strings.Contains(got, "WITH MEMBER [Measures].[Variance] AS [Measures].[Actual] - [Measures].[Budget]") {
		t.Errorf("Calculated member not in query: %v", got)
	}
}
