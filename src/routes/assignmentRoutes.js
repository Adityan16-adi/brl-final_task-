const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");
const {
  createAssignment,
  getAllAssignments,
  getAssignmentsByClass,
  getAssignmentById,
  updateAssignment,
  deleteAssignment,
} = require("../controllers/assignmentController");

const handleUpload = (req, res, next) => {
  upload.single("file")(req, res, (err) => {
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

router.post("/", handleUpload, createAssignment);
router.get("/", getAllAssignments);
router.get("/class/:classId", getAssignmentsByClass);
router.get("/:id", getAssignmentById);
router.put("/:id", handleUpload, updateAssignment);
router.delete("/:id", deleteAssignment);

module.exports = router;
