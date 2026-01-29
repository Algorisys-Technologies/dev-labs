package services

import (
	"encoding/json"
	"fmt"
)

type SandboxService struct {
	rest *RestService
}

func NewSandboxService(rest *RestService) *SandboxService {
	return &SandboxService{rest: rest}
}

func (s *SandboxService) GetAll() ([]map[string]interface{}, error) {
	url := "/Sandboxes?$select=Name,IncludeInSandboxDimension,IsLoaded,IsActive,IsQueued"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []map[string]interface{} `json:"value"`
	}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}
	return response.Value, nil
}

func (s *SandboxService) Create(name string, options map[string]interface{}) ([]byte, error) {
	url := "/Sandboxes"
	payload := map[string]interface{}{"Name": name}
	for k, v := range options {
		payload[k] = v
	}
	data, _ := json.Marshal(payload)
	return s.rest.POST(url, data)
}

func (s *SandboxService) Delete(name string) ([]byte, error) {
	url := fmt.Sprintf("/Sandboxes('%s')", name)
	return s.rest.DELETE(url)
}

func (s *SandboxService) Publish(name string) ([]byte, error) {
	url := fmt.Sprintf("/Sandboxes('%s')/tm1.Publish", name)
	return s.rest.POST(url, nil)
}

func (s *SandboxService) Reset(name string) ([]byte, error) {
	url := fmt.Sprintf("/Sandboxes('%s')/tm1.DiscardChanges", name)
	return s.rest.POST(url, nil)
}
