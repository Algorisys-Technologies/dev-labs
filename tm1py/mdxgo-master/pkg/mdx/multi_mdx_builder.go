package mdx

// MultiMdxBuilder generates multiple MDX queries by varying one axis
type MultiMdxBuilder struct {
	*MdxBuilder
	MultiDimension string
	MultiHierarchy string
	MultiSubsets   []string
	MultiAxis      int
}

func NewMultiMdxBuilder(cube, dimension, hierarchy string, subsets []string, axis int) *MultiMdxBuilder {
	return &MultiMdxBuilder{
		MdxBuilder:     NewMdxBuilder(cube),
		MultiDimension: dimension,
		MultiHierarchy: hierarchy,
		MultiSubsets:   subsets,
		MultiAxis:      axis,
	}
}

func (b *MultiMdxBuilder) ToMdxStrings() []string {
	var results []string
	for _, subset := range b.MultiSubsets {
		// Temporary set the varied axis
		originalAxis := b.Axes[b.MultiAxis]

		// Create a new set for the subset
		subsetSet := NewTm1SubsetToSetHierarchySet(b.MultiDimension, b.MultiHierarchy, subset)

		// If axis exists, we should technically crossjoin or replace.
		// Python's MultiMdxBuilder logic replaces or adds to the axis.
		// Let's create a temporary builder or modify state carefully.

		// For simplicity, we'll just swap the axis content temporarily
		tempAxis := NewMdxAxis()
		if originalAxis != nil {
			tempAxis.NonEmpty = originalAxis.NonEmpty
			tempAxis.Sets = append(tempAxis.Sets, originalAxis.Sets...)
			tempAxis.Tuples = append(tempAxis.Tuples, originalAxis.Tuples...)
		}
		tempAxis.Sets = append(tempAxis.Sets, subsetSet)

		b.Axes[b.MultiAxis] = tempAxis
		results = append(results, b.ToMdx())

		// Restore
		b.Axes[b.MultiAxis] = originalAxis
	}
	return results
}
