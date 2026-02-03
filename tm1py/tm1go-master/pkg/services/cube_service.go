package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// CubeService handles cube-related operations
type CubeService struct {
	rest *RestService
}

func NewCubeService(rest *RestService) *CubeService {
	return &CubeService{rest: rest}
}

func (s *CubeService) Create(cube *models.Cube) ([]byte, error) {
	body, err := cube.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST("/Cubes", []byte(body))
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

func (s *CubeService) GetAll() ([]*models.Cube, error) {
	url := "/Cubes?$expand=Dimensions($select=Name)"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []struct {
			Name       string `json:"Name"`
			Dimensions []struct {
				Name string `json:"Name"`
			} `json:"Dimensions"`
			Rules string `json:"Rules"`
		} `json:"value"`
	}

	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	cubes := make([]*models.Cube, len(response.Value))
	for i, v := range response.Value {
		dims := make([]string, len(v.Dimensions))
		for j, d := range v.Dimensions {
			dims[j] = d.Name
		}
		cubes[i] = models.NewCube(v.Name, dims, v.Rules)
	}

	return cubes, nil
}

func (s *CubeService) GetAllNames(skipControlCubes bool) ([]string, error) {
	url := "/Cubes?$select=Name"
	if skipControlCubes {
		url = "/ModelCubes()?$select=Name"
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

func (s *CubeService) Update(cube *models.Cube) ([]byte, error) {
	url := fmt.Sprintf("/Cubes('%s')", cube.Name)
	body, err := cube.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, []byte(body))
}

func (s *CubeService) Delete(cubeName string) ([]byte, error) {
	url := fmt.Sprintf("/Cubes('%s')", cubeName)
	return s.rest.DELETE(url)
}

func (s *CubeService) Exists(cubeName string) (bool, error) {
	url := fmt.Sprintf("/Cubes('%s')?$select=Name", cubeName)
	_, err := s.rest.GET(url)
	if err != nil {
		// This is a bit naive, as it might be a different error
		// but for now good enough
		return false, nil
	}
	return true, nil
}

func (s *CubeService) UpdateStorageDimensionOrder(cubeName string, dimensionOrder []string) error {
	url := fmt.Sprintf("/Cubes('%s')/tm1.ReorderDimensions", cubeName)
	payload := map[string][]string{"DimensionLayout": dimensionOrder}
	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = s.rest.POST(url, data)
	return err
}
