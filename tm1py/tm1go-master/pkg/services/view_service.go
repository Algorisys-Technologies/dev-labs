package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// ViewService handles view-related operations
type ViewService struct {
	rest *RestService
}

func NewViewService(rest *RestService) *ViewService {
	return &ViewService{rest: rest}
}

func (s *ViewService) Create(view models.View, private bool) ([]byte, error) {
	viewType := "Views"
	if private {
		viewType = "PrivateViews"
	}
	url := fmt.Sprintf("/Cubes('%s')/%s", view.GetCube(), viewType)
	body, err := view.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST(url, []byte(body))
}

func (s *ViewService) Get(cubeName, viewName string, private bool) (models.View, error) {
	viewType := "Views"
	if private {
		viewType = "PrivateViews"
	}
	url := fmt.Sprintf("/Cubes('%s')/%s('%s')?$expand=*", cubeName, viewType, viewName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var raw map[string]interface{}
	if err := json.Unmarshal(body, &raw); err != nil {
		return nil, err
	}

	if _, ok := raw["MDX"]; ok {
		var mdxView models.MDXView
		if err := json.Unmarshal(body, &mdxView); err != nil {
			return nil, err
		}
		mdxView.CubeName = cubeName
		return &mdxView, nil
	}

	var nativeView models.NativeView
	if err := json.Unmarshal(body, &nativeView); err != nil {
		return nil, err
	}
	nativeView.CubeName = cubeName
	return &nativeView, nil
}

func (s *ViewService) Delete(cubeName, viewName string, private bool) ([]byte, error) {
	viewType := "Views"
	if private {
		viewType = "PrivateViews"
	}
	url := fmt.Sprintf("/Cubes('%s')/%s('%s')", cubeName, viewType, viewName)
	return s.rest.DELETE(url)
}

func (s *ViewService) Exists(cubeName, viewName string, private bool) (bool, error) {
	viewType := "Views"
	if private {
		viewType = "PrivateViews"
	}
	url := fmt.Sprintf("/Cubes('%s')/%s('%s')?$select=Name", cubeName, viewType, viewName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}

func (s *ViewService) GetAllNames(cubeName string) ([]string, []string, error) {
	publicNames, err := s.getNamesByType(cubeName, "Views")
	if err != nil {
		return nil, nil, err
	}
	privateNames, err := s.getNamesByType(cubeName, "PrivateViews")
	if err != nil {
		return nil, nil, err
	}
	return publicNames, privateNames, nil
}

func (s *ViewService) getNamesByType(cubeName, viewType string) ([]string, error) {
	url := fmt.Sprintf("/Cubes('%s')/%s?$select=Name", cubeName, viewType)
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
