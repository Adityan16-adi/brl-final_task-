const { notifyUser } = require("../utils/notify");

const Assignment = require("../models/Assignment");
const Submission = require("../models/Submission");

// POST /api/submissions/assignment/:assignmentId
exports.submitAssignment = async (req, res) => {
  try {
    const { studentId, text } = req.body;
const fileUrl = req.file ? `/uploads/${req.file.filename}` : req.body.fileUrl;
if (!studentId || (!text && !fileUrl)) {
      return res
        .status(400)
        .json({ success: false, message: "studentId and text or fileUrl are required" });
    }

    const assignment = await Assignment.findById(req.params.assignmentId);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }

    const now = new Date();
    const isLate = now > assignment.dueDate;

    // create, or resubmit if the student already submitted
    const submission = await Submission.findOneAndUpdate(
      { assignmentId: assignment._id, studentId },
      { text, fileUrl, submittedAt: now, isLate, status: "submitted" },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    res.status(201).json({ success: true, message: "Submitted", data: submission });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/submissions/assignment/:assignmentId  (teacher sees all)
exports.getSubmissionsByAssignment = async (req, res) => {
  try {
    const submissions = await Submission.find({ assignmentId: req.params.assignmentId });
    res.json({ success: true, data: submissions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/submissions/assignment/:assignmentId/student/:studentId
exports.getMySubmission = async (req, res) => {
  try {
    const submission = await Submission.findOne({
      assignmentId: req.params.assignmentId,
      studentId: req.params.studentId,
    });
    res.json({ success: true, data: submission });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/submissions/:id/grade
exports.gradeSubmission = async (req, res) => {
  try {
    const { marks, feedback } = req.body;
    if (marks === undefined) {
      return res.status(400).json({ success: false, message: "marks is required" });
    }

    const existing = await Submission.findById(req.params.id).populate("assignmentId");
    if (!existing) {
      return res.status(404).json({ success: false, message: "Submission not found" });
    }
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