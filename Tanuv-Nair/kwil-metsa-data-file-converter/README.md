# kwil-metsa-data-file-converter

A CLI tool that converts Kwil Metsa data files from `.txt` to `.csv` format. It restructures the header rows by merging month labels (Row 2) into the primary header (Row 1) and outputs a clean, single-header CSV.

## How It Works

The input `.txt` file has a two-row header structure:

- **Row 1**: Dimension column names (`Currency`, `Customer`, …, `DataType`, `Period`)
- **Row 2**: Month names (`Jan`, `Feb`, `Mar`, …, `Dec`)

The converter:

1. Removes the trailing `Period` header from Row 1.
2. Appends all month values from Row 2 into Row 1 (starting at Column L).
3. Deletes Row 2.
4. Writes all rows as a standard CSV file.

**Before (input.txt):**

```
"Currency","Customer",...,"DataType","Period"
"Jan","Feb","Mar",...,"Dec"
"Local_Currency","114342",...,"Base",-88.09,-13.16,...
```

**After (output.csv):**

```
Currency,Customer,...,DataType,Jan,Feb,Mar,...,Dec
Local_Currency,114342,...,Base,-88.09,-13.16,...
```

## Project Structure

```
├── cmd/app/main.go          # CLI entry point
├── internal/
│   ├── config/config.go     # Path normalization & input validation
│   └── converter/converter.go  # Parsing, transformation & CSV writing
├── scripts/build.sh         # Cross-platform build script
├── data/                    # Sample input/output files
├── bin/                     # Compiled binaries
└── go.mod
```

## Prerequisites

- Go 1.25+

## Building

Use the build script to compile for one or more platforms:

```bash
# Interactive prompt
./scripts/build.sh

# Build for a specific platform
./scripts/build.sh -p linux/amd64
./scripts/build.sh -p windows/amd64

# Build for all platforms
./scripts/build.sh -p all
```

Binaries are output to `bin/<os>_<arch>/`.

## Usage

```bash
kwil-metsa-data-file-converter -input <file.txt> [-output <file.csv>]
```

### Flags

| Flag      | Required | Description                                                                 |
|-----------|----------|-----------------------------------------------------------------------------|
| `-input`  | Yes      | Path to the input `.txt` file.                                              |
| `-output` | No       | Path to the output `.csv` file. Defaults to `<input>_kwil_metsa_converted.csv`. |

### Examples

```bash
# Default output path (data/input_kwil_metsa_converted.csv)
./bin/linux_amd64/kwil-metsa-data-file-converter -input "data/input.txt"

# Custom output path
./bin/linux_amd64/kwil-metsa-data-file-converter -input "data/input.txt" -output "results/output.csv"
```
