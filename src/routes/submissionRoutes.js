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

const handleUpload = (req, res, next) => {
  upload.any()(req, res, (err) => {
    if (err) {
      const isSizeLimit = err.code === "LIMIT_FILE_SIZE";
      return res.status(400).json({
        success: false,
        message: isSizeLimit
          ? "File size exceeds the 25MB limit. Please select a smaller file."
          : (err.message || "File upload error"),
      });
    }
    next();
  });
};

router.post("/assignment/:assignmentId", handleUpload, submitAssignment);
router.get("/assignment/:assignmentId", getSubmissionsByAssignment);
router.get("/assignment/:assignmentId/student/:studentId", getMySubmission);
router.get("/student/:studentId", getAllStudentSubmissions);
router.get("/my", getAllStudentSubmissions);
router.put("/:id/grade", gradeSubmission);

module.exports = router;
