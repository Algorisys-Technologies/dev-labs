package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// DimensionService handles dimension-related operations
type DimensionService struct {
	rest *RestService
}

func NewDimensionService(rest *RestService) *DimensionService {
	return &DimensionService{rest: rest}
}

func (s *DimensionService) Create(dimension *models.Dimension) ([]byte, error) {
	// Simple create, doesn't handle hierarchical expansion or attribute creation yet
	body, err := json.Marshal(dimension)
	if err != nil {
		return nil, err
	}
	return s.rest.POST("/Dimensions", body)
}

func (s *DimensionService) Get(dimensionName string) (*models.Dimension, error) {
	url := fmt.Sprintf("/Dimensions('%s')?$expand=Hierarchies($expand=*)", dimensionName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var dim models.Dimension
	if err := json.Unmarshal(body, &dim); err != nil {
		return nil, err
	}

	return &dim, nil
}

func (s *DimensionService) GetAllNames(skipControlDims bool) ([]string, error) {
	url := "/Dimensions?$select=Name"
	if skipControlDims {
		url = "/ModelDimensions()?$select=Name"
	}

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

func (s *DimensionService) Delete(dimensionName string) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')", dimensionName)
	return s.rest.DELETE(url)
}

func (s *DimensionService) Exists(dimensionName string) (bool, error) {
	url := fmt.Sprintf("/Dimensions('%s')?$select=Name", dimensionName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}
