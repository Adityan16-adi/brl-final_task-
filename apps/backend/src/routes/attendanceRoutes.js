const express = require("express");
const router = express.Router();
const authenticate = require("../middleware/authenticate");
const {
  getClassAttendance,
  recordClassAttendance,
  getStudentAttendance,
} = require("../controllers/attendanceController");

router.use(authenticate);

router.get("/student/me", getStudentAttendance);
router.get("/class/:classId", getClassAttendance);
router.post("/class/:classId", recordClassAttendance);

module.exports = router;

