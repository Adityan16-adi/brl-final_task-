const express = require("express");
const router = express.Router();
const c = require("../controllers/sessionController");

router.post("/", c.startSession);
router.post("/:id/join", c.joinSession);
router.post("/:id/heartbeat", c.heartbeat);
router.post("/:id/leave", c.leaveSession);
router.put("/:id/end", c.endSession);
router.get("/:id/attendance", c.getSessionAttendance);
router.get("/class/:classId/student/:studentId", c.getStudentSummary);

module.exports = router;