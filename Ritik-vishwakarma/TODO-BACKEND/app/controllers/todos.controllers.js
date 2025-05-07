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


    res.send({ status: "success", data: createdTodo });
  } catch (err) {
    res.status(500).send({ status: "failure", message: err.message || "Error creating Todo." });
  }
  //yaha tak.............................................................



  // Save Todo in the database

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

// Fetch all Todos pending approval
exports.findPendingApproval = async (req, res) => {
  const title = req.body.title;
  const status = req.body.status;
  const category = req.body.category;
  const priority = req.body.priority;

  let sortCol = req.body.sortCol || "createdAt";
  const sortOrder = req.body.sortOrder || "asc";

  let conditions = [`pendingApproval = 1`]; // Only pending approval

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

  let conditionString = `WHERE ${conditions.join(" AND ")}`;

  let limit = req.body.limit;
  let offset = req.body.offset;

  let query = `SELECT * FROM todos ${conditionString} ORDER BY ${sortCol} ${sortOrder}`;
  if (limit) {
    query += ` LIMIT ${offset}, ${limit}`;
  }

  try {
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
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || "Error retrieving pending approval Todos.",
    });
  }
};
// for Rejected todo finding
exports.findRejectedTodos = async (req, res) => {
  const title = req.body.title;
  const category = req.body.category;
  const priority = req.body.priority;

  let sortCol = req.body.sortCol || "createdAt";
  const sortOrder = req.body.sortOrder || "desc"; // Default to descending for recent rejects

  let conditions = [`status = 'rejected'`]; // Only rejected status

  if (title) {
    conditions.push(`title LIKE "%${title}%"`);
  }
  if (category) {
    conditions.push(`category = "${category}"`);
  }
  if (priority) {
    conditions.push(`priority = "${priority}"`);
  }

  let conditionString = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

  let limit = req.body.limit;
  let offset = req.body.offset;

  let query = `SELECT * FROM todos ${conditionString} ORDER BY ${sortCol} ${sortOrder}`;
  if (limit) {
    query += ` LIMIT ${offset}, ${limit}`;
  }

  try {
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
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || "Error retrieving rejected Todos.",
    });
  }
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

// Approve a pending Todo by ID (set pendingApproval = false)
exports.approvePendingTodo = async (req, res) => {
  const id = req.params.id;

  try {
    const todo = await Todo.findByPk(id);

    if (!todo) {
      return res.status(404).send({
        status: "failure",
        message: `Todo with id=${id} not found.`,
      });
    }

    if (!todo.pendingApproval) {
      return res.send({
        status: "failure",
        message: `Todo with id=${id} is not pending approval.`,
      });
    }

    todo.pendingApproval = false;
    await todo.save();

    res.send({
      status: "success",
      message: `Todo with id=${id} has been approved.`,
      data: todo,
    });
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || `Could not approve Todo with id=${id}`,
    });
  }
};

// Bulk Approve pending Todos by IDs
exports.bulkApprovePendingTodos = async (req, res) => {
  const data = req.body.data;
  const ids = data.map(todo => todo.id); // 🛠️ Extract ids only
  console.log("ids", ids);
  if (!Array.isArray(ids) || ids.length === 0) {
    return res.status(400).send({
      status: "failure",
      message: "Please send an array of todo IDs to approve.",
    });
  }

  try {
    const [updatedCount] = await Todo.update(
      { pendingApproval: false },
      {
        where: {
          id: {
            [Op.in]: ids,
          },
          pendingApproval: true, // only update those actually pending
        },
      }
    );

    res.send({
      status: "success",
      message: `${updatedCount} todos approved successfully.`,
    });
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || "Error approving todos in bulk.",
    });
  }
};

// Bulk Rejected pending Todos 
exports.bulkRejectPendingTodos = async (req, res) => {
  const data = req.body.data;
  const ids = data.map(todo => todo.id);

  if (!Array.isArray(ids) || ids.length === 0) {
    return res.status(400).send({
      status: "failure",
      message: "Please send an array of todo IDs to reject.",
    });
  }

  try {
    const [updatedCount] = await Todo.update(
      {
        status: 'rejected',
        pendingApproval: false  // Clear pending flag
      },
      {
        where: {
          id: {
            [Op.in]: ids,
          },
          pendingApproval: true // Only reject pending todos
        },
      }
    );

    res.send({
      status: "success",
      message: `${updatedCount} todos rejected successfully.`,
    });
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || "Error rejecting todos in bulk.",
    });
  }
};


//Reject  pendingTodo
exports.rejectPendingTodo = async (req, res) => {
  const id = req.params.id;

  try {
    const todo = await Todo.findByPk(id);

    if (!todo) {
      return res.status(404).send({
        status: "failure",
        message: `Todo with id=${id} not found.`,
      });
    }

    if (!todo.pendingApproval) {
      return res.send({
        status: "failure",
        message: `Todo with id=${id} is not pending approval.`,
      });
    }

    // Update both pendingApproval and status
    todo.pendingApproval = false;
    todo.status = "rejected"; // Or whatever status you want to set for rejected todos
    await todo.save();

    res.send({
      status: "success",
      message: `Todo with id=${id} has been rejected.`,
      data: todo,
    });
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || `Could not reject Todo with id=${id}`,
    });
  }
};

// Bulk delete from database
exports.bulkDeleteTodos = async (req, res) => {
  const data = req.body.data;
  const ids = data.map(todo => todo.id);

  if (!Array.isArray(ids) || ids.length === 0) {
    return res.status(400).send({
      status: "failure",
      message: "Please send an array of todo IDs to delete.",
    });
  }

  try {
    const deletedCount = await Todo.destroy({
      where: {
        id: {
          [Op.in]: ids,
        }
      },
    });

    res.send({
      status: "success",
      message: `${deletedCount} todos deleted successfully.`,
    });
  } catch (err) {
    res.status(500).send({
      status: "failure",
      message: err.message || "Error deleting todos in bulk.",
    });
  }
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



// For approval
// Approve a Todo (Admin only)
// exports.approve = async (req, res) => {
//   try {
//     const todo = await Todo.findByPk(req.params.id);
//     if (!todo) {
//       return res.status(404).send({ status: "failure", message: "Todo not found." });
//     }

//     todo.pendingApproval = false;
//     await todo.save();

//     res.send({ status: "success", data: todo });
//   } catch (err) {
//     res.status(500).send({ status: "failure", message: err.message });
//   }
// };
