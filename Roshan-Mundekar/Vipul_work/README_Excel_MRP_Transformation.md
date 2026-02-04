# Excel MRP & Gram Transformation Automation

## Overview

This Python script processes a raw Excel file containing multi-year MRP
and Gram data, cleans irregular formatting, handles discontinued SKUs,
normalizes month values, creates a complete timeline, forward-fills
values, and exports a structured pivoted Excel file.

The final output is a clean Year × Month structured dataset for both: -
Gram - MRP

------------------------------------------------------------------------

## Key Features

-   Cleans messy Excel structure (no headers expected)
-   Removes media rows and empty rows
-   Dynamically detects year columns
-   Handles "Discontinued" SKUs intelligently
-   Expands missing month values when required
-   Creates complete timeline grid
-   Forward-fills missing values chronologically
-   Outputs structured pivot format
-   Exports clean Excel file

------------------------------------------------------------------------

## Requirements

Install required packages:

pip install pandas numpy openpyxl

Recommended Python Version: Python 3.8+

------------------------------------------------------------------------

## Input File Expectations

The input Excel: - Does NOT require headers - Contains year values like
2024, 2025 etc. in first row - Contains columns structured as: Category
\| PPG_code \| SKU_name \| Year-wise Month \| grams \| MRP \| etc.

The script dynamically detects first 3 years found in header row.

------------------------------------------------------------------------

## Processing Steps

1.  Clean raw Excel (remove media and blank rows)
2.  Detect available years
3.  Build structured column schema dynamically
4.  Forward fill Category and PPG_code
5.  Handle Discontinued SKUs:
    -   Detects patterns like "discontinu" or "dicontinu"
    -   Removes all data after first discontinued year
6.  Normalize month values (Jan--Dec)
7.  Expand N/A months where value exists
8.  Create full PPG × Year × Month grid
9.  Forward fill values chronologically
10. Pivot into wide format
11. Export final structured Excel

------------------------------------------------------------------------

## Output Format

Final columns:

PPG \| Year \| Measure \| Jan \| Feb \| Mar \| Apr \| May \| Jun \| Jul
\| Aug \| Sep \| Oct \| Nov \| Dec

Where: - Measure = Gram or MRP - Values are forward-filled across
timeline - Discontinued years excluded

------------------------------------------------------------------------

## Discontinued Handling Logic

If a SKU is marked discontinued in a specific year: - That year and all
future years are removed - Discontinued rows are excluded from final
output

------------------------------------------------------------------------

## Timeline Logic

The script: - Creates complete Year-Month grid - Converts Year + Month
into date format - Sorts chronologically - Forward fills within each
PPG-Measure group

This ensures consistent time-series continuity.

------------------------------------------------------------------------

## How to Run

python script_name.py

Default file names inside script:

Input: MRP_Master_Formate.xlsx

Output: output_data.xlsx

------------------------------------------------------------------------

## Recommended Improvements

-   Move file paths to config file
-   Add logging
-   Add validation checks
-   Add CLI arguments
-   Add automated testing

------------------------------------------------------------------------

## Business Purpose

Used for: - Cleaning raw MRP master files - Standardizing time-series
data - Preparing structured dataset for reporting or analytics -
Ensuring consistency across SKU lifecycle

------------------------------------------------------------------------

Maintainer: Data Automation Script
