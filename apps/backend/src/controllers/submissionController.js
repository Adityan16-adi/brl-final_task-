const { notifyUser } = require("../utils/notify");

const Assignment = require("../models/Assignment");
const Submission = require("../models/Submission");
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const mongoose = require("mongoose");
const { classAccess } = require("../utils/classAccess");

// POST /api/submissions/assignment/:assignmentId
exports.submitAssignment = async (req, res) => {
  try {
    const { text } = req.body || {};
    if (req.user.role !== "student") return res.status(403).json({ success: false, message: "Only students can submit assignments." });
    if (!mongoose.isValidObjectId(req.params.assignmentId)) return res.status(400).json({ success: false, message: "Assignment ID must be a valid MongoDB ObjectId." });
if (!text?.trim() && !req.file) {
      return res
        .status(400)
        .json({ success: false, message: "Provide submission text or attach a file." });
    }

    const assignment = await Assignment.findById(req.params.assignmentId);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }
    const access = await classAccess(assignment.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });

    const now = new Date();
    const isLate = now > assignment.dueDate;
    const uploaded = req.file ? await uploadToCloudinary(req.file.buffer, "submissions") : null;

    // create, or resubmit if the student already submitted
    const submission = await Submission.findOneAndUpdate(
      { assignmentId: assignment._id, studentId: req.user._id },
      { text: text || "", fileUrl: uploaded?.secure_url || "", submittedAt: now, isLate, status: "submitted" },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    res.status(201).json({ success: true, message: "Submitted", data: submission });
  } catch (error) {
    res.status(error.name === "ValidationError" || error.name === "CastError" ? 400 : 500).json({ success: false, message: error.message });
  }
};

// GET /api/submissions/assignment/:assignmentId  (teacher sees all)
exports.getSubmissionsByAssignment = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.assignmentId)) return res.status(400).json({ success: false, message: "Assignment ID must be a valid MongoDB ObjectId." });
    const assignment = await Assignment.findById(req.params.assignmentId);
    if (!assignment) return res.status(404).json({ success: false, message: "Assignment not found" });
    const access = await classAccess(assignment.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher) return res.status(403).json({ success: false, message: "Only the class teacher can view all submissions." });
    const submissions = await Submission.find({ assignmentId: req.params.assignmentId });
    res.json({ success: true, data: submissions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/submissions/assignment/:assignmentId/student/:studentId
exports.getMySubmission = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.assignmentId)) return res.status(400).json({ success: false, message: "Assignment ID must be a valid MongoDB ObjectId." });
    const assignment = await Assignment.findById(req.params.assignmentId);
    if (!assignment) return res.status(404).json({ success: false, message: "Assignment not found" });
    const access = await classAccess(assignment.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.student) return res.status(403).json({ success: false, message: "Only a class student can retrieve a personal submission." });
    if (req.params.studentId !== String(req.user._id)) return res.status(403).json({ success: false, message: "You can retrieve only your own submission." });
    const submission = await Submission.findOne({
      assignmentId: req.params.assignmentId,
      studentId: req.user._id,
    });
    res.json({ success: true, data: submission });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/submissions/:id/grade
exports.gradeSubmission = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Submission ID must be a valid MongoDB ObjectId." });
    if (req.user.role !== "teacher") return res.status(403).json({ success: false, message: "Only teachers can grade submissions." });
    const { marks, feedback } = req.body;
    if (marks === undefined) {
      return res.status(400).json({ success: false, message: "marks is required" });
    }

    const existing = await Submission.findById(req.params.id).populate("assignmentId");
    if (!existing) {
      return res.status(404).json({ success: false, message: "Submission not found" });
    }
    const access = await classAccess(existing.assignmentId.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher || String(existing.assignmentId.createdBy) !== String(req.user._id)) return res.status(403).json({ success: false, message: "Only the assignment's class teacher can grade it." });
    if (marks > existing.assignmentId.maxMarks) {
      return res
        .status(400)
        .json({ success: false, message: `marks cannot exceed ${existing.assignmentId.maxMarks}` });
    }

    existing.marks = marks;
    existing.feedback = feedback || "";
    existing.status = "graded";
    await existing.save();
    await notifyUser({
  userId: existing.studentId,
  title: "Assignment graded",
  message: `You got ${marks}/${existing.assignmentId.maxMarks} in "${existing.assignmentId.title}"`,
  type: "grade",
  refId: existing._id,
});

    res.json({ success: true, message: "Graded", data: existing });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
