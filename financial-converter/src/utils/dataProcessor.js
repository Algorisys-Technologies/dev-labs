const PeriodMapper = require("./periodMapper");

class DataProcessor {
  static processFinancialData(jsonData) {
    const result = [];
    const financialData = jsonData.financial_data || [];

    // Create a map of data by key for easy lookup
    const dataMap = {};
    financialData.forEach((item) => {
      dataMap[item.key] = item.values;
    });

    // Row 1: Company Name (merged B1-L1)
    result.push({
      row: 1,
      data: this.createRow1Data(jsonData.company_name),
    });

    // Row 2: Period Headers
    result.push({
      row: 2,
      data: this.createRow2Data(),
    });

    // Row 3: Period Sub-labels
    result.push({
      row: 3,
      data: this.createRow3Data(),
    });

    // Rows 4-47: Financial Data
    let currentRow = 4;
    const rowData = [];

    // I. Revenue from operations
    rowData.push(...this.createRevenueSection(dataMap, currentRow));
    currentRow += rowData.length;

    // II. Other income
    rowData.push(...this.createOtherIncomeSection(dataMap, currentRow));
    currentRow += 2;

    // III. Total Income
    rowData.push(...this.createTotalIncomeSection(dataMap, currentRow));
    currentRow += 4; // Includes growth rows

    // IV. Expenses
    rowData.push(...this.createExpensesSection(dataMap, currentRow));
    currentRow += rowData.length - 14; // Subtract previous rows

    // V. Profit before tax
    rowData.push(...this.createProfitSection(dataMap, currentRow));
    currentRow += 3;

    // VI. Tax expense
    rowData.push(...this.createTaxSection(dataMap, currentRow));
    currentRow += 4;

    // VII. Profit for the year
    rowData.push(...this.createFinalProfitSection(dataMap, currentRow));
    currentRow += 3;

    // EBITDA and Margins
    rowData.push(...this.createEBITDASection(dataMap, currentRow));
    currentRow += 3;

    // Volume and Price Growth
    rowData.push(...this.createGrowthSection(currentRow));

    result.push(...rowData);

    return result;
  }

  static createRow1Data(companyName) {
    const rowData = { A1: companyName || "Company Name" };
    // Cells B1-L1 will be merged and show company name
    return rowData;
  }

  static createRow2Data() {
    const rowData = { A2: "INR Crs" };
    const headers = PeriodMapper.getColumnHeaders();

    headers.forEach((header, index) => {
      const col = String.fromCharCode(66 + index); // B, C, D, etc.
      rowData[`${col}2`] = header;
    });

    return rowData;
  }

  static createRow3Data() {
    const rowData = { A3: "I. Revenue from operations" };
    const subLabels = PeriodMapper.getPeriodSubLabels();
    const headers = PeriodMapper.getColumnHeaders();

    headers.forEach((header, index) => {
      const col = String.fromCharCode(66 + index);
      rowData[`${col}3`] = subLabels[header] || "";
    });

    return rowData;
  }

  static createRevenueSection(dataMap, startRow) {
    const rows = [];
    const headers = PeriodMapper.getColumnHeaders();

    // Row 4: Sale of goods / Income from operations Domestic
    const row4 = {
      [`A${startRow}`]: "Sale of goods / Income from operations Domestic",
    };
    // Check for both sale_of_products and sale_of_goods
    const saleData = dataMap["sale_of_products"] || dataMap["sale_of_goods"];
    this.fillPeriodValues(row4, saleData, startRow);
    rows.push({ row: startRow, data: row4 });

    // Row 5: Sale Exports (not in sample data)
    const row5 = { [`A${startRow + 1}`]: "Sale Exports" };
    rows.push({ row: startRow + 1, data: row5 });

    // Row 6: Revenue from Services (not in sample data)
    const row6 = { [`A${startRow + 2}`]: "Revenue from Services" };
    rows.push({ row: startRow + 2, data: row6 });

    // Row 7: Other operating revenues
    const row7 = { [`A${startRow + 3}`]: "Other operating revenues" };
    this.fillPeriodValues(
      row7,
      dataMap["other_operating_revenues"],
      startRow + 3
    );
    rows.push({ row: startRow + 3, data: row7 });

    // Row 8: Total Revenue (calculate sum or use if available)
    const row8 = { [`A${startRow + 4}`]: "Total Revenue" };
    this.calculateTotalRevenue(row8, dataMap, startRow + 4);
    rows.push({ row: startRow + 4, data: row8 });

    return rows;
  }

