const Classroom = require("../models/Classroom");
const crypto = require("crypto");
const User = require("../models/User");

// Create classroom
const createClassroom = async (req, res) => {
    try {
        const user = await User.findOne({ uid: req.user.uid });

        if (!user || user.role !== "teacher") {
            return res.status(403).json({
                success: false,
                message: "Only teachers can create classrooms"
            });
        }

        const { name, subject, description, schedule } = req.body;

        if (!name || !name.trim()) {
            return res.status(400).json({
                success: false,
                message: "Classroom name is required"
            });
        }

        if (!subject || !subject.trim()) {
            return res.status(400).json({
                success: false,
                message: "Subject is required"
            });
        }

        const classroom = await Classroom.create({
            name: name.trim(),
            subject: subject.trim(),
            description: (description || "").trim(),
            schedule: (schedule || "").trim(),
            code: crypto.randomBytes(4).toString("hex").toUpperCase(),
            teacherUid: user.uid,
            students: []
        });

        res.status(201).json({
            success: true,
            message: "Classroom created successfully",
            classroom
        });
    } catch (error) {
        console.error("Create classroom error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to create classroom"
        });
    }
};

// Join classroom
const joinClassroom = async (req, res) => {
    try {
        const { code } = req.body;

        const user = await User.findOne({ uid: req.user.uid });

        if (!user || user.role !== "student") {
            return res.status(403).json({
                success: false,
                message: "Only students can join classrooms"
            });
        }

        if (!code || !code.trim()) {
            return res.status(400).json({
                success: false,
                message: "Classroom code is required"
            });
        }

        const classroom = await Classroom.findOne({
            code: code.trim().toUpperCase()
        });

        if (!classroom) {
            return res.status(404).json({
                success: false,
                message: "Invalid classroom code"
            });
        }

        if (classroom.students && classroom.students.includes(user.uid)) {
            return res.status(409).json({
                success: false,
                message: "Already joined this classroom"
            });
        }

        classroom.students.push(user.uid);
        await classroom.save();

        res.status(200).json({
            success: true,
            message: "Joined classroom successfully",
            classroom
        });
    } catch (error) {
        console.error("Join classroom error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to join classroom"
        });
    }
};

// Get classrooms
const getClassrooms = async (req, res) => {
    try {
        const user = await User.findOne({ uid: req.user.uid });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User profile not found"
            });
        }

        let classrooms;

        if (user.role === "teacher") {
            classrooms = await Classroom.find({
                teacherUid: user.uid
            }).sort({ createdAt: -1 });
        } else {
            classrooms = await Classroom.find({
                students: user.uid
            }).sort({ createdAt: -1 });
        }

        // Enrich classrooms with teacher name and student count
        const teacherUids = [...new Set(classrooms.map((c) => c.teacherUid))];
        const teachers = await User.find({ uid: { $in: teacherUids } });
        const teacherMap = {};
        teachers.forEach((t) => {
            teacherMap[t.uid] = t.name;
        });

        const formatted = classrooms.map((c) => ({
            ...c.toObject(),
            teacherName: teacherMap[c.teacherUid] || "Instructor",
            studentCount: (c.students || []).length
        }));

        res.status(200).json({
            success: true,
            count: formatted.length,
            classrooms: formatted
        });
    } catch (error) {
        console.error("Get classrooms error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch classrooms"
        });
    }
};

// Get classroom by ID
const getClassroomById = async (req, res) => {
    try {
        const user = await User.findOne({
            uid: req.user.uid
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User profile not found"
            });
        }

        const classroom = await Classroom.findById(
            req.params.id
        );

        if (!classroom) {
            return res.status(404).json({
                success: false,
                message: "Classroom not found"
            });
        }

        const isTeacher = classroom.teacherUid === user.uid;
        const isStudent = (classroom.students || []).includes(user.uid);

        if (!isTeacher && !isStudent) {
            return res.status(403).json({
                success: false,
                message: "Access denied"
            });
        }

        const teacher = await User.findOne({ uid: classroom.teacherUid });
        const students = await User.find(
            { uid: { $in: classroom.students || [] } },
            "uid name email"
        );

        const classroomData = classroom.toObject();
        classroomData.teacherName = teacher ? teacher.name : "Instructor";
        classroomData.studentProfiles = students;
        classroomData.studentCount = (classroom.students || []).length;
        classroomData.isTeacher = isTeacher;

        res.status(200).json({
            success: true,
            classroom: classroomData
        });
    } catch (error) {
        console.error("Get classroom by ID error:", error);
        res.status(400).json({
            success: false,
            message: "Invalid classroom ID or request"
        });
    }
};

// Remove student from classroom
const removeStudent = async (req, res) => {
    try {
        const user = await User.findOne({
            uid: req.user.uid
        });

        if (!user || user.role !== "teacher") {
            return res.status(403).json({
                success: false,
                message: "Only teachers can remove students"
            });
        }

        const classroom = await Classroom.findById(
            req.params.id
        );

        if (!classroom) {
            return res.status(404).json({
                success: false,
                message: "Classroom not found"
            });
        }

        if (classroom.teacherUid !== user.uid) {
            return res.status(403).json({
                success: false,
                message: "You do not own this classroom"
            });
        }

        const { studentUid } = req.body;

        if (!studentUid) {
            return res.status(400).json({
                success: false,
                message: "Student UID is required"
            });
        }

        classroom.students = classroom.students.filter(
            uid => uid !== studentUid
        );

        await classroom.save();

        res.status(200).json({
            success: true,
            message: "Student removed successfully"
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to remove student"
        });
    }
};

module.exports = { createClassroom, joinClassroom, getClassrooms, getClassroomById, removeStudent };