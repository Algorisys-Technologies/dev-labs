package models

type Dimension struct {
	Name        string       `json:"Name"`
	UniqueName  string       `json:"UniqueName,omitempty"`
	Hierarchies []*Hierarchy `json:"Hierarchies"`
}

// NewDimension creates a new Dimension instance
func NewDimension(name string, hierarchies []*Hierarchy) *Dimension {
	return &Dimension{
		Name:        name,
		Hierarchies: hierarchies,
	}
}
