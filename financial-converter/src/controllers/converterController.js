const ExcelService = require("../services/excelService");
const CSVService = require("../services/csvService");
const StorageService = require("../services/storageService");
const config = require("../utils/config");
const fs = require("fs");
const path = require("path");

class ConverterController {
  static async generateExcel(req, res) {
    try {
      const { download = "true", preview = "false" } = req.query;
      const autoDownload = download === "true";
      const showPreview = preview === "true";

      let jsonData = await ConverterController.parseInput(req);

      // Generate Excel
      const workbook = await ExcelService.generateExcel(jsonData);

      // Save to storage
      const savedFile = await StorageService.saveFile("excel", workbook, {
        companyName: jsonData.company_name,
        originalName: `${jsonData.company_name || "Financial_Statement"}.xlsx`,
      });

      // Update metadata with preview flag
      StorageService.updateMetadata(savedFile.id, {
        previewRequested: showPreview,
      });

      // Prepare response based on parameters
      if (showPreview) {
        // Return file info for preview
        return res.json({
          success: true,
          message: "Excel file generated successfully",
          file: savedFile,
          previewUrl: `/preview.html?id=${savedFile.id}`,
          autoDownload: autoDownload && config.download.autoDownload,
        });
      } else if (autoDownload && config.download.autoDownload) {
        // Auto-download
        const fileData = StorageService.getFile(
          savedFile.id,
          savedFile.metadata.type
        );
        StorageService.incrementDownloadCount(savedFile.id);

        res.setHeader(
          "Content-Type",
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        );
        res.setHeader(
          "Content-Disposition",
          `attachment; filename="${savedFile.metadata.originalName}"`
        );
        res.send(fileData?.content ? fileData.content : null);
      } else {
        // Return file info
        res.json({
          success: true,
          message: "Excel file generated successfully",
          file: savedFile,
          downloadUrl: savedFile.downloadUrl,
          previewUrl: savedFile.previewUrl,
        });
      }
    } catch (error) {
      console.error("Error generating Excel:", error);
      res.status(500).json({
        success: false,
        error: "Failed to generate Excel file",
        message: error.message,
      });
    }
  }

  static async generateCSV(req, res) {
    try {
      const { download = "true", preview = "false" } = req.query;
      const autoDownload = download === "true";
      const showPreview = preview === "true";

      let jsonData = await ConverterController.parseInput(req);

      // Generate CSV
      const csvData = CSVService.generateFormattedCSV(jsonData);

      // Save to storage
      const savedFile = await StorageService.saveFile("csv", csvData, {
        companyName: jsonData.company_name,
        originalName: `${jsonData.company_name || "Financial_Statement"}.csv`,
      });

      // Update metadata with preview flag
      StorageService.updateMetadata(savedFile.id, {
        previewRequested: showPreview,
      });

      // Prepare response based on parameters
      if (showPreview) {
        // Return file info for preview
        return res.json({
          success: true,
          message: "CSV file generated successfully",
          file: savedFile,
          previewUrl: `/preview.html?id=${savedFile.id}`,
          autoDownload: autoDownload && config.download.autoDownload,
        });
      } else if (autoDownload && config.download.autoDownload) {
        // Auto-download
        const fileData = StorageService.getFile(savedFile.id);
        StorageService.incrementDownloadCount(savedFile.id);

        res.setHeader("Content-Type", "text/csv");
        res.setHeader(
          "Content-Disposition",
          `attachment; filename="${savedFile.metadata.originalName}"`
        );
        res.send(fileData.content);
      } else {
        // Return file info
        res.json({
          success: true,
          message: "CSV file generated successfully",
          file: savedFile,
          downloadUrl: savedFile.downloadUrl,
          previewUrl: savedFile.previewUrl,
        });
      }
    } catch (error) {
      console.error("Error generating CSV:", error);
      res.status(500).json({
        success: false,
        error: "Failed to generate CSV file",
        message: error.message,
      });
    }
  }

  static async downloadFile(req, res) {
    try {
      const { id } = req.params;
      const fileData = StorageService.getFile(id);

      if (!fileData) {
        return res.status(404).json({
          success: false,
          error: "File not found",
        });
      }

      // Increment download count
      StorageService.incrementDownloadCount(id);

      // Set headers based on file type
      if (fileData.type === "excel") {
        res.setHeader(
          "Content-Type",
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        );
        res.setHeader(
          "Content-Disposition",
          `attachment; filename="${fileData.metadata.originalName}"`
        );
      } else {
        res.setHeader("Content-Type", "text/csv");
        res.setHeader(
          "Content-Disposition",
          `attachment; filename="${fileData.metadata.originalName}"`
        );
      }

      res.send(fileData.content);
    } catch (error) {
      console.error("Error downloading file:", error);
      res.status(500).json({
        success: false,
        error: "Failed to download file",
        message: error.message,
      });
    }
  }

  static async previewFile(req, res) {
    try {
      const { id } = req.params;
      const fileData = StorageService.getFile(id);

      if (!fileData) {
        return res.status(404).json({
          success: false,
          error: "File not found",
        });
      }

      // Update metadata
      StorageService.updateMetadata(id, { previewed: true });

      // Return file info for preview
      res.json({
        success: true,
        file: fileData.metadata,
        content: fileData.type === "csv" ? fileData.content.toString() : null,
        downloadUrl: `/api/download/${id}`,
      });
    } catch (error) {
      console.error("Error previewing file:", error);
      res.status(500).json({
        success: false,
        error: "Failed to preview file",
        message: error.message,
      });
    }
  }

  static async listFiles(req, res) {
    try {
      const { type, limit = 50 } = req.query;
      const files = StorageService.getFileList(type, parseInt(limit));

      res.json({
        success: true,
        count: files.length,
        files: files,
      });
    } catch (error) {
      console.error("Error listing files:", error);
      res.status(500).json({
        success: false,
        error: "Failed to list files",
        message: error.message,
      });
    }
  }

  static async deleteFile(req, res) {
    try {
      const { id } = req.params;
      const deleted = StorageService.deleteFile(id);

      if (!deleted) {
        return res.status(404).json({
          success: false,
          error: "File not found",
        });
      }

      res.json({
        success: true,
        message: "File deleted successfully",
      });
    } catch (error) {
      console.error("Error deleting file:", error);
      res.status(500).json({
        success: false,
        error: "Failed to delete file",
        message: error.message,
      });
    }
  }

  static async parseInput(req) {
    let jsonData;

    if (req.file) {
      // Read from uploaded file
      const filePath = path.join(__dirname, "../../uploads", req.file.filename);
      const fileContent = fs.readFileSync(filePath, "utf8");
      jsonData = JSON.parse(fileContent);

      // Clean up uploaded file
      fs.unlinkSync(filePath);
    } else if (req.body.data) {
      // Parse from request body
      jsonData =
        typeof req.body.data === "string"
          ? JSON.parse(req.body.data)
          : req.body.data;
    } else {
      throw new Error("No JSON data provided");
    }

    // Validate JSON structure
    if (!jsonData || typeof jsonData !== "object") {
      throw new Error("Invalid JSON data");
    }

    return jsonData;
  }

  static healthCheck(req, res) {
    res.json({
      success: true,
      status: "OK",
      message: "Financial Statement Converter Service is running",
      version: "2.0.0",
      config: {
        autoDownload: config.download.autoDownload,
        allowPreview: config.download.allowPreview,
        storageEnabled: config.storage.enabled,
      },
    });
  }
}

module.exports = ConverterController;
