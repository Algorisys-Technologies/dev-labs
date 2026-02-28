package models

import (
	"strings"
	"time"
)

type ProcessInfo struct {
	Name       string
	WorkingHrs float64
	StartDate  time.Time
	EndDate    time.Time
}

type Factory struct {
	Name            string
	ProcessCapacity map[string]float64 // name -> total Working Hours per day
}

type Order struct {
	OrderNo   string
	BagNo     string
	Factory   string
	OrderType string // "mined" or "lgd"
	Processes map[string]ProcessInfo
}

func (o *Order) GetBagKey() string {
	if o.BagNo == "" {
		return o.OrderNo
	}
	return o.OrderNo + "|" + o.BagNo
}

func ParseBagKey(key string) (string, string) {
	parts := strings.Split(key, "|")
	if len(parts) < 2 {
		return key, ""
	}
	return parts[0], parts[1]
}

type Overload struct {
	Factory string
	Date    time.Time
	Process string
	Deficit float64 // Working Hours needed
	OrderNo string
	BagNo   string
}

type Demand struct {
	Order         *Order
	ProcessName   string
	RequiredToday float64
	Deadline      time.Time
	Slack         float64
}
