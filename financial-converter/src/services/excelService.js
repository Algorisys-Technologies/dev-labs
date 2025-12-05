const ExcelJS = require("exceljs");
const PeriodMapper = require("../utils/periodMapper");
const DataProcessor = require("../utils/dataProcessor");

class ExcelService {
  static async generateExcel(jsonData) {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Financial Statement");

    // Set column widths
    worksheet.columns = [
      { header: "A", key: "A", width: 60 },
      { header: "B", key: "B", width: 15 },
      { header: "C", key: "C", width: 15 },
      { header: "D", key: "D", width: 15 },
      { header: "E", key: "E", width: 15 },
      { header: "F", key: "F", width: 15 },
      { header: "G", key: "G", width: 15 },
      { header: "H", key: "H", width: 15 },
      { header: "I", key: "I", width: 15 },
      { header: "J", key: "J", width: 15 },
      { header: "K", key: "K", width: 15 },
      { header: "L", key: "L", width: 15 },
    ];

    // Process data
    const processedData = DataProcessor.processFinancialData(jsonData);

    // Apply data to worksheet
    processedData.forEach((item) => {
      const row = worksheet.getRow(item.row);

      Object.keys(item.data).forEach((cellAddress) => {
        const cell = worksheet.getCell(cellAddress);
        cell.value = item.data[cellAddress];

        // Apply styling based on cell content
        this.applyCellStyling(cell, cellAddress, item.row);
      });
    });

    // Merge cells for company name (B1:L1)
    worksheet.mergeCells("B1:L1");
    const companyCell = worksheet.getCell("B1");
    companyCell.value = jsonData.company_name || "Company Name";
    companyCell.font = { bold: true, size: 16 };
    companyCell.alignment = { horizontal: "center", vertical: "middle" };

    // Apply borders
    this.applyBorders(worksheet);

    return workbook;
  }

  static applyCellStyling(cell, cellAddress, rowNum) {
    // Style for headers (rows 1-3)
    if (rowNum <= 3) {
      cell.font = { bold: true };
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFE0E0E0" },
      };
      cell.alignment = { horizontal: "center", vertical: "middle" };
    }

    // Style for section headers
    if (
      (cell.value && cell.value.toString().startsWith("I.")) ||
      (cell.value && cell.value.toString().startsWith("II.")) ||
      (cell.value && cell.value.toString().startsWith("III.")) ||
      (cell.value && cell.value.toString().startsWith("IV.")) ||
      (cell.value && cell.value.toString().startsWith("V.")) ||
      (cell.value && cell.value.toString().startsWith("VI.")) ||
      (cell.value && cell.value.toString().startsWith("VII."))
    ) {
      cell.font = { bold: true };
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFF0F0F0" },
      };
    }

    // Style for totals
    if (
      cell.value &&
      (cell.value.toString().includes("Total") ||
        cell.value.toString().includes("Profit for the year") ||
        cell.value.toString().includes("Profit before tax"))
    ) {
      cell.font = { bold: true };
      cell.border = {
        top: { style: "thin" },
        bottom: { style: "double" },
      };
    }

    // Right align numbers
    if (cellAddress[0] !== "A" && rowNum > 3) {
      cell.alignment = { horizontal: "right" };
    }
  }

  static applyBorders(worksheet) {
    // Apply borders to all cells
    for (let row = 1; row <= 47; row++) {
      const worksheetRow = worksheet.getRow(row);
      worksheetRow.eachCell((cell) => {
        if (!cell.border) {
          cell.border = {
            left: { style: "thin" },
            right: { style: "thin" },
            top: { style: "thin" },
            bottom: { style: "thin" },
          };
        }
      });
    }
  }

  static async writeToBuffer(workbook) {
    return await workbook.xlsx.writeBuffer();
  }
}

module.exports = ExcelService;
