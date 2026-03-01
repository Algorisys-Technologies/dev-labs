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

	// 2. Initial feasibility check (Comprehensive Analysis)
	fmt.Println("🔍 [STEP 1] Performing holistic feasibility analysis across all processes and dates...")
	ok, overloads := engine.CheckFeasibility(orders, factoryMaster)
	if ok {
		fmt.Println("✅ All orders are FEASIBLE with current capacity.")
	} else {
		fmt.Printf("❌ Initial system is INFEASIBLE. Identified %d specific capacity bottlenecks:\n", len(overloads))
		printLimit := 15
		if len(overloads) < printLimit {
			printLimit = len(overloads)
		}
		for i := 0; i < printLimit; i++ {
			o := overloads[i]
			fmt.Printf("    → %-20s [%-12s] on %10s: Add %6.2f mins (Bag: %s, Order: %s)\n",
				o.Factory, o.Process, o.Date.Format("02/01/2006"), o.Deficit, o.BagNo, o.OrderNo)
		}
		if len(overloads) > printLimit {
			fmt.Printf("    ... and %d more bottlenecks.\n", len(overloads)-printLimit)
		}
	}

	// 3. Strategy B: Keep all orders and improve feasibility
	// engine.ImproveFeasibility(orders, factoryMaster)
}
