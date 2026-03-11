package main

import (
	"fmt"
	"log"

	"optimisation-problem/internal/engine"
	"optimisation-problem/internal/excel"
	"optimisation-problem/internal/models"
)

func main() {
	// Read orders
	orders, err := excel.ReadOrdersFromExcel("data/test-ppc-base-data.xlsx")
	if err != nil {
		log.Fatal(err)
	}

	// Read factory capacity
	factoryMaster, err := excel.ReadFactoriesFromExcel("data/factory-capacity.xlsx")
	if err != nil {
		log.Fatal(err)
	}

	// 1️⃣ IDENTIFY BOTTLENECKS
	fmt.Println("🔍 [STEP 1] Checking initial feasibility and identifying bottlenecks...")
	ok, overloads := engine.CheckFeasibility(orders, factoryMaster)
	if ok {
		fmt.Println("✅ All orders are already FEASIBLE. No action needed.")
		return
	}

	fmt.Println("❌ Initial system is INFEASIBLE. Primary bottlenecks detected:")
	for _, o := range overloads {
		fmt.Printf("    → %s: %s on %s (Responsible Order: %s)\n", o.Factory, o.Process, o.Date.Format("02/01/2006"), o.OrderNo)
	}

	// 2️⃣ REMOVAL STRATEGY & VERIFICATION
	fmt.Println("\n✂️ [STEP 2] Strategy: Remove orders to restore feasibility...")
	toRemove, success := engine.ResolveByRemovingOrders(orders, factoryMaster)
	if success && len(toRemove) > 0 {
		fmt.Printf("� Identified %d orders for removal: %v\n", len(toRemove), toRemove)

		// Create the feasible subset
		var feasibleOrders []models.Order
		toRemoveMap := make(map[string]bool)
		for _, id := range toRemove {
			toRemoveMap[id] = true
		}
		for _, o := range orders {
			if !toRemoveMap[o.OrderNo] {
				feasibleOrders = append(feasibleOrders, o)
			}
		}

		fmt.Println("🧪 VERIFYING feasibility of the remaining subset...")
		subsetOk, _ := engine.CheckFeasibility(feasibleOrders, factoryMaster)
		if subsetOk {
			fmt.Printf("✅ SUCCESS! The system is now feasible with %d orders remaining.\n", len(feasibleOrders))
		} else {
			fmt.Println("⚠️ ERROR: Verification failed. The subset is still not feasible.")
		}
	} else {
		fmt.Println("❌ Could not find a feasible subset by removing orders.")
	}

	// 3️⃣ MANPOWER ALTERNATIVE
	fmt.Println("\n� [STEP 3] Strategy: Keep ALL orders and add manpower...")
	// Create a copy of the factory map to avoid mutating the original capacity for this simulation
	manpowerFactories := make(map[string]models.Factory)
	for k, v := range factoryMaster {
		manpowerFactories[k] = v
	}

	if engine.ImproveFeasibility(orders, manpowerFactories, overloads) {
		fmt.Println("🎉 System made feasible by adding the headcount shown above.")
	} else {
		fmt.Println("💥 Could not restore feasibility even with extreme manpower increases.")
	}
}
