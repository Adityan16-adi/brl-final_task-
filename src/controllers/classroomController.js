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

        const { name, description } = req.body;

        if (!name) {
            return res.status(400).json({
                success: false,
                message: "Classroom name is required"
            });
        }

        const classroom = await Classroom.create({
            name,
            description,
            code: crypto.randomBytes(4).toString("hex").toUpperCase(),
            teacherUid: user.uid
        });

        res.status(201).json({
            success: true,
            message: "Classroom created successfully",
            classroom
        });
    } catch (error) {
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

        const classroom = await Classroom.findOne({
            code: code?.trim().toUpperCase()
        });

        if (!classroom) {
            return res.status(404).json({
                success: false,
                message: "Invalid classroom code"
            });
        }

        if (classroom.students.includes(user.uid)) {
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
            });
        } else {
            classrooms = await Classroom.find({
                students: user.uid
            });
        }

        res.status(200).json({
            success: true,
            count: classrooms.length,
            classrooms
        });
    } catch (error) {
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
        const isStudent = classroom.students.includes(user.uid);

        if (!isTeacher && !isStudent) {
            return res.status(403).json({
                success: false,
                message: "Access denied"
            });
        }

        res.status(200).json({
            success: true,
            classroom
        });
    } catch (error) {
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