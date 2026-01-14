package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// TM1Service is the main entry point for the TM1 API
type TM1Service struct {
	Rest       *RestService
	Cubes      *CubeService
	Dimensions *DimensionService
	Cells      *CellService
}

func NewTM1Service(address string, port int, ssl bool, user, password, namespace, databaseName string) (*TM1Service, error) {
	rs, err := NewRestService(address, port, ssl, user, password, namespace, databaseName)
	if err != nil {
		return nil, err
	}

	tm1 := &TM1Service{
		Rest: rs,
	}
	tm1.Cubes = &CubeService{rest: rs}
	tm1.Dimensions = &DimensionService{rest: rs}
	tm1.Cells = &CellService{rest: rs}

	return tm1, nil
}

// CubeService handles cube-related operations
type CubeService struct {
	rest *RestService
}

func (s *CubeService) GetAllNames() ([]string, error) {
	body, err := s.rest.GET("/Cubes?$select=Name")
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

func (s *CubeService) Get(cubeName string) (*models.Cube, error) {
	url := fmt.Sprintf("/Cubes('%s')?$expand=Dimensions($select=Name)", cubeName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var cubeData struct {
		Name       string `json:"Name"`
		Dimensions []struct {
			Name string `json:"Name"`
		} `json:"Dimensions"`
		Rules string `json:"Rules"`
	}

	if err := json.Unmarshal(body, &cubeData); err != nil {
		return nil, err
	}

	dims := make([]string, len(cubeData.Dimensions))
	for i, d := range cubeData.Dimensions {
		dims[i] = d.Name
	}

	return models.NewCube(cubeData.Name, dims, cubeData.Rules), nil
}

// DimensionService handles dimension-related operations
type DimensionService struct {
	rest *RestService
}

func (s *DimensionService) GetAllNames() ([]string, error) {
	body, err := s.rest.GET("/Dimensions?$select=Name")
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
