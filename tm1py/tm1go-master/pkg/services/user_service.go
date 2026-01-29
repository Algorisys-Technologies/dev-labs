package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

type UserService struct {
	rest *RestService
}

func NewUserService(rest *RestService) *UserService {
	return &UserService{rest: rest}
}

func (s *UserService) GetAll() ([]*models.User, error) {
	url := "/Users?$expand=Groups"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []*models.User `json:"value"`
	}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response.Value, nil
}

func (s *UserService) GetActive() ([]*models.User, error) {
	url := "/Users?$filter=IsActive eq true&$expand=Groups"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []*models.User `json:"value"`
	}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response.Value, nil
}

func (s *UserService) IsActive(userName string) (bool, error) {
	url := fmt.Sprintf("/Users('%s')/IsActive", userName)
	body, err := s.rest.GET(url)
	if err != nil {
		return false, err
	}

	var response struct {
		Value bool `json:"value"`
	}
	if err := json.Unmarshal(body, &response); err != nil {
		return false, err
	}

	return response.Value, nil
}

func (s *UserService) Disconnect(userName string) error {
	url := fmt.Sprintf("/Users('%s')/tm1.Disconnect", userName)
	_, err := s.rest.POST(url, nil)
	return err
}

func (s *UserService) GetCurrent() (*models.User, error) {
	// SecurityService.GetCurrentUser handles this
	security := NewSecurityService(s.rest)
	return security.GetCurrentUser()
}
