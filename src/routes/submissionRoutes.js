const express = require("express");
const upload = require("../middleware/upload");
const router = express.Router();
const {
  submitAssignment,
  getSubmissionsByAssignment,
  getMySubmission,
  gradeSubmission,
  getAllStudentSubmissions,
} = require("../controllers/submissionController");

router.post("/assignment/:assignmentId", upload.single("file"), submitAssignment);
router.get("/assignment/:assignmentId", getSubmissionsByAssignment);
router.get("/assignment/:assignmentId/student/:studentId", getMySubmission);
router.get("/student/:studentId", getAllStudentSubmissions);
router.get("/my", getAllStudentSubmissions);
router.put("/:id/grade", gradeSubmission);

module.exports = router;
