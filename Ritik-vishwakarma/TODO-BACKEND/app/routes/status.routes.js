const express = require("express");
const router = express.Router();
const statusController = require("../controllers/status.controllers");

router.post("/status/create", statusController.createStatus);
router.post("/status/findall", statusController.getAllStatuses);
router.get("/status/:id", statusController.getStatusById);
router.post("/status/update/:id", statusController.updateStatus);
router.delete("/status/:id", statusController.deleteStatus);

module.exports = router;
