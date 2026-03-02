package engine

import (
	"math"
	"sort"
	"time"

	"optimisation-problem/internal/models"
)

// DistributeWithSlackEDF validates schedule feasibility by checking cumulative work against chronological deadline windows and prioritizes allocation using the Least Slack Time (LST) algorithm.
func DistributeWithSlackEDF(
	activeOrders []*models.Order,
	remainingMins map[string]float64,
	currentDate time.Time,
	processEndDate func(*models.Order) time.Time,
	processCapacity float64,
) (overload bool, deficit float64, orderNo string) {

	if len(activeOrders) == 0 {
		return false, 0, ""
	}

	// Epsilon tolerance to guard against float64 precision issues
	// (e.g. 1.2 workers = 575.9999... min, not exactly 576)
	const eps = 1e-6

	demands := []models.Demand{}

	for _, o := range activeOrders {
		key := o.GetBagKey()
		remaining := remainingMins[key]
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

		// Slack calculation (negative => this bag alone cannot meet its deadline)
		slack := float64(daysLeft)*processCapacity - remaining

		// ❗ Detect impossible schedule
		if slack < -eps {
			// Mathematical deficit required
			deficit := (remaining / float64(daysLeft)) - processCapacity
			return true, deficit, o.GetBagKey()
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
		cumulativeWork += remainingMins[d.Order.GetBagKey()]

		days := int(d.Deadline.Sub(currentDate).Hours()/24) + 1
		if days < 1 {
			days = 1
		}

		if cumulativeWork > float64(days)*processCapacity+eps {
			deficit := (cumulativeWork / float64(days)) - processCapacity
			return true, deficit, d.Order.GetBagKey()
		}
	}

	// Allocate capacity using Earliest Deadline First (EDF).
	for _, d := range demands {
		if processCapacity <= 0 {
			break
		}

		key := d.Order.GetBagKey()
		rem := remainingMins[key]
		work := math.Min(rem, processCapacity)

		remainingMins[key] -= work
		processCapacity -= work
	}

	return false, 0, ""
}
