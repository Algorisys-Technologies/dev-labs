package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"cubecalc-go-master/pkg/cubecalc"
	"tm1go/pkg/services"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: cubecalc --method <method> --tm1_source <source> ...")
		os.Exit(1)
	}

	params := make(map[string]string)
	for i := 1; i < len(os.Args)-1; i += 2 {
		key := strings.TrimPrefix(os.Args[i], "--")
		params[key] = os.Args[i+1]
	}

	methodName := params["method"]
	if methodName == "" {
		log.Fatal("Parameter 'method' is required")
	}

	start := time.Now()
	log.Printf("CubeCalc starts. Method: %s, Parameters: %v", methodName, params)

	calculator := cubecalc.NewCubeCalc()

	// Setup connections - in a real app these would come from config or env
	tm1Service, err := services.NewTM1ServiceFromEnv()
	if err != nil {
		log.Printf("Warning: Failed to initialize TM1 service from env: %v", err)
	} else {
		// Use the source name from params as key
		source := params["tm1_source"]
		if source == "" {
			source = "default"
		}
		calculator.AddService(source, tm1Service)

		target := params["tm1_target"]
		if target != "" && target != source {
			calculator.AddService(target, tm1Service) // Assuming same for now
		}
	}

	success, err := calculator.Execute(methodName, params)
	if err != nil {
		log.Fatalf("Execution failed: %v", err)
	}

	elapsed := time.Since(start)
	if success {
		log.Printf("CubeCalc finished successfully in %v", elapsed)
	} else {
		log.Printf("CubeCalc failed in %v", elapsed)
		os.Exit(1)
	}
}
