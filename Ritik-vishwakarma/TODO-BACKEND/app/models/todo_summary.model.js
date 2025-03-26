module.exports = (sequelize, Sequelize) => {
    const TodoSummary = sequelize.define("todo_summary", {
      id: {
        type: Sequelize.UUID,
        primaryKey: true,
      },
      title: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      status: {
        type: Sequelize.STRING,
        defaultValue: "pending", // possible values: pending, in-progress, completed
      },
    });
  
    return TodoSummary;
  };
  