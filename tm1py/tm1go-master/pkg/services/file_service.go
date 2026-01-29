package services

import (
	"encoding/json"
	"fmt"
	"net/url"
)

type FileService struct {
	rest               *RestService
	versionContentPath string
}

func NewFileService(rest *RestService) *FileService {
	// Defaulting to "Blobs" for now, ideally this would check server version
	return &FileService{
		rest:               rest,
		versionContentPath: "Blobs",
	}
}

func (s *FileService) GetAllNames() ([]string, error) {
	u := fmt.Sprintf("/Contents('%s')/Contents?$select=Name", s.versionContentPath)
	body, err := s.rest.GET(u)
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

func (s *FileService) Get(fileName string) ([]byte, error) {
	u := fmt.Sprintf("/Contents('%s')/Contents('%s')/Content", s.versionContentPath, fileName)
	return s.rest.GET(u)
}

func (s *FileService) Create(fileName string, content []byte) ([]byte, error) {
	u := fmt.Sprintf("/Contents('%s')/Contents", s.versionContentPath)
	body := map[string]interface{}{
		"@odata.type": "#ibm.tm1.api.v1.Document",
		"ID":          fileName,
		"Name":        fileName,
	}
	data, _ := json.Marshal(body)
	_, err := s.rest.POST(u, data)
	if err != nil {
		return nil, err
	}

	return s.Update(fileName, content)
}

func (s *FileService) Update(fileName string, content []byte) ([]byte, error) {
	u := fmt.Sprintf("/Contents('%s')/Contents('%s')/Content", s.versionContentPath, fileName)
	return s.rest.PUT(u, content)
}

func (s *FileService) Exists(fileName string) (bool, error) {
	u := fmt.Sprintf("/Contents('%s')/Contents('%s')", s.versionContentPath, fileName)
	return s.rest.Exists(u)
}

func (s *FileService) Delete(fileName string) ([]byte, error) {
	u := fmt.Sprintf("/Contents('%s')/Contents('%s')", s.versionContentPath, fileName)
	return s.rest.DELETE(u)
}

func (s *FileService) Search(wildcard string) ([]string, error) {
	filter := fmt.Sprintf("contains(tolower(Name), tolower('%s'))", wildcard)
	u := fmt.Sprintf("/Contents('%s')/Contents?$select=Name&$filter=%s", s.versionContentPath, url.QueryEscape(filter))

	body, err := s.rest.GET(u)
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
