package services

import (
	"encoding/json"
	"fmt"
)

type SessionService struct {
	rest *RestService
}

func NewSessionService(rest *RestService) *SessionService {
	return &SessionService{rest: rest}
}

func (s *SessionService) GetAll(includeUser, includeThreads bool) ([]map[string]interface{}, error) {
	url := "/Sessions"
	if includeUser || includeThreads {
		expands := ""
		if includeUser && includeThreads {
			expands = "User,Threads"
		} else if includeUser {
			expands = "User"
		} else {
			expands = "Threads"
		}
		url += "?$expand=" + expands
	}

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

func (s *SessionService) GetCurrent() (map[string]interface{}, error) {
	url := "/ActiveSession"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response map[string]interface{}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response, nil
}

func (s *SessionService) GetThreadsForCurrent(excludeIdle bool) ([]map[string]interface{}, error) {
	url := "/ActiveSession/Threads?$filter=Function ne 'GET /ActiveSession/Threads' and Function ne 'GET /api/v1/ActiveSession/Threads'"
	if excludeIdle {
		url += " and State ne 'Idle'"
	}

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

func (s *SessionService) Close(sessionID string) error {
	url := fmt.Sprintf("/Sessions('%s')/tm1.Close", sessionID)
	_, err := s.rest.POST(url, nil)
	return err
}
