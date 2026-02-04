# Multi-Sheet SKU Monthly Data Processor

## Overview

This Python script processes a structured Excel file containing multiple
channel sheets (GT, MT, Ecom, CSD, Insti, 3P, Export), extracts
SKU-level monthly data, maps measures dynamically (Actual, BE, Others),
and exports a clean tab-delimited text file.

The script is designed for automation and supports command-line
execution.

------------------------------------------------------------------------

## Key Features

-   Processes multiple predefined sheets
-   Dynamically detects "Pack Link" column
-   Extracts SKU list automatically
-   Detects measure types from header rows
-   Handles:
    -   Actual (Jan--Jul)
    -   BE (Aug--Dec)
    -   Other measures (Jan--Dec)
-   Outputs structured month-wise dataset
-   Logs errors to error_log.txt
-   Supports CLI execution

------------------------------------------------------------------------

## Required Sheets

The script processes only these sheets:

GT MT Ecom CSD Insti 3P Export

If a sheet is missing, it is logged in error_log.txt.

------------------------------------------------------------------------

## Output Structure

Final Output Columns:

SKU \| Sheet \| Measure \| Jan \| Feb \| Mar \| Apr \| May \| Jun \| Jul
\| Aug \| Sep \| Oct \| Nov \| Dec

Rules: - Actual → Only Jan--Jul populated - BE → Only Aug--Dec
populated - Other Measures → Jan--Dec populated - Missing values filled
with 0

------------------------------------------------------------------------

## File Structure Assumptions

-   Row 7 contains "Pack Link"
-   Row 6 contains Measure names
-   Row 7 contains month headers (e.g., Jan'23)
-   SKU list starts from row 8 onward
-   Data columns follow measure headers

------------------------------------------------------------------------

## How to Run

python app.py `<input_file_name>`{=html} `<output_file_name>`{=html}

Example:

python app.py input_file output_data

If extension not provided: - .xlsx automatically added to input - .txt
automatically added to output

------------------------------------------------------------------------

## Folder Structure Requirement

Input and Output files must be inside:

model_upload/

Example:

model_upload/input_file.xlsx model_upload/output_data.txt

------------------------------------------------------------------------

## Error Handling

All errors are logged to:

error_log.txt

Possible logged errors: - Missing sheet - Missing "Pack Link" column -
Missing measure row - File not found - Sheet processing errors

------------------------------------------------------------------------

## Output Format

-   Tab-delimited (.txt)
-   UTF-8 encoding
-   Ready for downstream system upload

------------------------------------------------------------------------

## Business Purpose

Used for: - Extracting SKU monthly data - Preparing structured upload
files - Standardizing multi-channel reporting - Automating Excel-to-text
transformation

------------------------------------------------------------------------

## Dependencies

Install required packages:

pip install pandas openpyxl

Python Version Recommended: Python 3.8+

------------------------------------------------------------------------

Maintainer: Data Processing Automation Script
