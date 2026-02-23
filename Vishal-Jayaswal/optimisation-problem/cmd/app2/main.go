package main

import (
	"fmt"
	"log"

	"optimisation-problem/internal/engine"
	"optimisation-problem/internal/excel"
)

func main() {
	fmt.Println("🧪 Starting Dummy Feasibility Test...")

	// 1. Read Dummy Factory (data2/factory.xlsx)
	factoryMaster, err := excel.ReadDummyFactories("data2/factory.xlsx")
	if err != nil {
		log.Fatalf("❌ Error reading dummy factory: %v", err)
	}

	// 2. Read Dummy Orders (data2/order.xlsx)
	orders, err := excel.ReadDummyOrders("data2/order.xlsx")
	if err != nil {
		log.Fatalf("❌ Error reading dummy orders: %v", err)
	}

	fmt.Printf("📊 Loaded %d factories and %d orders.\n", len(factoryMaster), len(orders))

	// 3. Check Feasibility
	fmt.Println("🔍 Checking feasibility with Slack method (Simple Mode)...")
	ok, overloads := engine.CheckFeasibilitySimple(orders, factoryMaster)

	if ok {
		fmt.Println("✅ TEST PASSED: All dummy orders are FEASIBLE.")
	} else {
		fmt.Println("❌ TEST FAILED: Dummy orders are INFEASIBLE.")
		for _, o := range overloads {
			fmt.Printf("    → %s: %s on %s (Excess: %.2f hrs)\n",
				o.Factory, o.Process, o.Date.Format("02-01-2006"), o.Excess)
		}
	}
}
