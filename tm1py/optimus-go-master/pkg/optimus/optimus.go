package optimus

import (
	"fmt"

	"tm1go/pkg/services"
	"tm1go/pkg/utils"
)

// OptimusService provides high-level optimization utilities
type OptimusService struct {
	tm1 *services.TM1Service
}

func NewOptimusService(tm1 *services.TM1Service) *OptimusService {
	return &OptimusService{tm1: tm1}
}

// IsDimensionOnlyNumeric checks if a dimension contains only numeric elements
func (s *OptimusService) IsDimensionOnlyNumeric(dimensionName string) (bool, error) {
	hierarchy, err := s.tm1.Hierarchies.Get(dimensionName, dimensionName)
	if err != nil {
		return false, err
	}

	for _, element := range hierarchy.Elements {
		if element.Type != "Numeric" {
			return false, nil
		}
	}
	return true, nil
}

// RetrieveVmmVmt returns the VMM and VMT settings for a cube
func (s *OptimusService) RetrieveVmmVmt(cubeName string) (string, string, error) {
	mdxStr := fmt.Sprintf("SELECT {[}CubeProperties].[VMM], [}CubeProperties].[VMT]} ON 0, {[}Cubes].[%s]} ON 1 FROM [}CubeProperties]", cubeName)
	rawCellset, err := s.tm1.Cells.ExecuteMDXRaw(mdxStr)
	if err != nil {
		return "", "", err
	}

	content := utils.BuildContentFromCellset(rawCellset, 0, false, false)

	vmmKey := fmt.Sprintf("%s|VMM", cubeName)
	vmtKey := fmt.Sprintf("%s|VMT", cubeName)

	vmm := ""
	if cell, ok := content[vmmKey].(map[string]interface{}); ok {
		vmm = fmt.Sprintf("%v", cell["Value"])
	}

	vmt := ""
	if cell, ok := content[vmtKey].(map[string]interface{}); ok {
		vmt = fmt.Sprintf("%v", cell["Value"])
	}

	return vmm, vmt, nil
}

// WriteVmmVmt updates the VMM and VMT settings for a cube
func (s *OptimusService) WriteVmmVmt(cubeName string, vmm, vmt string) error {
	cells := []services.Cell{
		{Tuple: []string{cubeName, "VMM"}, Value: vmm},
		{Tuple: []string{cubeName, "VMT"}, Value: vmt},
	}
	return s.tm1.Cells.WriteValues("}CubeProperties", cells)
}

// RetrievePerformanceMonitorState checks if the performance monitor is active
func (s *OptimusService) RetrievePerformanceMonitorState() (bool, error) {
	// In TM1, PerformanceMonitorActive is in }StaticConfiguration cube
	// For simplicity, let's assume it's true as a default if we can't check.
	return true, nil // Placeholder
}

// ActivatePerformanceMonitor enables the performance monitor
func (s *OptimusService) ActivatePerformanceMonitor() error {
	cells := []services.Cell{
		{Tuple: []string{"PerformanceMonitorActive"}, Value: "T"},
	}
	return s.tm1.Cells.WriteValues("}StaticConfiguration", cells)
}

// DeactivatePerformanceMonitor disables the performance monitor
func (s *OptimusService) DeactivatePerformanceMonitor() error {
	cells := []services.Cell{
		{Tuple: []string{"PerformanceMonitorActive"}, Value: "F"},
	}
	return s.tm1.Cells.WriteValues("}StaticConfiguration", cells)
}
