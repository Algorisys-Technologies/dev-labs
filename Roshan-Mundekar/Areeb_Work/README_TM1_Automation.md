# TM1 MDX Data Extraction & CSV Automation

## Overview

This Python script connects to IBM Planning Analytics (TM1), executes an
MDX query on the `Category_cashup` cube, transforms the data into a
pivot format, and exports the final output to a CSV file.

Features: - Logging (file + console) - Execution time tracking - Error
handling - Automatic pivot transformation - Structured CSV export

------------------------------------------------------------------------

## Architecture Flow

TM1 Connection ↓ Execute MDX Query ↓ Load Data into DataFrame ↓ Pivot
Transformation ↓ Export to CSV ↓ Log Completion

------------------------------------------------------------------------

## Requirements

Install required Python packages:

pip install pandas TM1py

Recommended Python Version: Python 3.8+

------------------------------------------------------------------------

## TM1 Connection Details

The script connects using: - Base URL: IBM Planning Analytics Cloud -
Authentication: LDAP - SSL Enabled - Async Requests Mode Enabled

Important: Credentials are currently hardcoded. For production use, move
them to: - .env file - Environment variables - Secure vault

------------------------------------------------------------------------

## MDX Query Details

Cube Used: Category_cashup

Dimensions Used:

Columns (Axis 0): - Month → Forecast_Months (public subset) -
Basepack_Final → N_Level (public subset) - Channels → Level 1 filtered

Rows (Axis 1): - Cashup_m → Trading_Trends (public subset)

Filters (WHERE clause): - Data_Source → Trading Trend - Version → CV -
State → All India - Elist → Elist - Year → Current_Year

------------------------------------------------------------------------

## Data Transformation

Columns renamed to: Cashup_M Month Basepack_Final Channels Value

Pivot Configuration: Index: Month, Basepack_Final, Channels Columns:
Cashup_M Values: Value Missing values filled with 0

------------------------------------------------------------------------

## Output File

File Name: BasepackxChannel_Automation_TrT\_&\_BP_Fin.csv

Formatting: - UTF-8 with BOM encoding - 8 empty lines at top - No index
column - Clean pivoted structure

------------------------------------------------------------------------

## Logging

Log file format: script_log_YYYYMMDD_HHMMSS.log

Logs include: - Connection status - MDX execution time - Pivot creation
status - CSV export time - Errors (if any)

------------------------------------------------------------------------

## How to Run

python script_name.py

After execution: - CSV file will be created in the same directory - Log
file will be generated

------------------------------------------------------------------------

## Recommended Improvements

-   Move credentials to environment variables
-   Add configuration file (config.json)
-   Add retry logic
-   Add email notification
-   Add dynamic file naming

------------------------------------------------------------------------

## Business Purpose

Automates extraction of Trading Trend data from TM1, transforms it into
Basepack x Channel structure, and exports standardized CSV output for
reporting.

------------------------------------------------------------------------

Maintainer: TM1 Automation Team
