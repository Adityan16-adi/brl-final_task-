const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authMiddleware");
const { syncUser } = require("../controllers/authController");

router.post("/sync", verifyToken, syncUser);

module.exports = router;