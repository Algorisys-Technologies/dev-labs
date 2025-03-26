const path = require("path");
const express = require("express");
const passport = require("passport");
require("./passport"); // Ensure passport config is loaded

const cors = require("cors");

const app = express();

const corsOptions = {
  origin: "*",
};

app.use(cors(corsOptions));
app.use(passport.initialize());
app.use(passport.session());

// Parse requests of content-type - application/json
app.use(express.json());

// Parse requests of content-type - application/x-www-form-urlencoded
app.use(express.urlencoded({ extended: true }));

const db = require("./app/models");

db.sequelize.sync(); // Sync database

// Simple route
app.get("/", (req, res) => {
  res.json({ message: "Welcome to Todo App." });
});

// Register routes
require("./app/routes/todos.routes")(app);
require("./app/routes/user.routes")(app);
require("./app/routes/master.routes")(app);

// Set port and start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}.`);
});
