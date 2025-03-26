const dbConfig = require("../config/db.config.js");

const Sequelize = require("sequelize");
const sequelize = new Sequelize(dbConfig.DB, dbConfig.USER, dbConfig.PASSWORD, {
  host: dbConfig.HOST,
  dialect: dbConfig.dialect,
  operatorsAliases: false,
  port: dbConfig.PORT || 3306,

  pool: {
    max: dbConfig.pool.max,
    min: dbConfig.pool.min,
    acquire: dbConfig.pool.acquire,
    idle: dbConfig.pool.idle,
  },
});

const db = {};

db.Sequelize = Sequelize;
db.sequelize = sequelize;

db.todo = require("./todo.models.js")(sequelize, Sequelize);
db.user = require("./user.models.js")(sequelize, Sequelize);
//yaha se 
db.todoSummary = require("./todo_summary.model.js")(sequelize, Sequelize); // Add new model
db.sequelize.sync()
  .then(() => {
    console.log("Database & tables synced!");
  })
  .catch((err) => {
    console.error("Error syncing database:", err);
  });
  // yaha tak new add

module.exports = db;
