package main

import (
	"fmt"
	"mdxgo-master/pkg/mdx"
)

func main() {
	// 1. Initialize the builder for a specific cube
	builder := mdx.NewMdxBuilder("Sales")

	// 2. Define rows using a hierarchy set with filters and sorting
	rows := mdx.NewTm1SubsetAllHierarchySet("Region", "").
		FilterByAttribute("Type", []string{"Country"}, "=").
		Tm1Sort(true).
		Head(10)

	// 3. Define columns using specific elements
	cols := mdx.NewElementsHierarchySet(
		mdx.NewMember("Year", "", "2024"),
		mdx.NewMember("Year", "", "2025"),
	)

	// 4. Add axes to the builder
	builder.AddSetToAxis(1, rows). // Rows typically on axis 1
					AddSetToAxis(0, cols). // Columns typically on axis 0
					SetNonEmpty(1, true)   // Set NON EMPTY for rows

	// 5. Add a context (WHERE clause)
	builder.AddMemberToWhere(mdx.NewMember("Scenario", "", "Actual"))

	// 6. Generate the MDX string
	query := builder.ToMdx()

	fmt.Println("Generated MDX Query:")
	fmt.Println("--------------------")
	fmt.Println(query)
}
