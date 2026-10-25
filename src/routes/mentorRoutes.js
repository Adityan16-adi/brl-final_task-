const express = require("express");
const router = express.Router();
const mentorController = require("../controllers/mentorController");
const verifyToken = require("../middleware/authMiddleware");

// Optional authentication middleware: if bearer token present, decodes user, otherwise allows guest/demo
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return verifyToken(req, res, next);
  }
  next();
};

router.get("/health", optionalAuth, mentorController.health);
router.post("/chat", optionalAuth, mentorController.chat);
router.post("/materials", verifyToken, mentorController.addMaterials);
router.post("/reset", optionalAuth, mentorController.resetSession);

module.exports = router;
