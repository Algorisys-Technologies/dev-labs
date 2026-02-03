package services

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
)

type TransactionLogService struct {
	rest *RestService
}

func NewTransactionLogService(rest *RestService) *TransactionLogService {
	return &TransactionLogService{rest: rest}
}

func (s *TransactionLogService) GetEntries(reverse bool, user, cube string, since, until string, top int, elementTupleFilter map[string]string) ([]map[string]interface{}, error) {
	order := "asc"
	if reverse {
		order = "desc"
	}
	u := fmt.Sprintf("/TransactionLogEntries?$orderby=TimeStamp %s", order)

	var filters []string
	if user != "" {
		filters = append(filters, fmt.Sprintf("User eq '%s'", user))
	}
	if cube != "" {
		filters = append(filters, fmt.Sprintf("Cube eq '%s'", cube))
	}
	if since != "" {
		filters = append(filters, fmt.Sprintf("TimeStamp ge %s", since))
	}
	if until != "" {
		filters = append(filters, fmt.Sprintf("TimeStamp le %s", until))
	}
	if len(elementTupleFilter) > 0 {
		var tupleFilters []string
		for k, v := range elementTupleFilter {
			tupleFilters = append(tupleFilters, fmt.Sprintf("e %s '%s'", v, k))
		}
		filters = append(filters, fmt.Sprintf("Tuple/any(e: %s)", strings.Join(tupleFilters, " or ")))
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