  static createOtherIncomeSection(dataMap, startRow) {
    const rows = [];

    // Row 9: II. Other income
    const row9 = { [`A${startRow}`]: "II. Other income" };
    this.fillPeriodValues(row9, dataMap["other_income"], startRow);
    rows.push({ row: startRow, data: row9 });

    return rows;
  }

  static createTotalIncomeSection(dataMap, startRow) {
    const rows = [];

    // Row 10: III. Total Income (I+II)
    const row10 = { [`A${startRow}`]: "III. Total Income (I+II)" };
    this.fillPeriodValues(row10, dataMap["total_income"], startRow);
    rows.push({ row: startRow, data: row10 });

    // Row 11: Sale of Goods Growth YOY (empty)
    const row11 = { [`A${startRow + 1}`]: "Sale of Goods Growth YOY" };
    rows.push({ row: startRow + 1, data: row11 });

    // Row 12: Total Revenue Growth YOY (empty)
    const row12 = { [`A${startRow + 2}`]: "Total Revenue Growth YOY" };
    rows.push({ row: startRow + 2, data: row12 });

    // Row 13: Total Income Growth YOY (empty)
    const row13 = { [`A${startRow + 3}`]: "Total Income Growth YOY" };
    rows.push({ row: startRow + 3, data: row13 });

    return rows;
  }

  static createExpensesSection(dataMap, startRow) {
    const rows = [];

    // Row 15: IV. Expenses: (note: row 14 is empty)
    const row15 = { [`A${startRow}`]: "IV. Expenses:" };
    rows.push({ row: startRow, data: row15 });

    // Row 16: Cost of materials consumed
    const row16 = { [`A${startRow + 1}`]: "Cost of materials consumed" };
    this.fillPeriodValues(
      row16,
      dataMap["cost_of_materials_consumed"],
      startRow + 1
    );
    rows.push({ row: startRow + 1, data: row16 });

    // Row 17: Excise duty (not in sample data)
    const row17 = { [`A${startRow + 2}`]: "Excise duty" };
    rows.push({ row: startRow + 2, data: row17 });

    // Row 18: Purchases of stock-in-trade
    const row18 = { [`A${startRow + 3}`]: "Purchases of stock-in-trade" };
    this.fillPeriodValues(
      row18,
      dataMap["purchases_stock_in_trade"],
      startRow + 3
    );
    rows.push({ row: startRow + 3, data: row18 });

    // Row 19: Changes in inventories
    const row19 = {
      [`A${startRow + 4}`]:
        "Changes in inventories of finished goods,work-in-progress and stockin- trade",
    };
    this.fillPeriodValues(
      row19,
      dataMap["changes_in_inventories"],
      startRow + 4
    );
    rows.push({ row: startRow + 4, data: row19 });

    // Row 20: Employee benefits expense
    const row20 = { [`A${startRow + 5}`]: "Employee benefits expense" };
    this.fillPeriodValues(
      row20,
      dataMap["employee_benefits_expense"],
      startRow + 5
    );
    rows.push({ row: startRow + 5, data: row20 });

    // Row 21: Finance costs
    const row21 = { [`A${startRow + 6}`]: "Finance costs" };
    this.fillPeriodValues(row21, dataMap["finance_costs"], startRow + 6);
    rows.push({ row: startRow + 6, data: row21 });

    // Row 22: Depreciation and amortisation expense
    const row22 = {
      [`A${startRow + 7}`]: "Depreciation and amortisation expense",
    };
    this.fillPeriodValues(
      row22,
      dataMap["depreciation_amortisation_expense"],
      startRow + 7
    );
    rows.push({ row: startRow + 7, data: row22 });

    // Row 23: Other expenses (empty)
    const row23 = { [`A${startRow + 8}`]: "Other expenses" };
    rows.push({ row: startRow + 8, data: row23 });

    // Row 24: Advertising and promotion
    const row24 = { [`A${startRow + 9}`]: "Advertising and promotion" };
    this.fillPeriodValues(row24, dataMap["advertising_expense"], startRow + 9);
    rows.push({ row: startRow + 9, data: row24 });

    // Row 25: Others
    const row25 = { [`A${startRow + 10}`]: "Others" };
    this.fillPeriodValues(row25, dataMap["other_expense"], startRow + 10);
    rows.push({ row: startRow + 10, data: row25 });

    // Row 26: Impairment (empty)
    const row26 = { [`A${startRow + 11}`]: "Impairment" };
    rows.push({ row: startRow + 11, data: row26 });

    // Row 27: Provision for contingencies (empty)
    const row27 = { [`A${startRow + 12}`]: "Provision for contengencies" };
    rows.push({ row: startRow + 12, data: row27 });

    // Row 28: Corporate responsibilities (empty)
    const row28 = { [`A${startRow + 13}`]: "Corporate responsiblities" };
    rows.push({ row: startRow + 13, data: row28 });

    // Row 29: Total expenses
    const row29 = { [`A${startRow + 14}`]: "Total expenses" };
    this.fillPeriodValues(row29, dataMap["total_expenses"], startRow + 14);
    rows.push({ row: startRow + 14, data: row29 });

    // Row 30: PBT before exp items
    const row30 = { [`A${startRow + 15}`]: "PBT befor exp items" };
    this.fillPeriodValues(
      row30,
      dataMap["profit_before_exceptional_and_tax"],
      startRow + 15
    );
    rows.push({ row: startRow + 15, data: row30 });

    // Row 32: Exceptional items Gain/(Loss) (note: row 31 is empty)
    const row32 = { [`A${startRow + 17}`]: "Exceptional items Gain/(Loss)" };
    this.fillPeriodValues(
      row32,
      dataMap["exceptional_item_expense"],
      startRow + 17
    );
    rows.push({ row: startRow + 17, data: row32 });

    return rows;
  }

