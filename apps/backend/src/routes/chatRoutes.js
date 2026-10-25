const express = require("express");
const router = express.Router();
const chatController = require("../controllers/chatController");

router.post("/spam-check", chatController.checkSpam);
router.get("/:classId", chatController.getClassroomMessages);
router.post("/:classId", chatController.sendMessage);

module.exports = router;
