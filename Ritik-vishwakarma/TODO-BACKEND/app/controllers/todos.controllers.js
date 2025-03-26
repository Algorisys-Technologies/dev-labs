const _ = require("lodash");
const db = require("../models");
const Todo = db.todo;
const Op = db.Sequelize.Op;

// Create and Save a new Todo
exports.create = async (req, res) => {
  if (!_.isArray(req.body)) {
    res.send({
      status: "failure",
      message: "Please send data in correct format!",
    });
    return;
  }
  if (req.body.length === 0) {
    res.send({
      status: "failure",
      message: "Please send at least 1 record to create!",
    });
    return;
  }
  const todo = req.body[0];

  if (!todo.title) {
    res.send({
      status: "failure",
      message: "Todo title cannot be empty!",
    });
    return;
  }
//yaha se ......................................................
try {
  const createdTodo = await Todo.create(todo);
  
  // Store todo in the summary table
  await db.todoSummary.create({
    id: createdTodo.id,
    title: createdTodo.title,
    status: createdTodo.status,
  });

  res.send({ status: "success", data: createdTodo });
} catch (err) {
  res.status(500).send({ status: "failure", message: err.message || "Error creating Todo." });
}
//yaha tak.............................................................


  
  // Save Todo in the database
  Todo.create(todo)
    .then((data) => {
      res.send({
        status: "success",
        data: data,
      });
    })
    .catch((err) => {
      res.status(500).send({
        status: "failure",
        message: err.message || "Some error occurred while creating the Todo.",
      });
    });
};

// Retrieve all Todos from the database.
exports.findAll = async (req, res) => {
  const title = req.body.title;
  const status = req.body.status;
  const category = req.body.category;
  const priority = req.body.priority;

  let sortCol = req.body.sortCol || "createdAt";
  const sortOrder = req.body.sortOrder || "asc";

  let conditions = [];
  let limit = req.body.limit;
  let offset = req.body.offset;

  if (title) {
    conditions.push(`title LIKE "%${title}%"`);
  }
  if (status) {
    conditions.push(`status = "${status}"`);
  }
  if (category) {
    conditions.push(`category = "${category}"`);
  }
  if (priority) {
    conditions.push(`priority = "${priority}"`);
  }

  let conditionString = conditions.length ? ` WHERE ${conditions.join(" AND ")}` : "";

  let query = `SELECT * FROM todos ${conditionString} ORDER BY ${sortCol} ${sortOrder}`;
  if (limit) {
    query += ` LIMIT ${offset}, ${limit}`;
  }

  let data = await db.sequelize.query(query, {
    type: db.sequelize.QueryTypes.SELECT,
  });

  let totalCountQuery = `SELECT COUNT(*) AS totalRecords FROM todos ${conditionString}`;
  let totalCount = await db.sequelize.query(totalCountQuery, {
    type: db.sequelize.QueryTypes.SELECT,
  });

  res.send({
    status: "success",
    data: data,
    totalRecords: totalCount[0].totalRecords,
  });
};

// Find a single Todo by ID
exports.findOne = (req, res) => {
  const id = req.params.id;

  Todo.findByPk(id)
    .then((data) => {
      res.send({
        status: "success",
        data: data,
      });
    })
    .catch(() => {
      res.status(500).send({
        status: "failure",
        message: `Error retrieving Todo with id=${id}`,
      });
    });
};

// Update a Todo by ID
exports.update = (req, res) => {
  if (!_.isArray(req.body)) {
    res.status(400).send({
      status: "failure",
      message: "Please send data in correct format!",
    });
  }
  if (req.body.length === 0) {
    res.status(400).send({
      status: "failure",
      message: "Please send at least 1 record to update!",
    });
  }
  let todo = req.body[0];

  Todo.update(todo, {
    where: { id: todo.id },
  })
    .then((num) => {
      if (num == 1) {
        res.send({
          status: "success",
          message: "Todo was updated successfully.",
        });

        //yaha se
         db.todoSummary.update(
          { title: todo.title, status: todo.status },
          { where: { id: todo.id } }
        );
  
        res.send({ status: "success", message: "Todo updated successfully." });
        //yaha tak
      } else {
        res.send({
          status: "failure",
          message: `Cannot update Todo with id=${todo.id}. Maybe Todo was not found or req.body is empty!`,
        });
      }
    })
    .catch(() => {
      res.status(500).send({
        message: `Error updating Todo with id=${todo.id}`,
      });
    });
};

// Delete a Todo by ID
exports.delete = (req, res) => {
  const id = req.params.id;

  Todo.destroy({
    where: { id: id },
  })
    .then((num) => {
      if (num == 1) {
        res.send({
          status: "success",
          message: "Todo was deleted successfully!",
        });
          // Delete from todo_summary ......yahase ..........
      db.todoSummary.destroy({ where: { id } });

      res.send({ status: "success", message: "Todo deleted successfully!" });
      //yahatak...................................................
      } else {
        res.send({
          status: "failure",
          message: `Cannot delete Todo with id=${id}. Maybe Todo was not found!`,
        });
      }
    })
    .catch(() => {
      res.status(500).send({
        message: `Could not delete Todo with id=${id}`,
      });
    });
};

// Delete all Todos from the database.
exports.deleteAll = (req, res) => {
  Todo.destroy({
    where: {},
    truncate: false,
  })
    .then((nums) => {
      res.send({ message: `${nums} Todos were deleted successfully!` });
    })
    .catch((err) => {
      res.status(500).send({
        message: err.message || "Some error occurred while removing all Todos.",
      });
    });
};
