package models

import "time"

type Factory struct {
	Name        string
	FilManHours float64 // hours per day
	PolManHours float64 // hours per day
	FQCManHours float64 // hours per day

	AddFilManHours float64 // hours per day
	AddPolManHours float64 // hours per day
	AddFQCManHours float64 // hours per day
}

type Order struct {
	OrderNo            string
	Factory            string
	FilingStartDate    time.Time
	PolishingStartDate time.Time
	FQCStartDate       time.Time
	OrderEndDate       time.Time
	FilWorkingHrs      float64
	PolWorkingHrs      float64
	FQCWorkingHrs      float64
}

type Overload struct {
	Factory string
	Date    time.Time
	Process string // "Filing", "Polishing", "FQC"
	Excess  float64
}

// Demand represents the daily work required for an order to stay on schedule and its deadline.
type Demand struct {
	Order         *Order
	RequiredToday float64
	Deadline      time.Time
	Slack         float64
}
