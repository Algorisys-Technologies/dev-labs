package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// HierarchyService handles hierarchy-related operations
type HierarchyService struct {
	rest *RestService
}

func NewHierarchyService(rest *RestService) *HierarchyService {
	return &HierarchyService{rest: rest}
}

func (s *HierarchyService) Get(dimensionName, hierarchyName string) (*models.Hierarchy, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')?$expand=Edges,Elements,ElementAttributes,Subsets,DefaultMember", dimensionName, hierarchyName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var hierarchy models.Hierarchy
	if err := json.Unmarshal(body, &hierarchy); err != nil {
		return nil, err
	}

	return &hierarchy, nil
}

func (s *HierarchyService) Create(hierarchy *models.Hierarchy) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies", hierarchy.DimensionName)
	body, err := hierarchy.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST(url, []byte(body))
}

func (s *HierarchyService) Update(hierarchy *models.Hierarchy) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')", hierarchy.DimensionName, hierarchy.Name)
	body, err := hierarchy.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, []byte(body))
}

func (s *HierarchyService) Delete(dimensionName, hierarchyName string) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')", dimensionName, hierarchyName)
	return s.rest.DELETE(url)
}

func (s *HierarchyService) Exists(dimensionName, hierarchyName string) (bool, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')?$select=Name", dimensionName, hierarchyName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}

func (s *HierarchyService) GetAllNames(dimensionName string) ([]string, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies?$select=Name", dimensionName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []struct {
			Name string `json:"Name"`
		} `json:"value"`
	}

	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	names := make([]string, len(response.Value))
	for i, v := range response.Value {
		names[i] = v.Name
	}

	return names, nil
}
