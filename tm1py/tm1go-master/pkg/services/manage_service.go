package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type ManageService struct {
	domain     string
	rootClient string
	rootSecret string
	rootURL    string
}

func NewManageService(domain, rootClient, rootSecret string) *ManageService {
	return &ManageService{
		domain:     domain,
		rootClient: rootClient,
		rootSecret: rootSecret,
		rootURL:    fmt.Sprintf("%s/manage/v1", domain),
	}
}

func (s *ManageService) doRequest(method, url string, body []byte) ([]byte, error) {
	req, err := http.NewRequest(method, url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	req.SetBasicAuth(s.rootClient, s.rootSecret)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	return respBody, nil
}

func (s *ManageService) GetInstances() ([]map[string]interface{}, error) {
	url := fmt.Sprintf("%s/Instances", s.rootURL)
	data, err := s.doRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []map[string]interface{} `json:"value"`
	}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}
	return response.Value, nil
}

func (s *ManageService) CreateInstance(instanceName string) ([]byte, error) {
	url := fmt.Sprintf("%s/Instances", s.rootURL)
	payload := map[string]string{"Name": instanceName}
	data, _ := json.Marshal(payload)
	return s.doRequest("POST", url, data)
}

func (s *ManageService) DeleteInstance(instanceName string) ([]byte, error) {
	url := fmt.Sprintf("%s/Instances('%s')", s.rootURL, instanceName)
	return s.doRequest("DELETE", url, nil)
}

func (s *ManageService) GetDatabases(instanceName string) ([]map[string]interface{}, error) {
	url := fmt.Sprintf("%s/Instances('%s')/Databases", s.rootURL, instanceName)
	data, err := s.doRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var response struct {
		Value []map[string]interface{} `json:"value"`
	}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}
	return response.Value, nil
}
