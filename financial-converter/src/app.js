const express = require("express");
const multer = require("multer");
const cors = require("cors");
const morgan = require("morgan");
const path = require("path");
const config = require("./utils/config");

// Configure multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/");
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname)
    );
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: config.security.maxFileSize },
  fileFilter: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    if (config.security.allowedFileTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error("Only JSON files are allowed"));
    }
  },
});

const app = express();

// Middleware
app.use(cors());
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));
app.use(express.static(path.join(__dirname, "../public")));
app.use("/generated", express.static("generated"));
app.use("/uploads", express.static("uploads"));

// Import routes
const apiRoutes = require("./routes/api");
app.use("/api", upload.single("file"), apiRoutes);

// Preview page
app.get("/preview.html", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/preview.html"));
});

// Main page
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);

  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        error: "File too large",
        message: `Maximum file size is ${
          config.security.maxFileSize / 1024 / 1024
        }MB`,
      });
    }
  }

  res.status(500).json({
    success: false,
    error: "Something went wrong!",
    message: err.message,
  });
});

module.exports = app;
