const { v4: uuidv4 } = require("uuid");

module.exports = (sequelize, Sequelize) => {
  const Todo = sequelize.define("todo", {
    id: {
      type: Sequelize.UUID,
      defaultValue: function () {
        return uuidv4();
      },
      primaryKey: true,
    },
    title: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    description: {
      type: Sequelize.TEXT,
    },
    status: {
      type: Sequelize.STRING,
      defaultValue: "pending", // Possible values: pending, in-progress, completed
    },
    dueDate: {
      type: Sequelize.DATE,
    },
  });

  return Todo;
};
