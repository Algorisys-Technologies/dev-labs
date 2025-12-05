const config = {
  // File storage settings
  storage: {
    enabled: true,
    excelPath: "generated/excel",
    csvPath: "generated/csv",
    retentionDays: 7, // Auto-cleanup after 7 days
    maxFiles: 1000, // Maximum files to store
  },

  // Download behavior
  download: {
    autoDownload: true, // Auto-download when API called
    allowPreview: true, // Allow preview before download
  },

  // Server settings
  server: {
    port: process.env.PORT || 3000,
    baseUrl: process.env.BASE_URL || "http://localhost:3000",
  },

  // Security
  security: {
    maxFileSize: 10 * 1024 * 1024, // 10MB
    allowedFileTypes: [".json"],
  },
};

module.exports = config;
