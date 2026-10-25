const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authMiddleware");
const { getLiveKitToken } = require("../controllers/meetingController");

router.post("/token", verifyToken, getLiveKitToken);
router.post("/:id/token", verifyToken, getLiveKitToken);

module.exports = router;
