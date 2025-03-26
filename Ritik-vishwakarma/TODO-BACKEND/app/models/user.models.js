// import {uuidv4} from "uuid/v4";
const { v4: uuidv4 } = require("uuid");
module.exports = (sequelize, Sequelize) => {
  const User = sequelize.define("user", {
    id: {
      type: Sequelize.UUID,
      defaultValue: function () {
        return uuidv4();
      },
      primaryKey: true,
    },
    username: {
      type: Sequelize.STRING,
    },
    password: {
      type: Sequelize.STRING,
    },
    salt: {
      type: Sequelize.STRING,
    },
    token: {
      type: Sequelize.STRING,
    },
    firstname: {
      type: Sequelize.STRING,
    },
    lastname: {
      type: Sequelize.STRING,
    },
    mobileno: {
      type: Sequelize.STRING,
    },
    isactive: {
      type: Sequelize.BOOLEAN,
      defaultValue: true,
    },
    role: {
      type: Sequelize.STRING,
    },
  });

  return User;
};
