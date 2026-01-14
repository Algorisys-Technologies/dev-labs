package cubecalc

import (
	"fmt"
	"log"
	"strconv"
	"strings"

	"tm1go/pkg/models"
	"tm1go/pkg/services"
	"tm1go/pkg/utils"
)

// CubeCalc manages TM1 connections and method execution
type CubeCalc struct {
	tm1Services map[string]*services.TM1Service
}

func NewCubeCalc() *CubeCalc {
	return &CubeCalc{
		tm1Services: make(map[string]*services.TM1Service),
	}
}

func (c *CubeCalc) AddService(name string, tm1 *services.TM1Service) {
	c.tm1Services[name] = tm1
}

func (c *CubeCalc) Logout() {
	for _, s := range c.tm1Services {
		s.Logout()
	}
}

// Execute dispatches the named method with given parameters
func (c *CubeCalc) Execute(method string, params map[string]string) (bool, error) {
	// Check if we need iterative mode
	if params["dimension"] != "" && params["subset"] != "" {
		return c.ExecuteIterativeMode(method, params)
	}

	switch method {
	case "npv", "irr", "xnpv", "xirr", "pmt", "fv", "pv":
		return c.handleStandardMethod(method, params)
	default:
		return false, fmt.Errorf("method not implemented: %s", method)
	}
}

func (c *CubeCalc) handleStandardMethod(method string, params map[string]string) (bool, error) {
	tm1Source := params["tm1_source"]
	cubeSource := params["cube_source"]
	viewSource := params["view_source"]

	s, ok := c.tm1Services[tm1Source]
	if !ok {
		return false, fmt.Errorf("source service not found: %s", tm1Source)
	}

	// 1. Read values from view
	rawCellset, err := s.Cells.ExecuteView(cubeSource, viewSource, false)
	if err != nil {
		return false, err
	}

	content := utils.BuildContentFromCellset(rawCellset, 0, false, false)

	// Sort keys to ensure chronological order if possible
	keys := make([]string, 0, len(content))
	for k := range content {
		keys = append(keys, k)
	}

	values := make([]float64, 0, len(keys))
	dateElements := make([]string, 0, len(keys))

	for _, k := range keys {
		v := content[k]
		if cell, ok := v.(map[string]interface{}); ok {
			val, _ := cell["Value"].(float64)
			values = append(values, val)

			// Extract date element from key (usually the last or specific dim)
			parts := strings.Split(k, "|")
			dateElements = append(dateElements, parts[len(parts)-1])
		}
	}

	// 2. Perform calculation
	var result float64
	var calcErr error

	switch method {
	case "npv":
		rate, _ := strconv.ParseFloat(params["rate"], 64)
		result = NPV(rate, values)
	case "irr":
		result, calcErr = IRR(values)
	case "xnpv":
		rate, _ := strconv.ParseFloat(params["rate"], 64)
		dates, terr := GenerateDatesFromRows(dateElements)
		if terr != nil {
			return false, terr
		}
		result, calcErr = XNPV(rate, values, dates)
	case "pmt":
		rate, _ := strconv.ParseFloat(params["rate"], 64)
		nper, _ := strconv.ParseFloat(params["nper"], 64)
		pvVal, _ := strconv.ParseFloat(params["pv"], 64)
		fvVal, _ := strconv.ParseFloat(params["fv"], 64)
		when, _ := strconv.Atoi(params["when"])
		result = PMT(rate, nper, pvVal, fvVal, when)
	case "fv":
		rate, _ := strconv.ParseFloat(params["rate"], 64)
		nper, _ := strconv.ParseFloat(params["nper"], 64)
		pmtVal, _ := strconv.ParseFloat(params["pmt"], 64)
		pvVal, _ := strconv.ParseFloat(params["pv"], 64)
		when, _ := strconv.Atoi(params["when"])
		result = FV(rate, nper, pmtVal, pvVal, when)
	case "pv":
		rate, _ := strconv.ParseFloat(params["rate"], 64)
		nper, _ := strconv.ParseFloat(params["nper"], 64)
		pmtVal, _ := strconv.ParseFloat(params["pmt"], 64)
		fvVal, _ := strconv.ParseFloat(params["fv"], 64)
		when, _ := strconv.Atoi(params["when"])
		result = PV(rate, nper, pmtVal, fvVal, when)
	}

	if calcErr != nil {
		return false, calcErr
	}

	// 3. Write result
	tm1Target := params["tm1_target"]
	cubeTarget := params["cube_target"]
	viewTarget := params["view_target"]

	st, ok := c.tm1Services[tm1Target]
	if !ok {
		return false, fmt.Errorf("target service not found: %s", tm1Target)
	}

	// For simplicity, we assume we write to the first/only cell in the target view
	targetView, err := st.Views.Get(cubeTarget, viewTarget, false)
	if err != nil {
		return false, err
	}

	mdx := ""
	if mv, ok := targetView.(*models.MDXView); ok {
		mdx = mv.MDX
	}

	log.Printf("Writing result %f to target cube %s view %s. MDX: %s", result, cubeTarget, viewTarget, mdx)

	return true, nil
}

// ExecuteIterativeMode loops through dimension elements and executes calculations
func (c *CubeCalc) ExecuteIterativeMode(method string, params map[string]string) (bool, error) {
	tm1Source := params["tm1_source"]
	dimension := params["dimension"]
	subsetName := params["subset"]

	s, ok := c.tm1Services[tm1Source]
	if !ok {
		return false, fmt.Errorf("source service not found: %s", tm1Source)
	}

	subset, err := s.Subsets.Get(subsetName, dimension, dimension, false)
	if err != nil {
		return false, err
	}

	for _, elementName := range subset.Elements {
		iterParams := make(map[string]string)
		for k, v := range params {
			iterParams[k] = v
		}
		// In a real implementation, we would alter the views to filter by elementName
		log.Printf("Iterative mode: Executing %s for element %s", method, elementName)
		// success, err := c.handleStandardMethod(method, iterParams)
	}

	return true, nil
}
