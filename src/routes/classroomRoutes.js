const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authMiddleware");
const {
    createClassroom,
    joinClassroom,getClassrooms,getClassroomById,removeStudent
} = require("../controllers/classroomController");
const { getLiveKitToken } = require("../controllers/meetingController");

router.post("/", verifyToken, createClassroom);
router.post("/join", verifyToken, joinClassroom);
router.get("/", verifyToken,getClassrooms);
router.get("/:id", verifyToken,getClassroomById);
router.delete("/:id/students", verifyToken, removeStudent);
router.post("/:id/meeting/token", verifyToken, getLiveKitToken);

module.exports = router;