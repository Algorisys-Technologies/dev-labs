package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// ChoreService handles chore-related operations
type ChoreService struct {
	rest *RestService
}

func NewChoreService(rest *RestService) *ChoreService {
	return &ChoreService{rest: rest}
}

func (s *ChoreService) Get(choreName string) (*models.Chore, error) {
	url := fmt.Sprintf("/Chores('%s')?$expand=Tasks($expand=*,Process($select=Name),Chore($select=Name))", choreName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var chore models.Chore
	if err := json.Unmarshal(body, &chore); err != nil {
		return nil, err
	}

	return &chore, nil
}

func (s *ChoreService) GetAll() ([]*models.Chore, error) {
	url := "/Chores?$expand=Tasks($expand=*,Process($select=Name),Chore($select=Name))"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []*models.Chore `json:"value"`
	}

	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response.Value, nil
}

func (s *ChoreService) GetAllNames() ([]string, error) {
	url := "/Chores?$select=Name"
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

func (s *ChoreService) Create(chore *models.Chore) ([]byte, error) {
	body, err := chore.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST("/Chores", []byte(body))
}

func (s *ChoreService) Update(chore *models.Chore) ([]byte, error) {
	url := fmt.Sprintf("/Chores('%s')", chore.Name)
	body, err := chore.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, []byte(body))
}

func (s *ChoreService) Delete(choreName string) ([]byte, error) {
	url := fmt.Sprintf("/Chores('%s')", choreName)
	return s.rest.DELETE(url)
}

func (s *ChoreService) Exists(choreName string) (bool, error) {
	url := fmt.Sprintf("/Chores('%s')?$select=Name", choreName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}

func (s *ChoreService) Execute(choreName string) ([]byte, error) {
	url := fmt.Sprintf("/Chores('%s')/tm1.Execute", choreName)
	return s.rest.POST(url, nil)
}

func (s *ChoreService) Activate(choreName string) ([]byte, error) {
	url := fmt.Sprintf("/Chores('%s')/tm1.Activate", choreName)
	return s.rest.POST(url, nil)
}

func (s *ChoreService) Deactivate(choreName string) ([]byte, error) {
	url := fmt.Sprintf("/Chores('%s')/tm1.Deactivate", choreName)
	return s.rest.POST(url, nil)
}
