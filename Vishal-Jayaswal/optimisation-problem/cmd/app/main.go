package main

import (
	"fmt"
	"log"

	"optimisation-problem/internal/engine"
	"optimisation-problem/internal/excel"
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

	// 1️⃣ Initial Feasibility Check
	fmt.Println("🔍  Checking initial feasibility...")
	ok, overloads := engine.CheckFeasibility(orders, factoryMaster)
	if ok {
		fmt.Println("✅  All orders are FEASIBLE")
		return
	}

	fmt.Println("❌  Orders are infeasible:")
	for _, o := range overloads {
		fmt.Printf("    → %s: %s on %s\n", o.Factory, o.Process, o.Date.Format("02/01/2006"))
	}
	// fmt.Println()

	// // 2️⃣ Attempt to Restore Feasibility
	// fmt.Println("🛠️  Attempting to restore feasibility...")
	// if restored := engine.ImproveFeasibility(orders, factoryMaster, overloads); restored {
	// 	fmt.Println("🎉  Feasibility restored!")
	// } else {
	// 	fmt.Println("💥  Could not restore feasibility.")
	// }
}
