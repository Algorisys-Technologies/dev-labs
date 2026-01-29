package services

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
)

type LoggerService struct {
	rest *RestService
}

func NewLoggerService(rest *RestService) *LoggerService {
	return &LoggerService{rest: rest}
}

func (s *LoggerService) GetAll() ([]map[string]interface{}, error) {
	url := "/Loggers"
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

func (s *LoggerService) Get(loggerName string) (map[string]interface{}, error) {
	url := fmt.Sprintf("/Loggers('%s')", loggerName)
	body, err := s.rest.GET(url)
	if err != nil {
		return nil, err
	}

	var response map[string]interface{}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}
	delete(response, "@odata.context")
	return response, nil
}

func (s *LoggerService) Search(wildcard, level string) ([]map[string]interface{}, error) {
	u := "/Loggers"
	var filters []string

	if level != "" {
		levelMap := map[string]int{
			"FATAL":   0,
			"ERROR":   1,
			"WARNING": 2,
			"INFO":    3,
			"DEBUG":   4,
			"UNKNOWN": 5,
			"OFF":     6,
		}
		if idx, ok := levelMap[strings.ToUpper(level)]; ok {
			filters = append(filters, fmt.Sprintf("Level eq %d", idx))
		}
	}

	if wildcard != "" {
		filters = append(filters, fmt.Sprintf("contains(tolower(Name), tolower('%s'))", wildcard))
	}

	if len(filters) > 0 {
		u += "?$filter=" + url.QueryEscape(strings.Join(filters, " and "))
	}

	body, err := s.rest.GET(u)
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

func (s *LoggerService) SetLevel(loggerName, level string) ([]byte, error) {
	u := fmt.Sprintf("/Loggers('%s')", loggerName)

	levelMap := map[string]int{
		"FATAL":   0,
		"ERROR":   1,
		"WARNING": 2,
		"INFO":    3,
		"DEBUG":   4,
		"UNKNOWN": 5,
		"OFF":     6,
	}

	idx, ok := levelMap[strings.ToUpper(level)]
	if !ok {
		return nil, fmt.Errorf("invalid level: %s", level)
	}

	payload := map[string]int{"Level": idx}
	data, _ := json.Marshal(payload)
	return s.rest.PATCH(u, data)
}
