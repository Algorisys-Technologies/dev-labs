const jwt = require("jsonwebtoken");
const db = require("../models/index.js");
const authConfig = require("../config/auth.config.js");
const User = db.user;
exports.verifyToken = async function (req, res, next) {
  //   console.log("req.headers)req.headers)", req.headers);
  // console.log("In verifyToken ***********");
  // console.log("req.headers['token']", req.headers["token"]);
  // console.log(
  //   "req.headers[constants.auth_constant.ACCESS_TOKEN]",
  //   req.headers[constants.auth_constant.ACCESS_TOKEN]
  // );
  //console.log(req.headers[constants.auth_constant.REFRESH_TOKEN]);
  //console.log(constants.auth_constant.ACCESS_TOKEN.toLowerCase());
  //console.log(req.headers[constants.auth_constant.ACCESS_TOKEN.toLowerCase()]);
  //console.log(constants.auth_constant.REFRESH_TOKEN.toLowerCase());
  //console.log(req.headers[constants.auth_constant.REFRESH_TOKEN.toLowerCase()]);
  var token = req.headers["token"]
    ? req.headers["token"]
    : req.headers["token".toLowerCase()];

  let statusCode = "201";
  if (!token)
    return res.json({
      status: "failure",
      statusCode: 403,
      message: "No token provided.",
    });

  let is_valid_token = await isValidToken(token);
  if (!is_valid_token) {
    console.log("inValidToken");
    return res.json({
      status: "failure",
      statusCode: 403,
      message: "Token is not valid", //err_message
    });
  }

  jwt.verify(token, authConfig.secret, async function (err, decoded) {
    // console.log(err);
    // console.log(decoded);
    // console.log("jwt.verify", err, decoded);
    if (err) {
      // console.log(err.name);
      if (err.name === "TokenExpiredError") {
        return res.json({
          status: "failure",
          statusCode: 403,
          message: "token expired",
        });
      } else {
        // console.log("failed");
        // statusCode = 403;
        // return;
        // return res.status(403).json({ error: true, auth: false, message: 'Failed to authenticate token.' });
        return res.json({
          status: "failure",
          statusCode: 403,
          message: "Failed to authenticate token",
        });
      }
    } else {
      // if everything good, save to request for use in other routes
      let data = decoded.data;

      updateRequest(
        req,
        res,
        {
          userid: data.id,
          username: data.username,
          firstname: data.firstname,
          lastname: data.lastname,
        },
        token
      );
      next();
    }
  });

  if (statusCode === 403) {
    // console.log("statusCode === 403");
    // return res
    //   .status(403)
    //   .json({ error: true, auth: false, message: "Token Expired Error" });
    return res.json({
      status: "failure",
      statusCode: 403,
      message: "Token Expired Error",
    });
  }
};

async function isValidToken(token) {
  let res = await User.findOne({ where: { token: token } });
  return res && res.dataValues && res.dataValues.token ? true : false;
}

function updateRequest(req, res, decoded, token, refreshToken) {
  console.log("updateRequest ***************", decoded);
  let data = decoded; // decoded.data;

  req.userInfo = {
    userid: data.userid,
    username: data.username,
    firstname: data.firstname,
    lastname: data.lastname,
  };
  res.setHeader("token", token);
}
