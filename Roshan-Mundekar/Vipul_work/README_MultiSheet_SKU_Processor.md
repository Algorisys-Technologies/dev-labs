# Multi-Sheet SKU Monthly Data Processor

## Overview

This Python script (`README_MultiSheet_SKU_Processor.py`) processes a structured Excel file containing multiple channel sheets (GT, MT, Ecom, CSD, Insti, 3P, Export), extracts SKU-level monthly data, maps measures dynamically (Actual, BE, Others), and exports a clean tab-delimited text file.

The script is designed for automation and supports **command-line execution**.

---

## Key Features

- ✅ Processes **7 predefined sheets** (GT, MT, Ecom, CSD, Insti, 3P, Export)
- ✅ Dynamically detects **"Pack Link"** column in row 7
- ✅ Extracts SKU list automatically (stops at "Export" marker)
- ✅ Detects measure types from header row 6
- ✅ Handles three measure types:
  - **Actual** → Jan-Jul (Aug-Dec filled with 0)
  - **BE** → Aug-Dec (Jan-Jul filled with 0)
  - **Other measures** → Jan-Dec (all months)
- ✅ Outputs structured month-wise dataset
- ✅ Comprehensive error logging to `error_log.txt`
- ✅ Supports CLI execution with file path arguments

---

## Required Sheets

The script processes **only these sheets**:

```
GT, MT, Ecom, CSD, Insti, 3P, Export
```

**Note:** If a sheet is missing, it is logged in `error_log.txt` and processing continues with remaining sheets.

---

## Output Structure

**Final Output Columns:**

```
SKU | Sheet | Measure | Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec
```

**Rules:**
- **Actual** → Only Jan-Jul populated (Aug-Dec = 0)
- **BE** → Only Aug-Dec populated (Jan-Jul = 0)
- **Other Measures** → Jan-Dec all populated
- Missing values filled with **0**

---

## File Structure Assumptions

The Excel file must follow this structure:

- **Row 6** → Contains **Measure names** (e.g., "Actual", "BE", etc.)
- **Row 7** → Contains **"Pack Link"** header and month headers (e.g., "Jan'23", "Feb'23")
- **Row 8 onward** → SKU data rows
- Data columns follow measure headers with proper alignment

**Important:** The script searches for "Export" in the Pack Link column to determine the end of data.

---

## How to Run

### Command-Line Usage

```bash
python README_MultiSheet_SKU_Processor.py <input_file_name> <output_file_name>
```

### Example

```bash
python README_MultiSheet_SKU_Processor.py sales_data output_results
```

**File Extension Handling:**
- If no extension provided for input → `.xlsx` automatically added
- If no extension provided for output → `.txt` automatically added

**Actual files used:**
- Input: `model_upload/sales_data.xlsx`
- Output: `model_upload/output_results.txt`

---

## Folder Structure Requirement

**All input and output files must be inside:**

```
model_upload/
```

**Example structure:**

```
project/
├── README_MultiSheet_SKU_Processor.py
├── model_upload/
│   ├── input_file.xlsx
│   └── output_data.txt
└── error_log.txt
```

---

## Error Handling

All errors are logged to:

```
error_log.txt
```

**Possible logged errors:**
- ❌ Missing sheet (e.g., "Sheet 'GT' not found in file")
- ❌ Missing "Pack Link" column
- ❌ Empty measures row (row 6)
- ❌ File not found
- ❌ Sheet processing errors (with exception details)

**Error logging is non-blocking** - the script continues processing remaining sheets even if one fails.

---

## Measure Processing Logic

### 1. **Actual Measure**
- Extracts **7 columns** starting from measure position
- Maps to **Jan-Jul**
- Sets **Aug-Dec = 0**

### 2. **BE Measure**
- Extracts **5 columns** starting from measure position
- Maps to **Aug-Dec**
- Sets **Jan-Jul = 0**

### 3. **Other Measures**
- Extracts **12 columns** starting from measure position
- Maps to **Jan-Dec** (all months)

---

## Output Format

- **Format:** Tab-delimited (`.txt`)
- **Encoding:** UTF-8
- **Purpose:** Ready for downstream system upload
- **Separator:** `\t` (tab character)

---

## Dependencies

Install required packages:

```bash
pip install pandas openpyxl
```

**Python Version Recommended:** Python 3.8+

---

## Business Purpose

**Used for:**
- 📊 Extracting SKU monthly data from multi-channel sales reports
- 📁 Preparing structured upload files for ERP/analytics systems
- 🔄 Standardizing multi-channel reporting formats
- ⚡ Automating Excel-to-text transformation workflows
- 📈 Consolidating data from multiple sales channels (GT, MT, Ecom, etc.)

---

## Function Reference

### `process_excel(file_path, output_path)`

**Parameters:**
- `file_path` (str): Full path to input Excel file
- `output_path` (str): Full path to output text file

**Returns:** None (saves file to disk)

**Side Effects:**
- Creates/appends to `error_log.txt`
- Saves tab-delimited output file

### `log_error(message)`

**Parameters:**
- `message` (str): Error message to log

**Returns:** None

**Side Effects:**
- Appends message to `error_log.txt`

---

## Troubleshooting

### Issue: "Sheet not found"
**Solution:** Ensure Excel file contains all required sheets (GT, MT, Ecom, CSD, Insti, 3P, Export)

### Issue: "No 'Pack Link' column found"
**Solution:** Verify row 7 contains "Pack Link" text in one of the columns

### Issue: "File does not exist"
**Solution:** Ensure input file is in `model_upload/` folder with correct extension

### Issue: "Measures row is empty"
**Solution:** Verify row 6 contains measure names

---

**Maintainer:** Data Processing Automation Team  
**Last Updated:** 2026-02-05  
**Script Version:** Production
