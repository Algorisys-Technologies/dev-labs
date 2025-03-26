module.exports = (app) => {
  const user = require("../controllers/user.controllers.js");

  var router = require("express").Router();

  // Create a new rationkit
  router.post("/login", user.login);

  app.use("/api/user", router);
};
