const express = require("express");
const ConverterController = require("../controllers/converterController");

const router = express.Router();

// Health check
router.get("/health", ConverterController.healthCheck);

// Generate files with options
router.post("/excel", ConverterController.generateExcel);
router.post("/csv", ConverterController.generateCSV);

// File management
router.get("/files", ConverterController.listFiles);
router.get("/preview/:id", ConverterController.previewFile);
router.get("/download/:id", ConverterController.downloadFile);
router.delete("/files/:id", ConverterController.deleteFile);

// Serve static files
router.get("/files/excel/:filename", (req, res) => {
  const { filename } = req.params;
  const filePath = path.join(__dirname, "../../generated/excel", filename);

  if (fs.existsSync(filePath)) {
    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: "File not found" });
  }
});

router.get("/files/csv/:filename", (req, res) => {
  const { filename } = req.params;
  const filePath = path.join(__dirname, "../../generated/csv", filename);

  if (fs.existsSync(filePath)) {
    res.setHeader("Content-Type", "text/csv");
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: "File not found" });
  }
});

module.exports = router;
