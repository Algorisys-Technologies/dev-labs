# intergold-preoptimization-cleanup

CLI tool that reads an input CSV, performs row-by-row preoptimization cleanup, and writes an optimized CSV.

It streams the input file so large CSVs can be processed without loading the entire file into memory.

## Behavior

- Reads a CSV header plus data rows.
- Writes an output CSV that contains all input columns in the same order, and appends one extra trailing column: `Remarks` (by default).
- If bloc scheduling configuration is available via environment variables (and the process-map can be loaded), the tool updates bloc/process completion date columns and writes a per-row `Remarks` summary.
- If scheduling configuration or the process-map cannot be loaded, the tool falls back to placeholder behavior: it writes empty `Remarks` and does not modify process completion dates.
- If the input CSV already contains a `Remarks` column, the tool still appends a new trailing `Remarks` column (so you will end up with two columns).

### Scheduling rules (when config + process map are valid)

- Business days are Monday through Saturday (Sunday is non-business). Configured holidays are also non-business.
- Dates are parsed as `dd-mm-yyyy`; `01-01-1900` (and out-of-window years via `NULL_DATE_YEAR_WINDOW_X`) are treated as invalid/sentinel and skipped.
- The bloc code (`Bloc` column) is mapped to a start process column via `preoptimization_process_map.csv` (or a path you pass with `-process-map`).
- Process columns are scanned from the mapped start column through `LAST_BLOC_PROCESS_COL_INDEX` (bounded by `FIRST_BLOC_PROCESS_COL_INDEX`).
- If `ProdEndDt < CurrentDate`:
  - Only bloc `RPOL` is updated (mapped start column set to `CurrentDate` as a business day; if `CurrentDate` falls on Sunday or a holiday, it rolls forward to the next business day).
  - Other blocs trigger an **extension-needed** flow (see “4-day buffer extension flow” below).
- If `ProdEndDt >= CurrentDate`:
  - Iterate process columns in order.
  - For each valid process date:
    - If `processDate >= CurrentDate`, stop scanning (leave this and later process columns unchanged).
    - If `processDate < CurrentDate`, update it:
      - First updated column becomes `CurrentDate` as a business day (Sunday/holidays roll forward).
      - Next updated columns keep at least a `+1` business-day gap from the previous updated date.
      - Exception: `Filing -> PrePolish` is allowed on the same updated date (no forced +1 gap).
      - If previous and current original process dates were equal, their updated values are kept equal.
- After updates, if the final updated date exceeds `ProdEndDt`, the row triggers an **extension-needed** flow (see “4-day buffer extension flow” below).

### 4-day buffer extension flow

When a row is determined to require an extension, the tool applies a **4-day buffer** to `ProdEndDt` and re-evaluates using the usual scheduling logic.

- If scheduling fits within the buffered `ProdEndDt`:
  - **Keep** the updated process dates.
  - **Keep** the buffered `ProdEndDt` value in the output.
  - `Remarks` ends with: `4 day buffer used` and lists the updated column names, e.g. `Updated: ZCAD,ZCAM,PrePolish; 4 day buffer used`.
- If scheduling still does not fit even after the buffer:
  - **Undo** all process-date changes (restore the original process dates).
  - **Keep** the buffered `ProdEndDt` value in the output.
  - `Remarks`: `No changes made; extension needed, 4 day buffer used`.

## Prerequisites

- Go 1.22 or later

## Build

```bash
go build -o bin/intergold-preoptimization-cleanup ./cmd/app
```

## Run

Defaults (when flags are omitted):

- input CSV path defaults to `ppc-data.csv`
- process map defaults to `preoptimization_process_map.csv`
- holiday list defaults to `Holiday_master.csv`
- output path behavior is unchanged: it is derived from the input (e.g. `data.csv` becomes `data_preoptimization_cleanup.csv`)

Optional:

- output path via `-output` or `-o` (default: derived from the input, e.g. `data.csv` becomes `data_preoptimization_cleanup.csv`)
- process map via `-process-map` (default: `preoptimization_process_map.csv`)
- holiday list via `-holiday-master` (default: `Holiday_master.csv`). That file must exist; there is no secondary search path. If it is missing, the CLI exits with an error (same as a missing process map).
- dotenv path via `-env-file` (default: `.env`)

