module.exports = (app) => {
  const masterController = require("../controllers/masterdata.controllers.js");

  var router = require("express").Router();

  // Create a new rationkit
  router.get("/allareas", masterController.getAllArea);
  router.get("/items", masterController.getAllItems);

  app.use("/api/master", router);
};
