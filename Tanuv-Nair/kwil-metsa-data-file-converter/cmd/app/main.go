package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"kwil-metsa-data-file-converter/internal/config"
	"kwil-metsa-data-file-converter/internal/converter"
)

func main() {
	inputPath := flag.String("input", "", "Path to the input .txt file")
	outputPath := flag.String("output", "", "Path to the output .csv file (optional, defaults to input with .csv extension)")
	flag.Parse()

	if *inputPath == "" {
		fmt.Fprintln(os.Stderr, "Usage: kwil-metsa-data-file-converter -input <file.txt> [-output <file.csv>]")
		os.Exit(1)
	}

	// Strip surrounding quotes / leading-trailing whitespace that some shells
	// or scripts inject, then resolve to a clean absolute path.
	absInput, err := filepath.Abs(config.NormalizePath(*inputPath))
	if err != nil {
		log.Fatalf("invalid input path: %v", err)
	}

	// If output is not provided, derive it from the input filename.
	// e.g. input.txt -> input_kwil_metsa_converted.csv
	output := *outputPath
	if output == "" {
		dir := filepath.Dir(absInput)
		base := filepath.Base(absInput)
		ext := filepath.Ext(base)
		name := base[:len(base)-len(ext)]
		output = filepath.Join(dir, name+"_kwil_metsa_converted.csv")
	}

	absOutput, err := filepath.Abs(config.NormalizePath(output))
	if err != nil {
		log.Fatalf("invalid output path: %v", err)
	}

	if err := config.ValidateInputPath(absInput); err != nil {
		log.Fatalf("input validation failed: %v", err)
	}

	if err := converter.Convert(absInput, absOutput); err != nil {
		log.Fatalf("conversion failed: %v", err)
	}

	fmt.Printf("Converted %q -> %q\n", absInput, absOutput)
}
