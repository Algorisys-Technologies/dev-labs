package engine

import (
	"math"
	"sort"
	"time"

	"optimisation-problem/internal/models"
)

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

// DistributeWithSlackEDF validates schedule feasibility by checking cumulative work against chronological deadline windows and prioritizes allocation using the Least Slack Time (LST) algorithm.
func DistributeWithSlackEDF(
	activeOrders []*models.Order,
	remainingHrs map[string]float64,
	currentDate time.Time,
	processEndDate func(*models.Order) time.Time,
	processCapacity float64,
) (overload bool) {

	if len(activeOrders) == 0 {
		return false
	}

	demands := []models.Demand{}

	for _, o := range activeOrders {
		remaining := remainingHrs[o.OrderNo]
		if remaining <= 0 {
			continue
		}

		deadline := processEndDate(o)
		daysLeft := int(deadline.Sub(currentDate).Hours() / 24)
		if daysLeft < 1 {
			daysLeft = 1
		}

		// Optional smoothing metric
		requiredToday := remaining / float64(daysLeft)

		// Slack calculation
		slack := float64(daysLeft)*processCapacity - remaining

		// ❗ Detect impossible schedule
		if slack < 0 {
			return true
		}

		demands = append(demands, models.Demand{
			Order:         o,
			RequiredToday: requiredToday,
			Deadline:      deadline,
			Slack:         slack,
		})
	}

	// Deadline window feasibility
	sort.Slice(demands, func(i, j int) bool {
		return demands[i].Deadline.Before(demands[j].Deadline)
	})
	cumulativeWork := 0.0
	for _, d := range demands {
		cumulativeWork += remainingHrs[d.Order.OrderNo]

		days := int(d.Deadline.Sub(currentDate).Hours() / 24)
		if days < 1 {
			days = 1
		}

		if cumulativeWork > float64(days)*processCapacity {
			return true
		}
	}

	// Sort by slack (ascending order)
	sort.Slice(demands, func(i, j int) bool {
		return demands[i].Slack < demands[j].Slack
	})

	// Allocate capacity
	for _, d := range demands {
		if processCapacity <= 0 {
			break
		}

		rem := remainingHrs[d.Order.OrderNo]
		work := math.Min(rem, processCapacity)

		remainingHrs[d.Order.OrderNo] -= work
		processCapacity -= work
	}

	return false
}
