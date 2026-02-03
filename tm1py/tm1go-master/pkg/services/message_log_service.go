package services

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
)

type MessageLogService struct {
	rest *RestService
}

func NewMessageLogService(rest *RestService) *MessageLogService {
	return &MessageLogService{rest: rest}
}

func (s *MessageLogService) GetEntries(reverse bool, since, until string, top int, logger, level string, msgContains []string) ([]map[string]interface{}, error) {
	order := "asc"
	if reverse {
		order = "desc"
	}
	u := fmt.Sprintf("/MessageLogEntries?$orderby=TimeStamp %s", order)

	var filters []string
	if since != "" {
		filters = append(filters, fmt.Sprintf("TimeStamp ge %s", since))
	}
	if until != "" {
		filters = append(filters, fmt.Sprintf("TimeStamp le %s", until))
	}
	if logger != "" {
		filters = append(filters, fmt.Sprintf("Logger eq '%s'", logger))
	}
	if level != "" {
		// TM1 level mapping: ERROR: 1, WARNING: 2, INFO: 3, DEBUG: 4, UNKNOWN: 5
		levelMap := map[string]int{
			"ERROR":   1,
			"WARNING": 2,
			"INFO":    3,
			"DEBUG":   4,
			"UNKNOWN": 5,
		}
		if idx, ok := levelMap[strings.ToUpper(level)]; ok {
			filters = append(filters, fmt.Sprintf("Level eq %d", idx))
		}
	}
	if len(msgContains) > 0 {
		var msgFilters []string
		for _, msg := range msgContains {
			msgFilters = append(msgFilters, fmt.Sprintf("contains(toupper(Message),toupper('%s'))", msg))
		}
		filters = append(filters, "("+strings.Join(msgFilters, " and ")+")")
	}

	if len(filters) > 0 {
		u += "&$filter=" + url.QueryEscape(strings.Join(filters, " and "))
	}

	if top > 0 {
		u += fmt.Sprintf("&$top=%d", top)
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
