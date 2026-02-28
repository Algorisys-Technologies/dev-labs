package main

import (
	"fmt"
	"log"

	"optimisation-problem/internal/engine"
	"optimisation-problem/internal/excel"
)

func main() {
	// 1. Read input data
	orders, err := excel.ReadOrdersFromExcel("data3/ppc-base-data.xlsx")
	if err != nil {
		log.Fatalf("❌ Error reading orders: %v", err)
	}

	factoryMaster, err := excel.ReadFactoriesFromExcel("data3/factory-capacity.xlsx")
	if err != nil {
		log.Fatalf("❌ Error reading factories: %v", err)
	}

	// 2. Initial feasibility check
	fmt.Println("🔍 [STEP 1] Checking initial feasibility and identifying bottlenecks...")
	ok, overloads := engine.CheckFeasibility(orders, factoryMaster)
	if ok {
		fmt.Println("✅ All orders are FEASIBLE with current capacity.")
	} else {
		fmt.Printf("❌ Initial system is INFEASIBLE. One or more capacity bottlenecks identified (stopped at first failure):\n")
		printLimit := 10
		if len(overloads) < printLimit {
			printLimit = len(overloads)
		}
		fmt.Printf("Displaying first %d bottlenecks:\n", printLimit)
		for i := 0; i < printLimit; i++ {
			o := overloads[i]
			fmt.Printf("    → %s: %s on %s (Bag: %s, Order: %s)\n", o.Factory, o.Process, o.Date.Format("02/01/2006"), o.BagNo, o.OrderNo)
		}
	}

	// 3. Strategy B: Keep all orders and improve feasibility
	engine.ImproveFeasibility(orders, factoryMaster)
}
