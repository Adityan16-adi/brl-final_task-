const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");
const {
  createAssignment,
  getAssignmentsByClass,
  getAssignmentById,
  updateAssignment,
  deleteAssignment,
} = require("../controllers/assignmentController");

router.post("/", upload.single("file"), createAssignment);
router.get("/class/:classId", getAssignmentsByClass);
router.get("/:id", getAssignmentById);
router.put("/:id", upload.single("file"), updateAssignment);
router.delete("/:id", deleteAssignment);

module.exports = router;