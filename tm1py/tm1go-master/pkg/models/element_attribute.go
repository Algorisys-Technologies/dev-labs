package models

// ElementAttribute represents a TM1 Element Attribute object
type ElementAttribute struct {
	Name          string `json:"Name"`
	AttributeType string `json:"Type"` // Numeric, String, Alias
}

// NewElementAttribute creates a new ElementAttribute instance
func NewElementAttribute(name string, attributeType string) *ElementAttribute {
	return &ElementAttribute{
		Name:          name,
		AttributeType: attributeType,
	}
}
