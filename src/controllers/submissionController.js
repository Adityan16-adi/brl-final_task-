const mongoose = require("mongoose");
const { notifyUser } = require("../utils/notify");
const Assignment = require("../models/Assignment");
const Submission = require("../models/Submission");
const User = require("../models/User");
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const { deleteFromCloudinary } = uploadToCloudinary;

// POST /api/submissions/assignment/:assignmentId
exports.submitAssignment = async (req, res) => {
    let newlyUploadedPublicId = null;
    let newlyUploadedResourceType = null;

    try {
        const rawStudentId = req.body?.studentId || req.user?._id || req.user?.uid || (process.env.NODE_ENV !== "production" ? "mock-student-01" : null);
        const text = req.body?.text;

        if (!rawStudentId || (!text?.trim() && !req.file && !req.body?.fileUrl)) {
            return res.status(400).json({
                success: false,
                message: "studentId and text or a file are required",
            });
        }

        // Resolve studentId to a valid User ObjectId
        let studentId = rawStudentId;
        if (!mongoose.Types.ObjectId.isValid(rawStudentId)) {
            let userDoc = await User.findOne({ uid: rawStudentId });
            if (!userDoc && process.env.NODE_ENV !== "production") {
                userDoc = await User.create({
                    uid: rawStudentId,
                    name: "Demo Student",
                    email: `${rawStudentId}@demo.com`,
                    role: "student",
                });
            }
            if (userDoc) {
                studentId = userDoc._id;
            }
        }

        const assignment = await Assignment.findById(req.params.assignmentId);

        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: "Assignment not found",
            });
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

        const now = new Date();
        const isLate = now > assignment.dueDate;

        // Preserve existing file metadata if this is a text-only resubmission.
        if (!req.file && previous) {
            filePublicId = previous.filePublicId || "";
            fileResourceType = previous.fileResourceType || "";
            if (!req.body?.fileUrl) {
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

        // Safe cleanup: Only delete old asset AFTER the database update has succeeded
        if (req.file && previous?.filePublicId && previous.filePublicId !== filePublicId) {
            await deleteFromCloudinary(previous.filePublicId, previous.fileResourceType);
        }

        return res.status(201).json({
            success: true,
            message: "Submitted",
            data: submission,
        });
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
        let studentId = req.params.studentId;
        if (!mongoose.Types.ObjectId.isValid(studentId)) {
            const userDoc = await User.findOne({ uid: studentId });
            if (userDoc) {
                studentId = userDoc._id;
            }
        }

        const submission = await Submission.findOne({
            assignmentId: req.params.assignmentId,
            studentId,
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
            userId: existing.studentId.toString(),
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

// GET /api/submissions/student/:studentId or /api/submissions/my
exports.getAllStudentSubmissions = async (req, res) => {
    try {
        const rawStudentId = req.params.studentId || req.user?._id || req.user?.uid || "mock-student-01";
        let studentId = rawStudentId;
        if (!mongoose.Types.ObjectId.isValid(rawStudentId)) {
            const userDoc = await User.findOne({ uid: rawStudentId });
            if (userDoc) {
                studentId = userDoc._id;
            }
        }

        const submissions = await Submission.find({
            $or: [{ studentId }, { studentId: rawStudentId }]
        }).populate("assignmentId");

        return res.json({ success: true, data: submissions });
    } catch (error) {
        console.error("Get student submissions error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to retrieve submissions",
        });
    }
};
