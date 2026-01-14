package models

import (
	"fmt"
)

type ApplicationType struct {
	Value     int
	Suffix    string
	ODataType string
}

var (
	AppTypeChore     = ApplicationType{1, ".chore", "tm1.ChoreReference"}
	AppTypeCube      = ApplicationType{2, ".cube", "tm1.CubeReference"}
	AppTypeDimension = ApplicationType{3, ".dimension", "tm1.DimensionReference"}
	AppTypeDocument  = ApplicationType{4, ".blob", "#ibm.tm1.api.v1.Document"}
	AppTypeFolder    = ApplicationType{5, "", "#ibm.tm1.api.v1.Folder"}
	AppTypeLink      = ApplicationType{6, ".extr", "#ibm.tm1.api.v1.Link"}
	AppTypeProcess   = ApplicationType{7, ".process", "tm1.ProcessReference"}
	AppTypeSubset    = ApplicationType{8, ".subset", "tm1.SubsetReference"}
	AppTypeView      = ApplicationType{9, ".view", "tm1.ViewReference"}
)

type ApplicationInterface interface {
	MapToTM1Body() map[string]interface{}
}

type Application struct {
	Path            string          `json:"-"`
	Name            string          `json:"Name"`
	ApplicationType ApplicationType `json:"-"`
}

func (a *Application) MapToTM1Body() map[string]interface{} {
	body := make(map[string]interface{})
	body["@odata.type"] = a.ApplicationType.ODataType
	body["Name"] = a.Name
	return body
}

type ChoreApplication struct {
	Application
	ChoreName string `json:"-"`
}

func (a *ChoreApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["Chore@odata.bind"] = fmt.Sprintf("Chores('%s')", a.ChoreName)
	return body
}

type CubeApplication struct {
	Application
	CubeName string `json:"-"`
}

func (a *CubeApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["Cube@odata.bind"] = fmt.Sprintf("Cubes('%s')", a.CubeName)
	return body
}

type DimensionApplication struct {
	Application
	DimensionName string `json:"-"`
}

func (a *DimensionApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["Dimension@odata.bind"] = fmt.Sprintf("Dimensions('%s')", a.DimensionName)
	return body
}

type DocumentApplication struct {
	Application
	Content     []byte `json:"-"`
	FileID      string `json:"ID,omitempty"`
	FileName    string `json:"Name,omitempty"`
	LastUpdated string `json:"LastUpdated,omitempty"`
}

type LinkApplication struct {
	Application
	URL string `json:"URL"`
}

func (a *LinkApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["URL"] = a.URL
	return body
}

type ProcessApplication struct {
	Application
	ProcessName string `json:"-"`
}

func (a *ProcessApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["Process@odata.bind"] = fmt.Sprintf("Processes('%s')", a.ProcessName)
	return body
}

type SubsetApplication struct {
	Application
	DimensionName string `json:"-"`
	HierarchyName string `json:"-"`
	SubsetName    string `json:"-"`
}

func (a *SubsetApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["Subset@odata.bind"] = fmt.Sprintf("Dimensions('%s')/Hierarchies('%s')/Subsets('%s')", a.DimensionName, a.HierarchyName, a.SubsetName)
	return body
}

type ViewApplication struct {
	Application
	CubeName string `json:"-"`
	ViewName string `json:"-"`
}

func (a *ViewApplication) MapToTM1Body() map[string]interface{} {
	body := a.Application.MapToTM1Body()
	body["View@odata.bind"] = fmt.Sprintf("Cubes('%s')/Views('%s')", a.CubeName, a.ViewName)
	return body
}
