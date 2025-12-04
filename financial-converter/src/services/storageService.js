const fs = require("fs");
const path = require("path");
const config = require("../utils/config");

class StorageService {
  constructor() {
    this.basePath = path.join(__dirname, "../../generated");
    this.initStorage();
  }

  initStorage() {
    // Create directories if they don't exist
    const dirs = [
      path.join(this.basePath, "excel"),
      path.join(this.basePath, "csv"),
      path.join(this.basePath, "metadata"),
    ];

    dirs.forEach((dir) => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });

    // Schedule cleanup
    this.scheduleCleanup();
  }

  async saveFile(type, content, metadata = {}) {
    const timestamp = Date.now();
    const fileId = this.generateFileId();
    const extension = type === "excel" ? ".xlsx" : ".csv";
    const fileName = `${fileId}${extension}`;

    const filePath = path.join(this.basePath, type, fileName);
    const metaPath = path.join(this.basePath, "metadata", `${fileId}.json`);

    // Save file content
    if (type === "excel") {
      const buffer = await content.xlsx.writeBuffer();
      fs.writeFileSync(filePath, buffer);
    } else {
      fs.writeFileSync(filePath, content);
    }

    // Save metadata
    const fileMetadata = {
      id: fileId,
      type: type,
      fileName: fileName,
      originalName: metadata.originalName || fileName,
      companyName: metadata.companyName,
      generatedAt: new Date().toISOString(),
      size: fs.statSync(filePath).size,
      downloadCount: 0,
      previewed: false,
      expiresAt: new Date(
        Date.now() + config.storage.retentionDays * 24 * 60 * 60 * 1000
      ).toISOString(),
    };

    fs.writeFileSync(metaPath, JSON.stringify(fileMetadata, null, 2));

    return {
      id: fileId,
      fileName: fileName,
      metadata: fileMetadata,
      url: `/api/files/${type}/${fileName}`,
      previewUrl: `/api/preview/${fileId}`,
      downloadUrl: `/api/download/${fileId}`,
    };
  }

  getFile(fileId, type = null) {
    let filePath;

    if (type) {
      // Direct path
      filePath = path.join(
        this.basePath,
        type,
        fileId + (type === "excel" ? ".xlsx" : ".csv")
      );
    } else {
      // Find file by ID in any directory
      const excelPath = path.join(this.basePath, "excel", fileId + ".xlsx");
      const csvPath = path.join(this.basePath, "csv", fileId + ".csv");

      if (fs.existsSync(excelPath)) {
        filePath = excelPath;
        type = "excel";
      } else if (fs.existsSync(csvPath)) {
        filePath = csvPath;
        type = "csv";
      }
    }

    if (!filePath || !fs.existsSync(filePath)) {
      console.error("File not found:", filePath);
      return null;
    }

    const metadata = this.getMetadata(fileId);
    return {
      path: filePath,
      type: type,
      metadata: metadata,
      content: fs.readFileSync(filePath),
    };
  }

  getMetadata(fileId) {
    const metaPath = path.join(this.basePath, "metadata", `${fileId}.json`);
    if (fs.existsSync(metaPath)) {
      return JSON.parse(fs.readFileSync(metaPath, "utf8"));
    }
    return null;
  }

  updateMetadata(fileId, updates) {
    const metadata = this.getMetadata(fileId);
    if (metadata) {
      Object.assign(metadata, updates);
      const metaPath = path.join(this.basePath, "metadata", `${fileId}.json`);
      fs.writeFileSync(metaPath, JSON.stringify(metadata, null, 2));
      return metadata;
    }
    return null;
  }

  incrementDownloadCount(fileId) {
    const metadata = this.getMetadata(fileId);
    if (metadata) {
      metadata.downloadCount = (metadata.downloadCount || 0) + 1;
      metadata.lastDownloaded = new Date().toISOString();
      this.updateMetadata(fileId, metadata);
    }
  }

  getFileList(type = null, limit = 50) {
    const metadataDir = path.join(this.basePath, "metadata");
    if (!fs.existsSync(metadataDir)) return [];

    const files = fs
      .readdirSync(metadataDir)
      .filter((file) => file.endsWith(".json"))
      .map((file) => {
        const fileId = file.replace(".json", "");
        return this.getMetadata(fileId);
      })
      .filter((meta) => meta && (!type || meta.type === type))
      .sort((a, b) => new Date(b.generatedAt) - new Date(a.generatedAt))
      .slice(0, limit);

    return files;
  }

  generateFileId() {
    return "file_" + Date.now() + "_" + Math.random().toString(36).substr(2, 9);
  }

  cleanupOldFiles() {
    const now = new Date();
    const metadataDir = path.join(this.basePath, "metadata");

    if (!fs.existsSync(metadataDir)) return;

    const files = fs.readdirSync(metadataDir);
    let deletedCount = 0;

    files.forEach((file) => {
      const fileId = file.replace(".json", "");
      const metadata = this.getMetadata(fileId);

      if (metadata && new Date(metadata.expiresAt) < now) {
        // Delete file
        const filePath = path.join(
          this.basePath,
          metadata.type,
          metadata.fileName
        );
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }

        // Delete metadata
        fs.unlinkSync(path.join(metadataDir, file));
        deletedCount++;
      }
    });

    if (deletedCount > 0) {
      console.log(`Cleaned up ${deletedCount} old files`);
    }
  }

  scheduleCleanup() {
    // Run cleanup every hour
    setInterval(() => this.cleanupOldFiles(), 60 * 60 * 1000);

    // Initial cleanup
    this.cleanupOldFiles();
  }

  deleteFile(fileId) {
    const metadata = this.getMetadata(fileId);
    if (!metadata) return false;

    // Delete the file
    const filePath = path.join(this.basePath, metadata.type, metadata.fileName);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    // Delete metadata
    const metaPath = path.join(this.basePath, "metadata", `${fileId}.json`);
    if (fs.existsSync(metaPath)) {
      fs.unlinkSync(metaPath);
    }

    return true;
  }
}

module.exports = new StorageService();
