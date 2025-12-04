const { Parser } = require("json2csv");
const PeriodMapper = require("../utils/periodMapper");
const DataProcessor = require("../utils/dataProcessor");

class CSVService {
  static generateCSV(jsonData) {
    const processedData = DataProcessor.processFinancialData(jsonData);

    // Convert to flat array for CSV
    const csvData = [];
    const headers = [
      "Row",
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H",
      "I",
      "J",
      "K",
      "L",
    ];

    // Add headers
    csvData.push(headers.join(","));

    // Add data rows
    for (let rowNum = 1; rowNum <= 47; rowNum++) {
      const rowData = processedData.find((d) => d.row === rowNum);
      const row = [rowNum];

      for (let col = "A".charCodeAt(0); col <= "L".charCodeAt(0); col++) {
        const colLetter = String.fromCharCode(col);
        const cellAddress = `${colLetter}${rowNum}`;
        const cellValue =
          rowData && rowData.data[cellAddress]
            ? this.formatCSVValue(rowData.data[cellAddress])
            : "";
        row.push(cellValue);
      }

      csvData.push(row.join(","));
    }

    return csvData.join("\n");
  }

  static formatCSVValue(value) {
    if (value === null || value === undefined) return "";

    // Escape quotes and wrap in quotes if contains comma
    const stringValue = String(value);
    if (stringValue.includes(",") || stringValue.includes('"')) {
      return `"${stringValue.replace(/"/g, '""')}"`;
    }

    return stringValue;
  }

  static generateFormattedCSV(jsonData) {
    // Alternative format that matches Excel layout
    const processedData = DataProcessor.processFinancialData(jsonData);

    // Create a 2D array representing the spreadsheet
    const grid = Array(47)
      .fill()
      .map(() => Array(12).fill(""));

    // Fill the grid
    processedData.forEach((item) => {
      Object.keys(item.data).forEach((cellAddress) => {
        const col = cellAddress.charCodeAt(0) - 65; // A=0, B=1, etc.
        const row = parseInt(cellAddress.slice(1)) - 1; // Convert to 0-based

        if (row >= 0 && row < 47 && col >= 0 && col < 12) {
          grid[row][col] = item.data[cellAddress];
        }
      });
    });

    // Convert to CSV
    const csvRows = [];
    grid.forEach((row) => {
      csvRows.push(row.map((cell) => this.formatCSVValue(cell)).join(","));
    });

    return csvRows.join("\n");
  }
}

module.exports = CSVService;