  static createProfitSection(dataMap, startRow) {
    const rows = [];

    // Row 34: V. Profit before tax (III-IV)
    const row34 = { [`A${startRow}`]: "V. Profit before tax (III-IV)" };
    this.fillPeriodValues(row34, dataMap["profit_before_tax"], startRow);
    rows.push({ row: startRow, data: row34 });

    // Row 35: % (empty)
    const row35 = { [`A${startRow + 1}`]: "%" };
    rows.push({ row: startRow + 1, data: row35 });

    return rows;
  }

  static createTaxSection(dataMap, startRow) {
    const rows = [];

    // Row 37: VI. Tax expense: (note: row 36 is empty)
    const row37 = { [`A${startRow}`]: "VI. Tax expense:" };
    rows.push({ row: startRow, data: row37 });

    // Row 38: (i) Current tax
    const row38 = { [`A${startRow + 1}`]: "(i) Current tax" };
    this.fillPeriodValues(row38, dataMap["current_tax"], startRow + 1);
    rows.push({ row: startRow + 1, data: row38 });

    // Row 39: (ii) Deferred tax/Income Tax of Prior years
    const row39 = {
      [`A${startRow + 2}`]: "(ii) Deferred tax/Income Tax of Prior years",
    };
    this.fillPeriodValues(row39, dataMap["deferred_tax"], startRow + 2);
    rows.push({ row: startRow + 2, data: row39 });

    // Row 40: Total Tax (sum of current and deferred tax)
    const row40 = { [`A${startRow + 3}`]: "Total Tax" };
    this.calculateTotalTax(row40, dataMap, startRow + 3);
    rows.push({ row: startRow + 3, data: row40 });

    return rows;
  }

  static createFinalProfitSection(dataMap, startRow) {
    const rows = [];

    // Row 41: VII. Profit for the year (V-VI)
    const row41 = { [`A${startRow}`]: "VII. Profit for the year (V-VI)" };
    this.fillPeriodValues(row41, dataMap["net_profit"], startRow);
    rows.push({ row: startRow, data: row41 });

    return rows;
  }

