const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authMiddleware");
const {
    createClassroom,
    joinClassroom,getClassrooms,getClassroomById,removeStudent
} = require("../controllers/classroomController");

router.post("/", verifyToken, createClassroom);
router.post("/join", verifyToken, joinClassroom);
router.get("/", verifyToken,getClassrooms);
router.get("/:id", verifyToken,getClassroomById);
router.delete("/:id/students", verifyToken, removeStudent);

module.exports = router;