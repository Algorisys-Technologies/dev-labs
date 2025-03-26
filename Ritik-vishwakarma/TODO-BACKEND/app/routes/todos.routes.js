const { verifyToken } = require("../controllers/token.controllers.js");

module.exports = (app) => {
  const todos = require("../controllers/todos.controllers.js");

  var router = require("express").Router();

  // Create a new Todo
  router.post("/create", verifyToken, todos.create);

  // Retrieve all Todos
  router.post("/findall", verifyToken, todos.findAll);

  // Retrieve a single Todo by ID
  router.get("/:id", verifyToken, todos.findOne);

  // Update a Todo
  router.post("/update", verifyToken, todos.update);

  // Delete a Todo by ID
  router.delete("/:id", verifyToken, todos.delete);

  // Delete all Todos
  router.delete("/", verifyToken, todos.deleteAll);


  app.use("/api/todos", router);
};
