const express = require("express");
const upload = require("../middleware/upload");
const authenticate = require("../middleware/authenticate");
const router = express.Router();
const {
  submitAssignment,
  getSubmissionsByAssignment,
  getMySubmission,
  gradeSubmission,
} = require("../controllers/submissionController");

router.use(authenticate);
router.post("/assignment/:assignmentId", upload.single("file"), submitAssignment);
router.get("/assignment/:assignmentId", getSubmissionsByAssignment);
router.get("/assignment/:assignmentId/me", (req, res, next) => { req.params.studentId = String(req.user._id); next(); }, getMySubmission);
router.get("/assignment/:assignmentId/student/:studentId", getMySubmission);
router.put("/:id/grade", gradeSubmission);

module.exports = router;
