package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// SubsetService handles subset-related operations
type SubsetService struct {
	rest *RestService
}

func NewSubsetService(rest *RestService) *SubsetService {
	return &SubsetService{rest: rest}
}

func (s *SubsetService) Get(subsetName, dimensionName, hierarchyName string, private bool) (*models.Subset, error) {
	if hierarchyName == "" {
		hierarchyName = dimensionName
	}
	subsetType := "Subsets"
	if private {
		subsetType = "PrivateSubsets"
	}

	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/%s('%s')?$expand=Hierarchy($select=Dimension,Name),Elements($select=Name)&$select=*,Alias",
		dimensionName, hierarchyName, subsetType, subsetName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var subset models.Subset
	if err := json.Unmarshal(body, &subset); err != nil {
		return nil, err
	}

	return &subset, nil
}

func (s *SubsetService) Create(subset *models.Subset, private bool) ([]byte, error) {
	subsetType := "Subsets"
	if private {
		subsetType = "PrivateSubsets"
	}
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/%s", subset.DimensionName, subset.HierarchyName, subsetType)
	body, err := subset.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST(url, []byte(body))
}

func (s *SubsetService) Update(subset *models.Subset, private bool) ([]byte, error) {
	subsetType := "Subsets"
	if private {
		subsetType = "PrivateSubsets"
	}
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/%s('%s')", subset.DimensionName, subset.HierarchyName, subsetType, subset.Name)
	body, err := subset.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, []byte(body))
}

func (s *SubsetService) Delete(subsetName, dimensionName, hierarchyName string, private bool) ([]byte, error) {
	if hierarchyName == "" {
		hierarchyName = dimensionName
	}
	subsetType := "Subsets"
	if private {
		subsetType = "PrivateSubsets"
	}
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/%s('%s')", dimensionName, hierarchyName, subsetType, subsetName)
	return s.rest.DELETE(url)
}

func (s *SubsetService) Exists(subsetName, dimensionName, hierarchyName string, private bool) (bool, error) {
	if hierarchyName == "" {
		hierarchyName = dimensionName
	}
	subsetType := "Subsets"
	if private {
		subsetType = "PrivateSubsets"
	}
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/%s('%s')?$select=Name", dimensionName, hierarchyName, subsetType, subsetName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}

func (s *SubsetService) GetAllNames(dimensionName, hierarchyName string, private bool) ([]string, error) {
	if hierarchyName == "" {
		hierarchyName = dimensionName
	}
	subsetType := "Subsets"
	if private {
		subsetType = "PrivateSubsets"
	}
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/%s?$select=Name", dimensionName, hierarchyName, subsetType)
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
