package cubecalc

import (
	"time"
)

// CalculationParams represents the parameters passed to calculation methods
type CalculationParams struct {
	Method     string
	Tm1Source  string
	Tm1Target  string
	CubeSource string
	CubeTarget string
	ViewSource string
	ViewTarget string
	Dimension  string
	Subset     string
	Other      map[string]string
}

// Config represents the connection configuration for a TM1 server
type Config struct {
	BaseURL   string
	User      string
	Password  string
	DecodeB64 bool
	Namespace string
}

// Date helper for calculations
type DateValue struct {
	Date  time.Time
	Value float64
}
