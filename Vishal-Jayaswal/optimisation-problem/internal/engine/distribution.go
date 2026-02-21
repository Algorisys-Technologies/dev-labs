package engine

import (
	"math"
	"sort"
	"time"

	"optimisation-problem/internal/models"
)

func DistributeEvenWithEDF(
	activeOrders []*models.Order,
	remainingHrs map[string]float64,
	currentDate time.Time,
	processEndDate func(*models.Order) time.Time,
	processCapacity float64,
) (overload bool) {

	if len(activeOrders) == 0 {
		return false
	}

	// Track the daily required work and deadlines to prioritize distribution (EDF) and check for overloads
	var demands []models.Demand
	totalRequiredHrs := 0.0

	for _, o := range activeOrders {
		endDate := processEndDate(o)
		remainingDays := int(endDate.Sub(currentDate).Hours() / 24)
		if remainingDays <= 0 {
			remainingDays = 1
		}

		requiredHrs := remainingHrs[o.OrderNo] / float64(remainingDays)
		demands = append(demands, models.Demand{Order: o, RequiredToday: requiredHrs, Deadline: endDate})
		totalRequiredHrs += requiredHrs
	}

	if totalRequiredHrs > processCapacity+1e-6 {
		return true
	}

	for _, d := range demands {
		remainingHrs[d.Order.OrderNo] -= d.RequiredToday
		processCapacity -= d.RequiredToday
	}

	if processCapacity > 0 {
		sort.Slice(demands, func(i, j int) bool {
			return demands[i].Deadline.Before(demands[j].Deadline)
		})

		for _, d := range demands {
			if processCapacity <= 0 {
				break
			}

			if remainingHrs[d.Order.OrderNo] <= 0 {
				continue
			}

			extra := math.Min(remainingHrs[d.Order.OrderNo], processCapacity)
			remainingHrs[d.Order.OrderNo] -= extra
			processCapacity -= extra
		}
	}

	return false
}

func DistributeWork(active []*models.Order, remaining map[string]float64, totalRemaining, capacity float64) {
	if totalRemaining == 0 || capacity == 0 {
		return
	}

	if totalRemaining <= capacity {
		for _, o := range active {
			remaining[o.OrderNo] = 0
		}
		return
	}

	for _, o := range active {
		share := (remaining[o.OrderNo] / totalRemaining) * capacity
		remaining[o.OrderNo] -= share
	}
}
