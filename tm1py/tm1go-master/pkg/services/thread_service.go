package services

import (
	"encoding/json"
	"fmt"
)

type ThreadService struct {
	rest *RestService
}

func NewThreadService(rest *RestService) *ThreadService {
	return &ThreadService{rest: rest}
}

func (s *ThreadService) GetAll() ([]map[string]interface{}, error) {
	url := "/Threads"
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

func (s *ThreadService) GetActive() ([]map[string]interface{}, error) {
	url := "/Threads?$filter=Function ne 'GET /Threads' and State ne 'Idle'"
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

func (s *ThreadService) Cancel(threadID int) error {
	url := fmt.Sprintf("/Threads('%d')/tm1.CancelOperation", threadID)
	_, err := s.rest.POST(url, nil)
	return err
}
