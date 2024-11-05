const express = require("express");
const router = express.Router();
const firebaseAuthController = require("../controllers/firebase-auth-controller.js");
const verifyToken = require("../middleware/index.js");

router.post("/api/register", firebaseAuthController.registerUser);
router.post("/api/login", firebaseAuthController.loginUser);
router.post("/api/logout", firebaseAuthController.logoutUser);
router.post("/api/reset-password", firebaseAuthController.resetPassword);

router.get("/api/posts", verifyToken, (req, res) => {
  res.json({ message: "This is a protected route", user: req.user });
});

module.exports = router;