  static createEBITDASection(dataMap, startRow) {
    const rows = [];

    // Row 43: EBITDA (note: row 42 is empty)
    const row43 = { [`A${startRow}`]: "EBITDA" };
    rows.push({ row: startRow, data: row43 });

    // Row 44: EBITDA Margin
    const row44 = { [`A${startRow + 1}`]: "EBITDA Margin" };
    rows.push({ row: startRow + 1, data: row44 });

    return rows;
  }

  static createGrowthSection(startRow) {
    const rows = [];

    // Row 46: Volume Gr% (note: row 45 is empty)
    const row46 = { [`A${startRow}`]: "Volume Gr%" };
    rows.push({ row: startRow, data: row46 });

    // Row 47: Price Gr%
    const row47 = { [`A${startRow + 1}`]: "Price Gr%" };
    rows.push({ row: startRow + 1, data: row47 });

    return rows;
  }

  static parseValue(value) {
    if (value === null || value === undefined || value === "") {
      return 0;
    }

    const stringValue = String(value).trim();

    // Check if value is in brackets (negative)
    const hasBrackets = /^\(.*\)$/.test(stringValue);

    // Remove brackets, commas, and any whitespace
    let cleanValue = stringValue.replace(/[\(\),\s]/g, "");

    // Parse to float
    let numericValue = parseFloat(cleanValue) || 0;

    // Apply negative sign if brackets were present
    if (hasBrackets) {
      numericValue = -Math.abs(numericValue);
    }

    return numericValue;
  }

  static formatValue(value) {
    const numericValue =
      typeof value === "number" ? value : this.parseValue(value);

    if (numericValue < 0) {
      // Format negative values with brackets
      return `(${PeriodMapper.formatNumber(Math.abs(numericValue))})`;
    } else {
      // Format positive values normally
      return PeriodMapper.formatNumber(numericValue);
    }
  }

  static fillPeriodValues(rowData, values, rowNum) {
    const headers = PeriodMapper.getColumnHeaders();

    headers.forEach((header, index) => {
      const col = String.fromCharCode(66 + index);
      const dataKey = PeriodMapper.getDataKeyForPeriod(header);

      if (dataKey && values && values[dataKey] !== undefined) {
        const value = PeriodMapper.formatNumber(values[dataKey]);
        rowData[`${col}${rowNum}`] = value;
      } else {
        rowData[`${col}${rowNum}`] = "";
      }
    });
  }

  static calculateTotalRevenue(rowData, dataMap, rowNum) {
    const headers = PeriodMapper.getColumnHeaders();

    headers.forEach((header, index) => {
      const col = String.fromCharCode(66 + index);
      const dataKey = PeriodMapper.getDataKeyForPeriod(header);

      if (dataKey) {
        // Try to get from total_income or calculate
        // Check for both sale_of_products and sale_of_goods
        const saleData =
          dataMap["sale_of_products"] || dataMap["sale_of_goods"];
        const saleOfProducts = saleData
          ? this.parseValue(saleData[dataKey])
          : 0;
        const otherOperating = dataMap["other_operating_revenues"]
          ? this.parseValue(dataMap["other_operating_revenues"][dataKey])
          : 0;

        // Note: Export sales and services not in sample data
        const total = saleOfProducts + otherOperating;
        rowData[`${col}${rowNum}`] = this.formatValue(total);
      } else {
        rowData[`${col}${rowNum}`] = "";
      }
    });
  }

  static calculateTotalTax(rowData, dataMap, rowNum) {
    const headers = PeriodMapper.getColumnHeaders();

    headers.forEach((header, index) => {
      const col = String.fromCharCode(66 + index);
      const dataKey = PeriodMapper.getDataKeyForPeriod(header);

      if (dataKey) {
        const currentTax = dataMap["current_tax"]
          ? this.parseValue(dataMap["current_tax"][dataKey])
          : 0;
        const deferredTax = dataMap["deferred_tax"]
          ? this.parseValue(dataMap["deferred_tax"][dataKey])
          : 0;

        const total = currentTax + deferredTax;
        rowData[`${col}${rowNum}`] = this.formatValue(total);
      } else {
        rowData[`${col}${rowNum}`] = "";
      }
    });
  }
}

module.exports = DataProcessor;
