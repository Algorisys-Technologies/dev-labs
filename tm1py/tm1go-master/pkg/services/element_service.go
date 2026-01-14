package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// ElementService handles element-related operations
type ElementService struct {
	rest *RestService
}

func NewElementService(rest *RestService) *ElementService {
	return &ElementService{rest: rest}
}

func (s *ElementService) Get(dimensionName, hierarchyName, elementName string) (*models.Element, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/Elements('%s')?$expand=*", dimensionName, hierarchyName, elementName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var element models.Element
	if err := json.Unmarshal(body, &element); err != nil {
		return nil, err
	}

	return &element, nil
}

func (s *ElementService) Create(dimensionName, hierarchyName string, element *models.Element) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/Elements", dimensionName, hierarchyName)
	body, err := element.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST(url, []byte(body))
}

func (s *ElementService) Update(dimensionName, hierarchyName string, element *models.Element) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/Elements('%s')", dimensionName, hierarchyName, element.Name)
	body, err := element.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, []byte(body))
}

func (s *ElementService) Delete(dimensionName, hierarchyName, elementName string) ([]byte, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/Elements('%s')", dimensionName, hierarchyName, elementName)
	return s.rest.DELETE(url)
}

func (s *ElementService) Exists(dimensionName, hierarchyName, elementName string) (bool, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/Elements('%s')?$select=Name", dimensionName, hierarchyName, elementName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}

func (s *ElementService) GetElementNames(dimensionName, hierarchyName string) ([]string, error) {
	url := fmt.Sprintf("/Dimensions('%s')/Hierarchies('%s')/Elements?$select=Name", dimensionName, hierarchyName)
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
