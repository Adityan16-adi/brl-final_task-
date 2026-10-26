const mongoose = require("mongoose");
const { notifyUser } = require("../utils/notify");
const Assignment = require("../models/Assignment");
const Classroom = require("../models/Classroom");
const Submission = require("../models/Submission");
const User = require("../models/User");
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const { deleteFromCloudinary } = uploadToCloudinary;

// POST /api/submissions/assignment/:assignmentId
exports.submitAssignment = async (req, res) => {
    const uploadedPublicIds = [];

    try {
        const rawStudentId =
            req.body?.studentId ||
            req.user?._id ||
            req.user?.uid ||
            (process.env.NODE_ENV !== "production" ? "mock-student-01" : null);

        const text = req.body?.text || "";
        const link = req.body?.link || req.body?.submissionLink || "";
        let fileUrl = req.body?.fileUrl || "";

        // Resolve studentId to a valid User ObjectId
        let studentId = rawStudentId;
        let resolvedUser = null;
        if (rawStudentId && !mongoose.Types.ObjectId.isValid(rawStudentId)) {
            resolvedUser = await User.findOne({ uid: rawStudentId });
            if (!resolvedUser && process.env.NODE_ENV !== "production") {
                resolvedUser = await User.create({
                    uid: rawStudentId,
                    name: "Demo Student",
                    email: `${rawStudentId}@demo.com`,
                    role: "student",
                });
            }
            if (resolvedUser) {
                studentId = resolvedUser._id;
            }
        } else if (rawStudentId && mongoose.Types.ObjectId.isValid(rawStudentId)) {
            resolvedUser = await User.findById(rawStudentId);
        }

        const assignment = await Assignment.findById(req.params.assignmentId);
        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: "Assignment not found",
            });
        }

        // Enrollment validation: student must belong to the classroom
        if (assignment.classId) {
            const classroom = await Classroom.findById(assignment.classId);
            if (classroom) {
                const studentUid = req.user?.uid || resolvedUser?.uid || (typeof rawStudentId === "string" ? rawStudentId : "");
                const studentIdStr = studentId ? studentId.toString() : "";
                const isTeacher = classroom.teacherUid === studentUid;
                const isStudent = (classroom.students || []).some(
                    (s) => s === studentUid || s === studentIdStr || s === rawStudentId
                );
                if (!isTeacher && !isStudent) {
                    return res.status(403).json({
                        success: false,
                        message: "You are not enrolled in this classroom",
                    });
                }
            }
        }

        const previous = await Submission.findOne({
            assignmentId: assignment._id,
            studentId,
        });

        // Collect uploaded files from multipart req.file or req.files
        const filesToUpload = [];
        if (req.file) filesToUpload.push(req.file);
        if (Array.isArray(req.files)) {
            for (const f of req.files) {
                if (!filesToUpload.includes(f)) filesToUpload.push(f);
            }
        }

        // Parse any JSON attachments provided in body
        let attachments = [];
        if (Array.isArray(req.body?.attachments)) {
            attachments = [...req.body.attachments];
        } else if (typeof req.body?.attachments === "string" && req.body.attachments.trim().length > 0) {
            try {
                const parsed = JSON.parse(req.body.attachments);
                if (Array.isArray(parsed)) attachments = [...parsed];
            } catch (_) {}
        }

        // Process file uploads
        for (const file of filesToUpload) {
            const result = await uploadToCloudinary(
                file.buffer,
                "assignment-submissions",
                {
                    mimetype: file.mimetype,
                    filename: file.originalname,
                }
            );

            attachments.push({
                url: result.secure_url || result.url,
                name: file.originalname || "attachment",
                publicId: result.public_id || "",
                resourceType: result.resource_type || "raw",
                fileType: file.mimetype || "",
                size: file.size || (file.buffer ? file.buffer.length : 0),
            });

            uploadedPublicIds.push({
                publicId: result.public_id,
                resourceType: result.resource_type || "raw",
            });
        }

        // Backward compatibility for fileUrl & filePublicId
        let filePublicId = "";
        let fileResourceType = "";

        if (attachments.length > 0 && !fileUrl) {
            fileUrl = attachments[0].url;
            filePublicId = attachments[0].publicId || "";
            fileResourceType = attachments[0].resourceType || "raw";
        } else if (!req.file && filesToUpload.length === 0 && previous) {
            filePublicId = previous.filePublicId || "";
            fileResourceType = previous.fileResourceType || "";
            if (!fileUrl) fileUrl = previous.fileUrl || "";
            if (attachments.length === 0 && previous.attachments?.length > 0) {
                attachments = previous.attachments;
            }
        }

        // Require at least text, link, or attachment
        if (
            !rawStudentId ||
            (!text.trim() && !link.trim() && !fileUrl.trim() && attachments.length === 0)
        ) {
            return res.status(400).json({
                success: false,
                message: "Submission requires text, a link, or at least one attached file",
            });
        }

        const now = new Date();
        const isLate = assignment.dueDate ? now > new Date(assignment.dueDate) : false;

        const submission = await Submission.findOneAndUpdate(
            { assignmentId: assignment._id, studentId },
            {
                text: text.trim(),
                link: link.trim() || (previous?.link || ""),
                fileUrl,
                filePublicId,
                fileResourceType,
                attachments,
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

        // Safe cleanup: Only delete old single asset if a new file replaced it
        if (
            filesToUpload.length > 0 &&
            previous?.filePublicId &&
            previous.filePublicId !== filePublicId &&
            !previous.filePublicId.startsWith("local_")
        ) {
            await deleteFromCloudinary(previous.filePublicId, previous.fileResourceType);
        }

        return res.status(201).json({
            success: true,
            message: "Submitted",
            data: submission,
        });
    } catch (error) {
        for (const item of uploadedPublicIds) {
            if (item.publicId) {
                await deleteFromCloudinary(item.publicId, item.resourceType);
            }
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
        }).populate("studentId", "name email uid");

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
        }).populate("studentId", "name email uid");

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
