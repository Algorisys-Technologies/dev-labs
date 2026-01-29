package services

import (
	"encoding/json"
	"fmt"
)

type AnnotationService struct {
	rest *RestService
}

func NewAnnotationService(rest *RestService) *AnnotationService {
	return &AnnotationService{rest: rest}
}

func (s *AnnotationService) GetAll(cubeName string) ([]map[string]interface{}, error) {
	url := fmt.Sprintf("/Cubes('%s')/Annotations?$expand=DimensionalContext($select=Name)", cubeName)
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

func (s *AnnotationService) Get(annotationID string) (map[string]interface{}, error) {
	url := fmt.Sprintf("/Annotations('%s')?$expand=DimensionalContext($select=Name)", annotationID)
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

func (s *AnnotationService) Create(annotation map[string]interface{}) ([]byte, error) {
	url := "/Annotations"
	data, _ := json.Marshal(annotation)
	return s.rest.POST(url, data)
}

func (s *AnnotationService) Delete(annotationID string) ([]byte, error) {
	url := fmt.Sprintf("/Annotations('%s')", annotationID)
	return s.rest.DELETE(url)
}
