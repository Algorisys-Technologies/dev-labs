package services

import (
	"encoding/json"
	"fmt"
)

type CellService struct {
	rest *RestService
}

type Cell struct {
	Tuple []string    `json:"Tuple"`
	Value interface{} `json:"Value"`
}

func (s *CellService) WriteValues(cubeName string, cells []Cell) error {
	url := fmt.Sprintf("/Cubes('%s')/tm1.Update", cubeName)

	type tm1UpdatePayload struct {
		Cells []struct {
			TupleBind []string    `json:"Tuple@odata.bind"`
			Value     interface{} `json:"Value"`
		} `json:"Cells"`
	}

	payload := tm1UpdatePayload{
		Cells: make([]struct {
			TupleBind []string    `json:"Tuple@odata.bind"`
			Value     interface{} `json:"Value"`
		}, len(cells)),
	}

	for i, cell := range cells {
		binds := make([]string, len(cell.Tuple))
		// Note: This is a simplification. Real logic needs dimension/hierarchy names.
		// In TM1py, it uses dimensions from the cube.
		// For now, we assume simple 1-to-1 dimension mapping.
		for j, elem := range cell.Tuple {
			binds[j] = fmt.Sprintf("Elements('%s')", elem)
		}
		payload.Cells[i].TupleBind = binds
		payload.Cells[i].Value = cell.Value
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	_, err = s.rest.POST(url, data)
	return err
}

func (s *CellService) ExecuteMDX(mdx string) (map[string]interface{}, error) {
	url := "/ExecuteMDX"
	payload := map[string]string{"MDX": mdx}
	data, _ := json.Marshal(payload)

	body, err := s.rest.POST(url, data)
	if err != nil {
		return nil, err
	}

	var response map[string]interface{}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response, nil
}

func (s *CellService) ExecuteView(cubeName, viewName string, private bool) (map[string]interface{}, error) {
	viewType := "Views"
	if private {
		viewType = "PrivateViews"
	}
	url := fmt.Sprintf("/Cubes('%s')/%s('%s')/tm1.Execute", cubeName, viewType, viewName)
	body, err := s.rest.POST(url, nil)
	if err != nil {
		return nil, err
	}

	var response map[string]interface{}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return response, nil
}

func (s *CellService) ExecuteMDXRaw(mdx string) (map[string]interface{}, error) {
	return s.ExecuteMDX(mdx)
}
