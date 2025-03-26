const passport = require("passport");
const LocalStrategy = require("passport-local").Strategy;
const db = require("./app/models");
const User = db.user;
const crypto = require("crypto");
// Changed username to email (Assuming users log in with an email).

// Added async/await for cleaner asynchronous handling.

// Enhanced error handling and messages for better debugging.

// Included serializeUser and deserializeUser to maintain sessions.
passport.use(
  new LocalStrategy(async (username, password, done) => {
    try {
      const user = await User.findOne({
        where: { username: username, isactive: 1 }, // Adjust field names as per your database
        attributes: [
          "id",
          "password",
          "salt",
          "firstName",
          "lastName",
          "mobileNo",
          "isActive",
          "role",
          "username"
        ],
      });

      if (!user) {
        return done(null, false, { message: "User not found" });
      }

      const hash_password = crypto
        .pbkdf2Sync(password, user.salt, 1000, 64, `sha512`)
        .toString(`hex`);

      if (hash_password !== user.password) {
        return done(null, false, { message: "Incorrect password" });
      }

      return done(null, user);
    } catch (err) {
      console.error(err);
      return done(err);
    }
  })
);

// Serialize user to store session
passport.serializeUser((user, done) => {
  done(null, user.id);
});

// Deserialize user from session
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findByPk(id);
    done(null, user);
  } catch (err) {
    done(err, null);
  }
});

module.exports = passport;
