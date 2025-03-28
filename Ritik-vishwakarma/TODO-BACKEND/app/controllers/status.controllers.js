const _ = require("lodash");
const db = require("../models");
const { cls } = require("sequelize");
const Status = db.status;

// Create a new status
exports.createStatus = async (req, res) => {
  try {
    const status = req.body[0];
    console.log("status",status);
    if (!status) {
      return res.status(400).json({ message: "Status is required" });
    }

    console.log("check comes here");
    const newStatus = await Status.create(status);
    console.log("newStatus", newStatus);

    res.status(201).json({ data: newStatus,success:true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all statuses
exports.getAllStatuses = async (req, res) => {
  const { status, limit, offset } = req.body;
  console.log("allstaus")
  let data = await await Status.findAll();
  res.send({
    status: "success",
    data: data,
  });
  // try {
  //   const statuses = await Status.findAll();
  //   res.status(200).json({ data: statuses,success:true });
  // } catch (error) {
  //   res.status(500).json({ message: error.message });
  // }
};

// Get status by ID
exports.getStatusById = async (req, res) => {
  try {
    const { id } = req.params;
    const status = await Status.findByPk(id);
    if (!status) {
      return res.status(404).json({ message: " Any Status  not found" });
    }
    res.status(200).json({ data: status });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update a status
exports.updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const statusToUpdate = await Status.findByPk(id);
    if (!statusToUpdate) {
      return res.status(404).json({ message: "Status not found" });
    }

    statusToUpdate.status = status;
    await statusToUpdate.save();

    res.status(200).json({ data: statusToUpdate });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete a status
exports.deleteStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const statusToDelete = await Status.findByPk(id);
    if (!statusToDelete) {
      return res.status(404).json({ message: "Status not found" });
    }

    await statusToDelete.destroy();
    res.status(200).json({ message: "Status deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
