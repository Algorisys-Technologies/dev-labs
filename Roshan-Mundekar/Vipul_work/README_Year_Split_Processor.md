# Year Split Excel Data Processor

## Overview

This Python script (`README_Year_Split_Processor.py`) processes Excel sheets that follow the naming pattern:

```
YYYY Split (e.g., "2025 Split", "2024 Split", "2023 Split")
```

It extracts **Product Link-level** financial data, processes table values dynamically, and exports a structured tab-delimited (`.txt`) file for downstream use.

The script supports **command-line execution** and logs all errors with **timestamps**.

---

## Key Features

- ✅ Automatically detects sheets matching pattern: `^\d{4} Split$` (regex)
- ✅ Dynamically locates **"Product Link"** column in row 1
- ✅ Extracts year from sheet name (first 4 characters)
- ✅ Handles dynamic table structures with multiple measures
- ✅ Stops extraction at **"Export"** row (if present)
- ✅ Timestamped error logging to `error_log.txt`
- ✅ Outputs clean tab-delimited text file
- ✅ CLI-based automation support
- ✅ Skips base comparison tables automatically

---

## Expected Sheet Structure

Each sheet must follow this structure:

- **Sheet Name:** `YYYY Split` (e.g., "2025 Split")
- **Row 0** → Contains **measure/table names**
- **Row 1** → Contains **"Product Link"** header
- **Row 2 onward** → Product-level data rows
- **Optional:** Contains an **"Export"** row (used as stopping marker)

---

## Output Structure

**Final Output Columns:**

```
Product Link | Year | Table | GIS | GS | Disc. | PA | RD&A | NS | Disc. | PA | RD&A | TOT BTL
```

**Note:** One unused blank column (column 9 in original data) is automatically removed during processing.

---

## Processing Logic

1. **Identify sheets** matching `^\d{4} Split$` pattern using regex
2. **Locate "Product Link" column** dynamically in row 1
3. **Extract Product Link list** from column (rows 2 onward)
4. **Append "Total" row** to product list
5. **Loop through table headers** in row 0
6. **Skip base comparison tables:**
   - `Jan'23 to Feb'24 Base`
   - `Jan'22 to Jan'23 Base`
7. **Extract 11 related columns** per measure (starting from measure position)
8. **Stop extraction at "Export" row** if present in Product Link column
9. **Append structured rows** to final dataset with Year extracted from sheet name
10. **Remove extra blank column** (column index 9)
11. **Export as tab-delimited text file**

---

## How to Run

### Command-Line Usage

```bash
python README_Year_Split_Processor.py <input_file_name> <output_file_name>
```

### Example

```bash
python README_Year_Split_Processor.py financial_data yearly_output
```

**File Extension Handling:**
- If no extension provided for input → `.xlsx` automatically added
- If no extension provided for output → `.txt` automatically added

**Actual files used:**
- Input: `model_upload/financial_data.xlsx`
- Output: `model_upload/yearly_output.txt`

---

## Required Folder Structure

**All files must exist inside:**

```
model_upload/
```

**Example structure:**

```
project/
├── README_Year_Split_Processor.py
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

**Error log format:**
```
[2026-02-05 10:53:46] Error message here
```

**Possible logged errors:**
- ❌ Missing sheet matching pattern
- ❌ Missing "Product Link" column in row 1
- ❌ Sheet processing failure (with exception details)
- ❌ File not found
- ❌ Export/save issues

**Each log entry contains a timestamp** for debugging and audit purposes.

---

## Sheet Name Pattern

The script uses **regex pattern** to identify valid sheets:

```python
sheet_pattern = r'^\d{4} Split$'
```

**Valid sheet names:**
- ✅ `2025 Split`
- ✅ `2024 Split`
- ✅ `2023 Split`

**Invalid sheet names:**
- ❌ `2025Split` (missing space)
- ❌ `Split 2025` (wrong order)
- ❌ `25 Split` (only 2 digits)
- ❌ `2025 split` (lowercase 's')

---

## Data Extraction Details

### Columns Extracted Per Measure

For each measure/table in row 0, the script extracts **11 columns**:

1. GIS
2. GS
3. Disc.
4. PA
5. RD&A
6. NS
7. (blank column - removed)
8. Disc.
9. PA
10. RD&A
11. TOT BTL

**Note:** The blank column at position 9 is automatically dropped before export.

### Skipped Measures

The following measures are **automatically skipped**:
- `Jan'23 to Feb'24 Base`
- `Jan'22 to Jan'23 Base`

These are base comparison tables and are excluded from the output.

---

## Output Format

- **Format:** Tab-delimited (`.txt`)
- **Encoding:** UTF-8
- **Separator:** `\t` (tab character)
- **Purpose:** Structured for downstream system upload

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
- 📊 Processing Year Split financial tables from Excel reports
- 💰 Extracting product-level financial metrics (GIS, GS, PA, RD&A, etc.)
- ⚡ Automating structured uploads to financial systems
- 📈 Standardizing multi-year financial reporting
- 🔄 Converting Excel-based financial data to system-ready format

---

## Function Reference

### `process_excel(file_path, output_path)`

**Parameters:**
- `file_path` (str): Full path to input Excel file
- `output_path` (str): Full path to output text file

**Returns:** None (saves file to disk)

**Side Effects:**
- Creates/appends to `error_log.txt` with timestamps
- Saves tab-delimited output file

### `log_error(message)`

**Parameters:**
- `message` (str): Error message to log

**Returns:** None

**Side Effects:**
- Appends timestamped message to `error_log.txt`
- Format: `[YYYY-MM-DD HH:MM:SS] message`

---

## Troubleshooting

### Issue: "No sheets matching pattern found"
**Solution:** Ensure Excel file contains sheets named exactly as `YYYY Split` (e.g., "2025 Split")

### Issue: "No 'Product Link' column found"
**Solution:** Verify row 1 (0-indexed) contains "Product Link" text in one of the columns

### Issue: "File does not exist"
**Solution:** Ensure input file is in `model_upload/` folder with correct extension

### Issue: "Export row not found"
**Solution:** This is not an error - the script processes all rows if "Export" is not present

---

**Maintainer:** Financial Data Automation Team  
**Last Updated:** 2026-02-05  
**Script Version:** Production
