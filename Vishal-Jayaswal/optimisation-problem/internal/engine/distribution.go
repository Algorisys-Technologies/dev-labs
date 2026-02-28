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
			remaining[o.GetBagKey()] = 0
		}
		return
	}

	for _, o := range active {
		key := o.GetBagKey()
		share := (remaining[key] / totalRemaining) * capacity
		remaining[key] -= share
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
		remainingDays := int(endDate.Sub(currentDate).Hours()/24) + 1
		if remainingDays <= 0 {
			remainingDays = 1
		}

		requiredHrs := remainingHrs[o.GetBagKey()] / float64(remainingDays)
		demands = append(demands, models.Demand{Order: o, RequiredToday: requiredHrs, Deadline: endDate})
		totalRequiredHrs += requiredHrs
	}

	if totalRequiredHrs > processCapacity+1e-6 {
		return true
	}

	for _, d := range demands {
		remainingHrs[d.Order.GetBagKey()] -= d.RequiredToday
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

			key := d.Order.GetBagKey()
			if remainingHrs[key] <= 0 {
				continue
			}

			extra := math.Min(remainingHrs[key], processCapacity)
			remainingHrs[key] -= extra
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
) (overload bool, deficit float64, orderNo string) {

	if len(activeOrders) == 0 {
		return false, 0, ""
	}

	demands := []models.Demand{}

	for _, o := range activeOrders {
		key := o.GetBagKey()
		remaining := remainingHrs[key]
		if remaining <= 0 {
			continue
		}

		deadline := processEndDate(o)
		daysLeft := int(deadline.Sub(currentDate).Hours()/24) + 1
		if daysLeft < 1 {
			daysLeft = 1
		}

		// Optional smoothing metric
		requiredToday := remaining / float64(daysLeft)

		// Slack calculation
		slack := float64(daysLeft)*processCapacity - remaining

		// ❗ Detect impossible schedule
		if slack < 0 {
			// Add a small safety buffer (0.01) to "cross" the feasibility line
			deficit := (remaining/float64(daysLeft) - processCapacity) * 1.01
			return true, deficit + 0.01, o.GetBagKey()
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
		cumulativeWork += remainingHrs[d.Order.GetBagKey()]

		days := int(d.Deadline.Sub(currentDate).Hours()/24) + 1
		if days < 1 {
			days = 1
		}

		if cumulativeWork > float64(days)*processCapacity {
			// Add a small safety buffer (0.01) to "cross" the feasibility line
			deficit := (cumulativeWork/float64(days) - processCapacity) * 1.01
			return true, deficit + 0.01, d.Order.GetBagKey()
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

		key := d.Order.GetBagKey()
		rem := remainingHrs[key]
		work := math.Min(rem, processCapacity)

		remainingHrs[key] -= work
		processCapacity -= work
	}

	return false, 0, ""
}
