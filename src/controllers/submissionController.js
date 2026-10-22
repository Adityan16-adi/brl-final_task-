
const { notifyUser } = require("../utils/notify");
const Assignment = require("../models/Assignment");
const Submission = require("../models/Submission");
const uploadToCloudinary = require("../utils/uploadToCloudinary");

// POST /api/submissions/assignment/:assignmentId
exports.submitAssignment = async (req, res) => {
    try {
        const { studentId, text } = req.body || {};

        if (!studentId || (!text?.trim() && !req.file && !req.body.fileUrl)) {
            return res.status(400).json({
                success: false,
                message: "studentId and text or a file are required",
            });
        }

        const assignment = await Assignment.findById(req.params.assignmentId);

        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: "Assignment not found",
            });
        }

        let fileUrl = req.body.fileUrl || "";
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
        }

        const now = new Date();
        const isLate = now > assignment.dueDate;

        // Preserve existing file metadata if this is a text-only resubmission.
        const previous = await Submission.findOne({
            assignmentId: assignment._id,
            studentId,
        });

        if (!req.file && previous) {
            filePublicId = previous.filePublicId || "";
            fileResourceType = previous.fileResourceType || "";
            if (!req.body.fileUrl) {
                fileUrl = previous.fileUrl || "";
            }
        }

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
            {
                new: true,
                upsert: true,
                setDefaultsOnInsert: true,
                runValidators: true,
            }
        );

        return res.status(201).json({
            success: true,
            message: "Submitted",
            data: submission,
        });
    } catch (error) {
        console.error("Submit assignment error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to submit assignment",
        });
    }
};

// GET /api/submissions/assignment/:assignmentId
exports.getSubmissionsByAssignment = async (req, res) => {
    try {
        const submissions = await Submission.find({
            assignmentId: req.params.assignmentId,
        });

        return res.json({ success: true, data: submissions });
    } catch (error) {
        console.error("Get submissions error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to retrieve submissions",
        });
    }
};

// GET /api/submissions/assignment/:assignmentId/student/:studentId
exports.getMySubmission = async (req, res) => {
    try {
        const submission = await Submission.findOne({
            assignmentId: req.params.assignmentId,
            studentId: req.params.studentId,
        });

        return res.json({ success: true, data: submission });
    } catch (error) {
        console.error("Get student submission error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to retrieve submission",
        });
    }
};

// PUT /api/submissions/:id/grade
exports.gradeSubmission = async (req, res) => {
    try {
        const { marks, feedback } = req.body || {};

        if (marks === undefined || !Number.isFinite(Number(marks))) {
            return res.status(400).json({
                success: false,
                message: "A valid marks value is required",
            });
        }

        const existing = await Submission.findById(req.params.id)
            .populate("assignmentId");

        if (!existing) {
            return res.status(404).json({
                success: false,
                message: "Submission not found",
            });
        }

        if (!existing.assignmentId) {
            return res.status(400).json({
                success: false,
                message: "Associated assignment not found",
            });
        }

        const numericMarks = Number(marks);

        if (
            numericMarks < 0 ||
            numericMarks > existing.assignmentId.maxMarks
        ) {
            return res.status(400).json({
                success: false,
                message: `Marks must be between 0 and ${existing.assignmentId.maxMarks}`,
            });
        }

        existing.marks = numericMarks;
        existing.feedback = feedback || "";
        existing.status = "graded";
        await existing.save();

        await notifyUser({
            userId: existing.studentId,
            title: "Assignment graded",
            message: `You got ${numericMarks}/${existing.assignmentId.maxMarks} in "${existing.assignmentId.title}"`,
            type: "grade",
            refId: existing._id,
        });

        return res.json({
            success: true,
            message: "Graded",
            data: existing,
        });
    } catch (error) {
        console.error("Grade submission error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to grade submission",
        });
    }
};