Process map and holiday **file paths** are only chosen via those flags or their defaults; they are **not** read from environment variables or `.env`.

If `-output` is omitted, the output file is derived from the input (e.g. `data.csv` becomes `data_preoptimization_cleanup.csv`).

```bash
go run ./cmd/app -input /path/to/data.csv
go run ./cmd/app -input /path/to/data.csv -process-map /path/to/preoptimization_process_map.csv
go run ./cmd/app -input /path/to/data.csv -output /path/to/out.csv
go run ./cmd/app -input /path/to/data.csv -holiday-master /path/to/holiday_master.csv -env-file /path/to/custom.env
```

Or using the binary:

```bash
./bin/intergold-preoptimization-cleanup -input /path/to/data.csv
./bin/intergold-preoptimization-cleanup -i /path/to/data.csv -process-map /path/to/preoptimization_process_map.csv -o /path/to/out.csv
./bin/intergold-preoptimization-cleanup -i /path/to/data.csv -env-file /path/to/custom.env
```

## Logging

File logging is off by default. Set `ENABLE_LOGGING` to `true`, `1`, `yes`, or `on` to enable it.

When enabled, a log file `intergold-preoptimization-cleanup.log` is created in the same directory as the output CSV (or the current working directory if the output path is not set). Each run records input/output paths and row counts.

Row counts are data rows only; the header line in each file is not counted.

## Configuration

Configuration is read from environment variables. The CLI auto-loads `.env` by default; use `-env-file` to load a different dotenv path. (Process map and holiday CSV locations are **not** configured via env; use `-process-map` / `-holiday-master` or their defaults.)

Supported configuration:

- `REMARKS_COLUMN_NAME` – name of the appended `Remarks` column in the output CSV (default: `Remarks`)
- `PROD_END_DT_COL_INDEX` – column index in the input CSV for `ProdEndDt` (0-based numeric index, or Excel column letters like `AA`)
- `BLOC_COL_INDEX` – column index in the input CSV for `Bloc` (0-based numeric index, or Excel column letters like `AA`)
- `FIRST_BLOC_PROCESS_COL_INDEX` – first process completion date column to scan (inclusive) (0-based numeric index, or Excel column letters like `AA`)
- `LAST_BLOC_PROCESS_COL_INDEX` – last process completion date column to scan (inclusive) (0-based numeric index, or Excel column letters like `AA`)
- `NULL_DATE_YEAR_WINDOW_X` – year window X used to treat process dates as valid only within `[CurrentYear-X, CurrentYear+X]` (default: `5`)
- `REMARKS_EXTENSION_NEEDED` – text written into `Remarks` when an extension is needed (default: `extension needed`)
- `PROCESS_MAP_KEY_COL_INDEX` – column index for the process code in the process-map CSV (default: `A` / `0`); numeric or Excel-style letters like other `*_COL_INDEX` settings
- `PROCESS_MAP_VALUE_COL_INDEX` – column index for the mapped value(s) in the process-map CSV (default: `B` / `1`; must differ from the key index)
- `HOLIDAYS_KEY_COL_INDEX` – column index for the holiday **date** in `holiday_master.csv` (default: `A` / `0`); numeric or Excel letters like other `*_COL_INDEX` settings
- `HOLIDAYS_VALUE_COL_INDEX` – column index for a non-empty **label** on each row (default: `B` / `1`); must differ from the key index. Holiday dates may be `dd-mm-yyyy` or `dd-mm-yy`.
- `ENABLE_LOGGING` – set to `true`, `1`, `yes`, or `on` to enable file logging (default: disabled)

See `.env.example` for the full list of configuration variables.

## Project layout

- `cmd/app` – CLI entrypoint; parses `-input`/`-output` and invokes cleanup
- `internal/config` – input path validation (exists, not a directory)
- `internal/csv_stream` – CSV row-by-row streaming reader and writer
- `internal/cleanup` – cleanup engine (bloc process scheduling, date updates, undo checks, and `Remarks` generation)

## Test

```bash
go test ./...
```
