const { verifyToken } = require("../controllers/token.controllers.js");

module.exports = (app) => {
  const todos = require("../controllers/todos.controllers.js");

  var router = require("express").Router();

  // Create a new Todo
  router.post("/create", verifyToken, todos.create);

  // Retrieve all Todos
  router.post("/findall", verifyToken, todos.findAll);
  // router.post("/checker", todos.findAll);
  router.post("/checker", verifyToken, todos.findPendingApproval);

  // route for rejected todos
  router.post("/rejected", verifyToken, todos.findRejectedTodos);


  // Retrieve a single Todo by ID
  router.get("/:id", verifyToken, todos.findOne);

  // Update a Todo
  router.post("/update", verifyToken, todos.update);

  // Delete a Todo by ID
  router.delete("/:id", verifyToken, todos.delete);

  router.put("/approve/:id", verifyToken, todos.approvePendingTodo);

  router.put("/bulkApprovePending", verifyToken, todos.bulkApprovePendingTodos);

  router.put("/bulkRejectPending", verifyToken, todos.bulkRejectPendingTodos);


  router.put("/reject/:id", verifyToken, todos.rejectPendingTodo);

  //For bulkdelete routes
  router.put('/bulkdelete', todos.bulkDeleteTodos);
  // Delete all Todos
  router.delete("/", verifyToken, todos.deleteAll);


  app.use("/api/todos", router);
};
