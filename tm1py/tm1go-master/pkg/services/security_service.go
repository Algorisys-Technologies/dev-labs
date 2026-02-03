package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

type SecurityService struct {
	rest *RestService
}

func NewSecurityService(rest *RestService) *SecurityService {
	return &SecurityService{rest: rest}
}

func (s *SecurityService) CreateUser(user *models.User) error {
	body, err := user.MapToTM1Body()
	if err != nil {
		return err
	}
	_, err = s.rest.POST("/Users", []byte(body))
	return err
}

func (s *SecurityService) CreateGroup(groupName string) error {
	payload := map[string]string{"Name": groupName}
	data, _ := json.Marshal(payload)
	_, err := s.rest.POST("/Groups", data)
	return err
}

func (s *SecurityService) GetUser(userName string) (*models.User, error) {
	url := fmt.Sprintf("/Users('%s')?$select=Name,FriendlyName,Password,Type,Enabled&$expand=Groups", userName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var user models.User
	if err := json.Unmarshal(body, &user); err != nil {
		return nil, err
	}

	return &user, nil
}

func (s *SecurityService) GetCurrentUser() (*models.User, error) {
	url := "/ActiveUser?$select=Name,FriendlyName,Password,Type,Enabled&$expand=Groups"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var user models.User
	if err := json.Unmarshal(body, &user); err != nil {
		return nil, err
	}

	return &user, nil
}

func (s *SecurityService) UpdateUser(user *models.User) error {
	url := fmt.Sprintf("/Users('%s')", user.Name)
	body, err := user.MapToTM1Body()
	if err != nil {
		return err
	}
	_, err = s.rest.PATCH(url, []byte(body))
	return err
}

func (s *SecurityService) DeleteUser(userName string) error {
	url := fmt.Sprintf("/Users('%s')", userName)
	_, err := s.rest.DELETE(url)
	return err
}

func (s *SecurityService) DeleteGroup(groupName string) error {
	url := fmt.Sprintf("/Groups('%s')", groupName)
	_, err := s.rest.DELETE(url)
	return err
}

func (s *SecurityService) GetAllUsers() ([]*models.User, error) {
	url := "/Users?$select=Name,FriendlyName,Password,Type,Enabled&$expand=Groups"
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

func (s *SecurityService) GetAllGroups() ([]string, error) {
	url := "/Groups?$select=Name"
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

	groups := make([]string, len(response.Value))
	for i, v := range response.Value {
		groups[i] = v.Name
	}
	return groups, nil
}

func (s *SecurityService) AddUserToGroups(userName string, groups []string) error {
	url := fmt.Sprintf("/Users('%s')", userName)
	binds := make([]string, len(groups))
	for i, g := range groups {
		binds[i] = fmt.Sprintf("Groups('%s')", g)
	}

	payload := map[string]interface{}{
		"Groups@odata.bind": binds,
	}
	data, _ := json.Marshal(payload)
	_, err := s.rest.PATCH(url, data)
	return err
}

func (s *SecurityService) RemoveUserFromGroup(userName, groupName string) error {
	url := fmt.Sprintf("/Users('%s')/Groups?$id=Groups('%s')", userName, groupName)
	_, err := s.rest.DELETE(url)
	return err
}
