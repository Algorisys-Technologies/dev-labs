# Excel MRP & Gram Transformation Automation

## Overview

This Python script (`MRP Master Formate final.py`) processes a raw Excel file containing multi-year MRP (Maximum Retail Price) and Gram data, cleans irregular formatting, handles discontinued SKUs, normalizes month values, creates a complete timeline, forward-fills values, and exports a structured pivoted Excel file.

The final output is a clean Year × Month structured dataset for both:
- **Gram** (weight measurements)
- **MRP** (Maximum Retail Price)

---

## Key Features

- ✅ Cleans messy Excel structure (no headers expected)
- ✅ Removes media pointer rows (`[media...`) and empty rows
- ✅ Dynamically detects year columns (pattern: 20XX)
- ✅ Handles "Discontinued" SKUs intelligently (detects misspellings)
- ✅ Expands N/A month values when valid data exists
- ✅ Creates complete timeline grid for all PPG-Year-Month combinations
- ✅ Forward-fills missing values chronologically within PPG-Measure groups
- ✅ Outputs structured pivot format with months as columns
- ✅ Exports clean Excel file (.xlsx)

---

## Requirements

Install required packages:

```bash
pip install pandas numpy openpyxl
```

**Recommended Python Version:** Python 3.8+

---

## Input File Expectations

The input Excel file:
- **Does NOT require headers** (script reads raw structure)
- **Row 1** contains year values like `2024`, `2025`, etc.
- **Row 2+** contains data rows
- **Column structure**: `Category | PPG_code | SKU_name | Year-wise Month | grams | MRP | etc.`

**Note:** The script dynamically detects the **first 3 years** found in the header row.

---

## Processing Steps

1. **Clean raw Excel** - Remove rows starting with `[media` and empty rows
2. **Detect available years** - Extract years matching pattern `20[2-9][0-9]`
3. **Build structured column schema** - Dynamically create column names based on detected years
4. **Forward fill Category and PPG_code** - Propagate values down for grouped data
5. **Handle Discontinued SKUs:**
   - Detects patterns: `discontinu` or `dicontinu` (case-insensitive)
   - Identifies first discontinued year per PPG
   - Removes all data from that year onward
6. **Normalize month values** - Standardize to 3-letter format (Jan, Feb, Mar, etc.)
7. **Expand N/A months** - When Month is N/A but value exists, expand to all 12 months
8. **Create full PPG × Year × Month grid** - Ensure complete timeline coverage
9. **Forward fill values chronologically** - Fill missing values within each PPG-Measure group
10. **Pivot into wide format** - Transform long format to wide with months as columns
11. **Export final structured Excel** - Save to output file

---

## Output Format

**Final columns:**

```
PPG | Year | Measure | Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec
```

**Where:**
- `Measure` = "Gram" or "MRP"
- Values are forward-filled across timeline
- Discontinued years are excluded
- Empty values filled with empty string

---

## Discontinued Handling Logic

If a SKU is marked discontinued in a specific year:
- ❌ That year and all future years are **removed**
- ❌ Discontinued rows are **excluded** from final output
- ✅ Only pre-discontinuation data is retained

**Detection patterns:** `discontinu`, `dicontinu` (case-insensitive, checks Month, gm, and MRP columns)

---

## Timeline Logic

The script:
1. Creates complete **Year-Month grid** for all PPG-Measure combinations
2. Converts `Year + Month` into **datetime** format for proper sorting
3. Sorts **chronologically** within each PPG-Measure group
4. **Forward fills** values within each group to ensure continuity

This ensures **consistent time-series continuity** across all products.

---

## How to Run

```bash
python "MRP Master Formate final.py"
```

**Default file names** (hardcoded in script):
- **Input:** `MRP_Master_Formate.xlsx`
- **Output:** `output_data.xlsx`

**To customize:** Edit lines 234-235 in the script:
```python
input_excel = "your_input_file.xlsx"
output_excel = "your_output_file.xlsx"
```

---

## Function Reference

### `transform_excel_data(input_file_path, output_file_path)`

**Parameters:**
- `input_file_path` (str): Path to input Excel file
- `output_file_path` (str): Path to output Excel file

**Returns:**
- `pandas.DataFrame`: The transformed pivot DataFrame

**Raises:**
- `ValueError`: If no valid data found after cleaning

---

## Recommended Improvements

- 🔧 Move file paths to **config file** or **environment variables**
- 📝 Add **logging** (replace print statements)
- ✅ Add **validation checks** (file existence, data quality)
- 🖥️ Add **CLI arguments** for input/output paths
- 🧪 Add **automated testing** (unit tests for edge cases)
- 📊 Add **data quality reports** (summary statistics)

---

## Business Purpose

**Used for:**
- 🧹 Cleaning raw MRP master files from various sources
- 📊 Standardizing time-series data for consistent reporting
- 📈 Preparing structured datasets for analytics and BI tools
- ✅ Ensuring consistency across SKU lifecycle management
- 🔄 Automating manual Excel transformation workflows

---

## Error Handling

The script includes basic error handling:
- Raises `ValueError` if no valid data found after cleaning
- Uses `pd.to_numeric(..., errors='coerce')` for safe type conversion
- Handles missing values with `fillna()` and forward-fill logic

---

**Maintainer:** Data Automation Team  
**Last Updated:** 2026-02-05  
**Script Version:** Final
