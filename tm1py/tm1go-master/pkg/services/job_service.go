package services

import (
	"encoding/json"
	"fmt"
)

type JobService struct {
	rest *RestService
}

func NewJobService(rest *RestService) *JobService {
	return &JobService{rest: rest}
}

func (s *JobService) GetAll() ([]map[string]interface{}, error) {
	url := "/Jobs"
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

func (s *JobService) Cancel(jobID interface{}) error {
	url := fmt.Sprintf("/Jobs('%v')/tm1.Cancel", jobID)
	_, err := s.rest.POST(url, nil)
	return err
}

func (s *JobService) CancelAll() error {
	jobs, err := s.GetAll()
	if err != nil {
		return err
	}

	for _, job := range jobs {
		if id, ok := job["ID"]; ok {
			s.Cancel(id)
		}
	}
	return nil
}
