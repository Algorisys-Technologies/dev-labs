package services

import (
	"encoding/json"
)

type ConfigurationService struct {
	rest *RestService
}

func NewConfigurationService(rest *RestService) *ConfigurationService {
	return &ConfigurationService{rest: rest}
}

func (s *ConfigurationService) GetAll() (map[string]interface{}, error) {
	url := "/Configuration"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var config map[string]interface{}
	if err := json.Unmarshal(body, &config); err != nil {
		return nil, err
	}
	delete(config, "@odata.context")
	return config, nil
}

func (s *ConfigurationService) GetServerName() (string, error) {
	url := "/Configuration/ServerName/$value"
	body, err := s.rest.GET(url)
	if err != nil {
		return "", err
	}
	return string(body), nil
}

func (s *ConfigurationService) GetProductVersion() (string, error) {
	url := "/Configuration/ProductVersion/$value"
	body, err := s.rest.GET(url)
	if err != nil {
		return "", err
	}
	return string(body), nil
}

func (s *ConfigurationService) GetStatic() (map[string]interface{}, error) {
	url := "/StaticConfiguration"
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var config map[string]interface{}
	if err := json.Unmarshal(body, &config); err != nil {
		return nil, err
	}
	delete(config, "@odata.context")
	return config, nil
}

func (s *ConfigurationService) UpdateStatic(config map[string]interface{}) ([]byte, error) {
	url := "/StaticConfiguration"
	data, err := json.Marshal(config)
	if err != nil {
		return nil, err
	}
	return s.rest.PATCH(url, data)
}
