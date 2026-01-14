package services

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
)

type AuditLogService struct {
	rest          *RestService
	configuration *ConfigurationService
}

func NewAuditLogService(rest *RestService) *AuditLogService {
	return &AuditLogService{
		rest:          rest,
		configuration: NewConfigurationService(rest),
	}
}

func (s *AuditLogService) GetEntries(user, objectType, objectName, since, until string, top int) ([]map[string]interface{}, error) {
	u := "/AuditLogEntries?$expand=AuditDetails"

	var filters []string
	if user != "" {
		filters = append(filters, fmt.Sprintf("UserName eq '%s'", user))
	}
	if objectType != "" {
		filters = append(filters, fmt.Sprintf("ObjectType eq '%s'", objectType))
	}
	if objectName != "" {
		filters = append(filters, fmt.Sprintf("ObjectName eq '%s'", objectName))
	}
	if since != "" {
		filters = append(filters, fmt.Sprintf("TimeStamp ge %s", since))
	}
	if until != "" {
		filters = append(filters, fmt.Sprintf("TimeStamp le %s", until))
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

func (s *AuditLogService) Activate() error {
	payload := map[string]interface{}{
		"Administration": map[string]interface{}{
			"AuditLog": map[string]interface{}{
				"Enable": true,
			},
		},
	}
	_, err := s.configuration.UpdateStatic(payload)
	return err
}
