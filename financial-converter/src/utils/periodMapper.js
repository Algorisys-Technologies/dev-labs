class PeriodMapper {
  // Map period keys to display labels
  static getPeriodMapping() {
    return {
      // Column headers (Row 2)
      "Unaudited Q1": "30.06.2025",
      "FY 2025": "31.03.2025_Y",
      Q4: "31.03.2025",
      Q3: null, // Not available in sample data
      Q2: null, // Not available in sample data
      "Unaudited Q1 FY 2024": "30.06.2024",
      "FY 2024": null, // Not available in sample data
      "Q4 FY 2024": null, // Not available in sample data
      "Q3 FY 2024": null, // Not available in sample data
      "Q2 FY 2024": null, // Not available in sample data
      "Q1 FY 2024": null, // Not available in sample data
    };
  }

  // Get period labels for Row 3
  static getPeriodSubLabels() {
    return {
      "Unaudited Q1": "3M-30th Jun 2025",
      "FY 2025": "12M",
      Q4: "3M-31st Mar 2025",
      Q3: "3M-31st Dec 2024",
      Q2: "3M-30th Sept 2024",
      "Unaudited Q1 FY 2024": "3M-30th Jun 2024",
      "FY 2024": "12M",
      "Q4 FY 2024": "3M-31st Mar 2024",
      "Q3 FY 2024": "3M-31st Dec 2023",
      "Q2 FY 2024": "3M-30th Sept 2023",
      "Q1 FY 2024": "3M-30th Jun 2023",
    };
  }

  // Get all column headers in order
  static getColumnHeaders() {
    return [
      "Unaudited Q1",
      "FY 2025",
      "Q4",
      "Q3",
      "Q2",
      "Unaudited Q1 FY 2024",
      "FY 2024",
      "Q4 FY 2024",
      "Q3 FY 2024",
      "Q2 FY 2024",
      "Q1 FY 2024",
    ];
  }

  // Get column letters for Excel (A-L)
  static getColumnLetters() {
    return ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"];
  }

  // Get data key for a period
  static getDataKeyForPeriod(periodLabel) {
    const mapping = this.getPeriodMapping();
    return mapping[periodLabel];
  }

  // Format number with commas
  static formatNumber(value) {
    if (
      value === null ||
      value === undefined ||
      value === "" ||
      value === "null"
    ) {
      return "";
    }

    // Check if it's already a formatted string
    if (typeof value === "string") {
      // Remove existing commas and check if it's a number
      const cleanValue = value.replace(/,/g, "");
      if (cleanValue.includes("(") && cleanValue.includes(")")) {
        const num = cleanValue.replace(/[()]/g, "");
        const number = parseFloat(num);
        if (!isNaN(number)) {
          return `(${Math.abs(number).toLocaleString("en-IN", {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0,
          })})`;
        }
      } else {
        const number = parseFloat(cleanValue);
        if (!isNaN(number)) {
          return number.toLocaleString("en-IN", {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0,
          });
        }
      }
    } else if (typeof value === "number") {
      return value.toLocaleString("en-IN", {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      });
    }

    return value;
  }
}

module.exports = PeriodMapper;
