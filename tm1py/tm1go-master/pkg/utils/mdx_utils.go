package utils

import (
	"fmt"
	"strings"
)

type SelectionType int

const (
	SelectionSubset SelectionType = iota
	SelectionExpression
	SelectionIterable
)

type DimensionSelection struct {
	DimensionName string
	Elements      []string
	Subset        string
	Expression    string
	SelectionType SelectionType
}

func NewDimensionSelection(dimensionName string, elements []string, subset string, expression string) *DimensionSelection {
	ds := &DimensionSelection{
		DimensionName: dimensionName,
		Elements:      elements,
		Subset:        subset,
		Expression:    expression,
	}

	if elements != nil {
		ds.SelectionType = SelectionIterable
		ds.Expression = CurlyBraces(fmt.Sprintf("[%s].[%s]", dimensionName, strings.Join(elements, "],[%s].[%s]")))
		// Need to fix the above formatting logic for multiple elements
		var parts []string
		for _, e := range elements {
			parts = append(parts, fmt.Sprintf("[%s].[%s]", dimensionName, e))
		}
		ds.Expression = CurlyBraces(strings.Join(parts, ","))
	} else if subset != "" {
		ds.SelectionType = SelectionSubset
		ds.Expression = CurlyBraces(fmt.Sprintf("Tm1SubsetToSet([%s], '%s')", dimensionName, subset))
	} else if expression != "" {
		ds.SelectionType = SelectionExpression
		ds.Expression = CurlyBraces(expression)
	} else {
		ds.Expression = CurlyBraces(fmt.Sprintf("TM1SubsetAll([%s])", dimensionName))
	}

	return ds
}

func CurlyBraces(expression string) string {
	if expression == "" {
		return "{}"
	}
	res := expression
	if !strings.HasPrefix(res, "{") {
		res = "{" + res
	}
	if !strings.HasSuffix(res, "}") {
		res = res + "}"
	}
	return res
}

func ConstructMdxAxis(dimSelections []*DimensionSelection) string {
	var expressions []string
	for _, ds := range dimSelections {
		expressions = append(expressions, ds.Expression)
	}
	return strings.Join(expressions, "*")
}

func ConstructMdx(cubeName string, rows []*DimensionSelection, columns []*DimensionSelection, contexts map[string]string, suppress string) string {
	mdxTemplate := "SELECT %s%s ON ROWS, %s%s ON COLUMNS FROM [%s] %s"

	mdxRowsSuppress := ""
	if strings.ToUpper(suppress) == "ROWS" || strings.ToUpper(suppress) == "BOTH" {
		mdxRowsSuppress = "NON EMPTY "
	}

	mdxColumnsSuppress := ""
	if strings.ToUpper(suppress) == "COLUMNS" || strings.ToUpper(suppress) == "BOTH" {
		mdxColumnsSuppress = "NON EMPTY "
	}

	mdxRows := ConstructMdxAxis(rows)
	mdxColumns := ConstructMdxAxis(columns)

	mdxWhere := ""
	if len(contexts) > 0 {
		var whereParts []string
		for dim, elem := range contexts {
			whereParts = append(whereParts, fmt.Sprintf("[%s].[%s]", dim, elem))
		}
		mdxWhere = "WHERE (" + strings.Join(whereParts, ",") + ")"
	}

	return fmt.Sprintf(mdxTemplate, mdxRowsSuppress, mdxRows, mdxColumnsSuppress, mdxColumns, cubeName, mdxWhere)
}
