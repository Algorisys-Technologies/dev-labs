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

	// Check initial feasibility
	fmt.Println("🔍  Checking initial feasibility...")
	ok, overloads := engine.CheckFeasibility(orders, factoryMaster)
	if ok {
		fmt.Println("✅  All orders are FEASIBLE")
		return
	} else {
		fmt.Println("❌  Orders are infeasible:")
		for _, o := range overloads {
			fmt.Printf("    → %s: %s on %s\n", o.Factory, o.Process, o.Date.Format("02/01/2006"))
		}
	}

	// Try to improve feasibility
	ok = engine.ImproveFeasibility(orders, factoryMaster, overloads)
	if ok {
		fmt.Println("🎉  Feasibility restored")
	} else {
		fmt.Println("💥  Could not restore feasibility")
	}
}
