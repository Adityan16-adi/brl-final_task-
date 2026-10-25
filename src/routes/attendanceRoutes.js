const express = require("express");
const router = express.Router();
const {
  takeAttendance,
  getAttendanceByClass,
  getMyAttendance,
} = require("../controllers/attendanceController");

router.post("/", takeAttendance);
router.get("/class/:classId", getAttendanceByClass);
router.get("/student/:studentId", getMyAttendance);

module.exports = router;
