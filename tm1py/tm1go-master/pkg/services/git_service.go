package services

import (
	"encoding/json"
	"fmt"
)

type GitService struct {
	rest *RestService
}

func NewGitService(rest *RestService) *GitService {
	return &GitService{rest: rest}
}

func (s *GitService) GetProject() (map[string]interface{}, error) {
	url := "/!tm1project"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var project map[string]interface{}
	if err := json.Unmarshal(body, &project); err != nil {
		return nil, err
	}
	return project, nil
}

func (s *GitService) Init(gitURL, deployment string, options map[string]interface{}) ([]byte, error) {
	url := "/GitInit"
	payload := map[string]interface{}{
		"URL":        gitURL,
		"Deployment": deployment,
	}
	for k, v := range options {
		payload[k] = v
	}
	data, _ := json.Marshal(payload)
	return s.rest.POST(url, data)
}

func (s *GitService) Status(options map[string]interface{}) (map[string]interface{}, error) {
	url := "/GitStatus"
	data, _ := json.Marshal(options)
	body, err := s.rest.POST(url, data)
	if err != nil {
		return nil, err
	}

	var status map[string]interface{}
	if err := json.Unmarshal(body, &status); err != nil {
		return nil, err
	}
	return status, nil
}

func (s *GitService) Push(options map[string]interface{}) ([]byte, error) {
	url := "/GitPush"
	data, _ := json.Marshal(options)
	return s.rest.POST(url, data)
}

func (s *GitService) Pull(branch string, options map[string]interface{}) ([]byte, error) {
	url := "/GitPull"
	payload := map[string]interface{}{
		"Branch": branch,
	}
	for k, v := range options {
		payload[k] = v
	}
	data, _ := json.Marshal(payload)
	return s.rest.POST(url, data)
}

func (s *GitService) ExecutePlan(planID string) ([]byte, error) {
	url := fmt.Sprintf("/GitPlans('%s')/tm1.Execute", planID)
	return s.rest.POST(url, nil)
}
