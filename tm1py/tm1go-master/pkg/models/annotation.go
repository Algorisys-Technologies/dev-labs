package models

import (
	"fmt"
	"strings"
)

type DimensionalContextItem struct {
	Name string `json:"Name"`
}

type Annotation struct {
	ID                 string                   `json:"ID,omitempty"`
	Text               string                   `json:"Text,omitempty"`
	Creator            string                   `json:"Creator,omitempty"`
	Created            string                   `json:"Created,omitempty"`
	LastUpdatedBy      string                   `json:"LastUpdatedBy,omitempty"`
	LastUpdated        string                   `json:"LastUpdated,omitempty"`
	DimensionalContext []DimensionalContextItem `json:"DimensionalContext,omitempty"`
	CommentLocation    string                   `json:"commentLocation,omitempty"`
	CommentType        string                   `json:"commentType,omitempty"`
	CommentValue       string                   `json:"commentValue,omitempty"`
	ObjectName         string                   `json:"objectName,omitempty"`
}

func (a *Annotation) MapToTM1Body() map[string]interface{} {
	body := make(map[string]interface{})
	if a.ID != "" {
		body["ID"] = a.ID
	}
	body["Text"] = a.Text
	body["Creator"] = a.Creator
	body["Created"] = a.Created
	body["LastUpdatedBy"] = a.LastUpdatedBy
	body["LastUpdated"] = a.LastUpdated
	body["DimensionalContext"] = a.DimensionalContext
	body["commentLocation"] = a.CommentLocation
	body["commentType"] = a.CommentType
	body["commentValue"] = a.CommentValue
	body["objectName"] = a.ObjectName
	return body
}

func (a *Annotation) ConstructBodyForPost(cubeDimensions []string) map[string]interface{} {
	body := make(map[string]interface{})
	body["Text"] = a.Text
	body["ApplicationContext"] = []map[string]interface{}{
		{
			"Facet@odata.bind": "ApplicationContextFacets('}Cubes')",
			"Value":            a.ObjectName,
		},
	}

	coordinateBinds := make([]string, 0)
	elements := make([]string, 0)
	for i, dim := range cubeDimensions {
		if i < len(a.DimensionalContext) {
			element := a.DimensionalContext[i].Name
			elements = append(elements, element)
			bind := fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')/Members('%s')", dim, dim, element)
			coordinateBinds = append(coordinateBinds, bind)
		}
	}

	body["DimensionalContext@odata.bind"] = coordinateBinds
	body["objectName"] = a.ObjectName
	body["commentValue"] = a.CommentValue
	body["commentType"] = "ANNOTATION"
	body["commentLocation"] = strings.Join(elements, ",")

	return body
}
