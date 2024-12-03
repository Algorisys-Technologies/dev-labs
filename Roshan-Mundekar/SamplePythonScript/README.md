<<<<<<< HEAD
# Python CSV/XLSX Reader Console Application

This project demonstrates how to create a standalone executable (`.exe`) for a Python console application that reads a CSV or Excel (`.xlsx`) file provided via the command line. The executable runs on a Windows machine without requiring Python to be installed.

## Features

- Reads a CSV or Excel (`.xlsx`) file passed as a command-line argument.
- Prints the content of the file in the terminal.
- Built with Python and packaged into a standalone `.exe` using `PyInstaller`.

## Prerequisites

- **Development Machine:**
  - Windows OS
  - Python (for creating the `.exe`)
  - `PyInstaller` and `openpyxl` installed as dependencies.
- **Target Machine:**
  - Windows OS (no Python installation required).

## Getting Started

### Step 1: Clone the Repository

```bash
git clone https://github.com/Algorisys-Technologies/dev-labs/tree/main/Roshan-Mundekar/SamplePythonScript
cd SamplePythonScript

```bash
pip install pyinstaller openpyxl

```bash
pyinstaller --onefile read_csv.py

```bash
read_csv.exe a.xlsx
=======

>>>>>>> 
