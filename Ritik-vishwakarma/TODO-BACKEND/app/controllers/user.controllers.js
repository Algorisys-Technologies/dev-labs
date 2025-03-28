const _ = require("lodash");
var jwt = require("jsonwebtoken");
const passport = require("passport");
const db = require("../models/index.js");
const authConfig = require("../config/auth.config.js");

exports.login = (req, res, next) => {
  const {username, password} = req.body;
  console.log(" {username, password} ::", {username, password} )
  if (username && password) {
    passport.authenticate("local", { session: false }, (x, usr) => {
      if (usr) {
        var token = generateToken({
          id: usr.username,
          firstname: usr.firstname,
          lastname: usr.lastname,
        });
        db.sequelize
          .query(
            `update users set token="${token}" where username="${usr.username}"`
          )
          .then(() => {
            res.json({
              status: "success",
              data: {
                token: token,
                username: usr.username,
                firstname: usr.firstname,
                lastname: usr.lastname,
                userDisplayName: `${usr.firstname} ${usr.lastname}`,
              },
            });
          });
      } else {
        res.json({
          status: "failure",
          message: "Invalid Credentials",
        });
      }
    })(req, res, next);
  } else {  
      res.json({
        status: "failure",
        message: "Please enter Credentials",
      });
    
  }
};

const generateToken = (info, expire_time) => {
  var token = jwt.sign({ data: info }, authConfig.secret, {
    expiresIn: expire_time ? expire_time : authConfig.tokenExpiryTime,
  });
  return token;
};
