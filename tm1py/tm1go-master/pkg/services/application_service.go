package services

import (
	"encoding/json"
	"fmt"
)

type ApplicationService struct {
	rest *RestService
}

func NewApplicationService(rest *RestService) *ApplicationService {
	return &ApplicationService{rest: rest}
}

func (s *ApplicationService) GetPublicRootNames() ([]string, error) {
	url := "/Contents('Applications')/Contents"
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

func (s *ApplicationService) GetPrivateRootNames() ([]string, error) {
	url := "/Contents('Applications')/PrivateContents"
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

func (s *ApplicationService) Delete(path, appType, name string, private bool) ([]byte, error) {
	// Simplified URL construction for now
	contents := "Contents"
	if private {
		contents = "PrivateContents"
	}
	url := fmt.Sprintf("/Contents('Applications')/%s('%s')", contents, name)
	return s.rest.DELETE(url)
}

func (s *ApplicationService) Exists(name string, private bool) (bool, error) {
	contents := "Contents"
	if private {
		contents = "PrivateContents"
	}
	url := fmt.Sprintf("/Contents('Applications')/%s('%s')", contents, name)
	return s.rest.Exists(url)
}
