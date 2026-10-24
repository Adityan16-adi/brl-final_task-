const { notifyUser } = require("../utils/notify");
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const { deleteFromCloudinary } = uploadToCloudinary;

const Assignment = require("../models/Assignment");
const Submission = require("../models/Submission");

// POST /api/submissions/assignment/:assignmentId
exports.submitAssignment = async (req, res) => {
  let newlyUploadedPublicId = null;
  let newlyUploadedResourceType = null;

  try {
    const { studentId, text } = req.body || {};

    const assignment = await Assignment.findById(req.params.assignmentId);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }

    const previous = await Submission.findOne({
      assignmentId: assignment._id,
      studentId,
    });

    let fileUrl = req.body?.fileUrl || "";
    let filePublicId = "";
    let fileResourceType = "";

    if (req.file) {
      const result = await uploadToCloudinary(
        req.file.buffer,
        "assignment-submissions"
      );
      fileUrl = result.secure_url;
      filePublicId = result.public_id;
      fileResourceType = result.resource_type;
      newlyUploadedPublicId = result.public_id;
      newlyUploadedResourceType = result.resource_type;
    }

    if (!req.file && previous) {
      filePublicId = previous.filePublicId || "";
      fileResourceType = previous.fileResourceType || "";
      if (!req.body?.fileUrl) {
        fileUrl = previous.fileUrl || "";
      }
    }

    if (!studentId || (!text?.trim() && !fileUrl)) {
      return res
        .status(400)
        .json({ success: false, message: "studentId and text or fileUrl are required" });
    }

    const now = new Date();
    const isLate = now > assignment.dueDate;

    // create, or resubmit if the student already submitted
    const submission = await Submission.findOneAndUpdate(
      { assignmentId: assignment._id, studentId },
      {
        text: text || "",
        fileUrl,
        filePublicId,
        fileResourceType,
        submittedAt: now,
        isLate,
        status: "submitted",
      },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    // Safe cleanup: Only delete old asset AFTER the database update has succeeded
    if (req.file && previous?.filePublicId && previous.filePublicId !== filePublicId) {
      await deleteFromCloudinary(previous.filePublicId, previous.fileResourceType);
    }

    res.status(201).json({ success: true, message: "Submitted", data: submission });
  } catch (error) {
    if (newlyUploadedPublicId) {
      await deleteFromCloudinary(newlyUploadedPublicId, newlyUploadedResourceType);
    }
    if (error.message && error.message.includes("Cloud storage is not configured")) {
      return res.status(503).json({
        success: false,
        message: "Storage service not configured. Unable to upload file.",
      });
    }
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