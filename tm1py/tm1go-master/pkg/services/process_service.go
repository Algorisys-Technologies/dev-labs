package services

import (
	"encoding/json"
	"fmt"
	"tm1go/pkg/models"
)

// ProcessService handles process-related operations
type ProcessService struct {
	rest *RestService
}

func NewProcessService(rest *RestService) *ProcessService {
	return &ProcessService{rest: rest}
}

func (s *ProcessService) Get(processName string) (*models.Process, error) {
	url := fmt.Sprintf("/Processes('%s')?$select=*,UIData,VariablesUIData,DataSource", processName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var process models.Process
	if err := json.Unmarshal(body, &process); err != nil {
		return nil, err
	}

	return &process, nil
}

func (s *ProcessService) GetAll(skipControlProcesses bool) ([]*models.Process, error) {
	filter := ""
	if skipControlProcesses {
		filter = "&$filter=startswith(Name,'}') eq false and startswith(Name,'{') eq false"
	}

	url := "/Processes?$select=*,UIData,VariablesUIData,DataSource" + filter
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []*models.Process `json:"value"`
	}

	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response.Value, nil
}

func (s *ProcessService) GetAllNames(skipControlProcesses bool) ([]string, error) {
	filter := ""
	if skipControlProcesses {
		filter = "&$filter=startswith(Name,'}') eq false and startswith(Name,'{') eq false"
	}

	url := "/Processes?$select=Name" + filter
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

func (s *ProcessService) Create(process *models.Process) ([]byte, error) {
	body, err := process.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.POST("/Processes", []byte(body))
}

func (s *ProcessService) Update(process *models.Process) ([]byte, error) {
	url := fmt.Sprintf("/Processes('%s')", process.Name)
	body, err := process.MapToTM1Body()
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, []byte(body))
}

func (s *ProcessService) Delete(processName string) ([]byte, error) {
	url := fmt.Sprintf("/Processes('%s')", processName)
	return s.rest.DELETE(url)
}

func (s *ProcessService) Exists(processName string) (bool, error) {
	url := fmt.Sprintf("/Processes('%s')?$select=Name", processName)
	_, err := s.rest.GET(url)
	if err != nil {
		return false, nil
	}
	return true, nil
}

func (s *ProcessService) Execute(processName string, parameters map[string]interface{}) ([]byte, error) {
	url := fmt.Sprintf("/Processes('%s')/tm1.Execute", processName)

	params := make([]map[string]interface{}, 0)
	if parameters != nil {
		for k, v := range parameters {
			params = append(params, map[string]interface{}{
				"Name":  k,
				"Value": v,
			})
		}
	}

	payload := map[string]interface{}{
		"Parameters": params,
	}

	jsonBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	return s.rest.POST(url, jsonBytes)
}
