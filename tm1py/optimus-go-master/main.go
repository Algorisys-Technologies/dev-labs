package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"optimus-go-master/pkg/optimus"
	"tm1go/pkg/services"
)

func main() {
	var (
		instanceName string
		cubeName     string
		viewName     string
		processName  string
		executions   int
		fast         bool
		output       string
		update       bool
		excludeDims  string
	)

	flag.StringVar(&instanceName, "instance", "", "TM1 instance name (from environment)")
	flag.StringVar(&cubeName, "cube", "", "Cube to optimize")
	flag.StringVar(&viewName, "view", "", "View to benchmark (comma separated)")
	flag.StringVar(&processName, "process", "", "Process to benchmark")
	flag.IntVar(&executions, "executions", 3, "Number of executions per permutation")
	flag.BoolVar(&fast, "fast", false, "Fast mode (less permutations)")
	flag.StringVar(&output, "output", "results", "Output file prefix")
	flag.BoolVar(&update, "update", false, "Update cube with best order found")
	flag.StringVar(&excludeDims, "exclude", "", "Dimensions to exclude from rotation (comma separated)")

	flag.Parse()

	if cubeName == "" {
		fmt.Println("Error: -cube argument is required")
		flag.Usage()
		os.Exit(1)
	}

	// 1. Connect to TM1
	// In tm1go, we use environment variables for connection info
	// We'll assume TM1Service initialization logic similar to TTM1py
	tm1, err := services.NewTM1ServiceFromEnv()
	if err != nil {
		log.Fatalf("Failed to connect to TM1: %v", err)
	}
	defer tm1.Logout()

	// 2. Prepare parameters
	views := strings.Split(viewName, ",")
	excluded := strings.Split(excludeDims, ",")

	cube, err := tm1.Cubes.Get(cubeName)
	if err != nil {
		log.Fatalf("Failed to get cube %s: %v", cubeName, err)
	}

	// 3. Orchestrate optimization
	executor := optimus.NewMainExecutor(tm1, cubeName, views, processName, cube.Dimensions, executions, true, fast, excluded)

	fmt.Printf("Starting optimization for cube: %s\n", cubeName)
	results, err := executor.Execute()
	if err != nil {
		log.Fatalf("Optimization failed: %v", err)
	}

	// 4. Export results
	err = results.ExportToCSV(output + ".csv")
	if err != nil {
		log.Printf("Failed to export CSV: %v", err)
	}
	err = results.ExportToJSON(output + ".json")
	if err != nil {
		log.Printf("Failed to export JSON: %v", err)
	}
	err = results.ExportToXLSX(output + ".xlsx")
	if err != nil {
		log.Printf("Failed to export XLSX: %v", err)
	}

	fmt.Println("Optimization complete. Results exported.")
}
