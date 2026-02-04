# Year Split Excel Data Processor

## Overview

This Python script processes Excel sheets that follow the naming
pattern:

YYYY Split (Example: 2025 Split, 2024 Split)

It extracts Product Link--level financial data, processes table values
dynamically, and exports a structured tab-delimited (.txt) file for
downstream use.

The script supports command-line execution and logs all errors with
timestamps.

------------------------------------------------------------------------

## Key Features

-   Automatically detects sheets matching pattern: \^YYYY Split\$
-   Dynamically locates "Product Link" column
-   Extracts year from sheet name
-   Handles dynamic table structures
-   Stops extraction at "Export" row
-   Logs timestamped errors
-   Outputs clean tab-delimited text file
-   CLI-based automation support

------------------------------------------------------------------------

## Expected Sheet Structure

Each sheet must:

-   Be named like: 2025 Split
-   Row 0 → Contains measure/table names
-   Row 1 → Contains "Product Link"
-   Row 2 onward → Product-level data
-   Contain an "Export" row (optional; used as stopping marker)

------------------------------------------------------------------------

## Output Structure

Final Output Columns:

Product Link Year Table GIS GS Disc. PA RD&A NS Disc. PA RD&A TOT BTL

(Note: One unused blank column is removed automatically.)

------------------------------------------------------------------------

## Processing Logic

1.  Identify sheets matching YYYY Split pattern.
2.  Locate "Product Link" column dynamically.
3.  Extract Product Link list.
4.  Loop through table headers in row 0.
5.  Skip base comparison tables:
    -   Jan'23 to Feb'24 Base
    -   Jan'22 to Jan'23 Base
6.  Extract 11 related columns per measure.
7.  Stop extraction at "Export" row if present.
8.  Append structured rows to final dataset.
9.  Remove extra blank column.
10. Export as tab-delimited text file.

------------------------------------------------------------------------

## How to Run

python app.py `<input_file_name>`{=html} `<output_file_name>`{=html}

Example:

python app.py input_file output_data

If extension not provided: - .xlsx automatically added to input - .txt
automatically added to output

------------------------------------------------------------------------

## Required Folder Structure

Files must exist inside:

model_upload/

Example:

model_upload/input_file.xlsx model_upload/output_data.txt

------------------------------------------------------------------------

## Error Handling

All errors are logged to:

error_log.txt

Errors include: - Missing sheet - Missing "Product Link" column - Sheet
processing failure - File not found - Export issues

Each log entry contains a timestamp.

------------------------------------------------------------------------

## Output Format

-   Tab-delimited (.txt)
-   UTF-8 encoding
-   Structured for downstream system upload

------------------------------------------------------------------------

## Dependencies

Install required packages:

pip install pandas openpyxl

Python Version Recommended: Python 3.8+

------------------------------------------------------------------------

## Business Purpose

Used for: - Processing Year Split financial tables - Extracting
product-level financial metrics - Automating structured uploads -
Standardizing multi-year financial reporting

------------------------------------------------------------------------

Maintainer: Financial Data Automation Script
