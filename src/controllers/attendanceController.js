const mongoose = require("mongoose");
const Attendance = require("../models/Attendance");
const Classroom = require("../models/Classroom");
const User = require("../models/User");

// POST /api/attendance
exports.takeAttendance = async (req, res) => {
  try {
    const { classId, sessionDate, records, topic } = req.body;

    if (!classId || !records || !Array.isArray(records)) {
      return res.status(400).json({
        success: false,
        message: "classId and records array are required",
      });
    }

    let resolvedClassId = classId;
    if (!mongoose.Types.ObjectId.isValid(classId)) {
      const cls = await Classroom.findOne({
        $or: [{ _id: mongoose.Types.ObjectId.isValid(classId) ? classId : null }, { code: classId }],
      });
      if (cls) {
        resolvedClassId = cls._id;
      }
    }

    const date = sessionDate ? new Date(sessionDate) : new Date();
    // Normalize to date (start of day)
    const dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const dayEnd = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);

    const markedByUid = req.user?.uid || req.body.teacherUid || "teacher";

    // Format records
    const formattedRecords = records.map((r) => ({
      studentUid: r.studentUid || r.uid || "student",
      studentName: r.studentName || r.name || "Student",
      status: ["present", "absent", "late", "excused"].includes(r.status)
        ? r.status
        : "present",
      remarks: r.remarks || "",
    }));

    // Find existing attendance for this class and day, or create new
    let attendance = await Attendance.findOne({
      classId: resolvedClassId,
      sessionDate: { $gte: dayStart, $lte: dayEnd },
    });

    if (attendance) {
      attendance.records = formattedRecords;
      if (topic) attendance.topic = topic;
      attendance.markedByUid = markedByUid;
      await attendance.save();
    } else {
      attendance = await Attendance.create({
        classId: resolvedClassId,
        sessionDate: date,
        markedByUid,
        topic: topic || "Regular Session",
        records: formattedRecords,
      });
    }

    return res.status(201).json({
      success: true,
      message: "Attendance recorded successfully",
      data: attendance,
    });
  } catch (error) {
    console.error("Take attendance error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to record attendance",
      error: error.message,
    });
  }
};

// GET /api/attendance/class/:classId
exports.getAttendanceByClass = async (req, res) => {
  try {
    const { classId } = req.params;
    let queryClassId = classId;

    if (!mongoose.Types.ObjectId.isValid(classId)) {
      const cls = await Classroom.findOne({ code: classId });
      if (cls) queryClassId = cls._id;
    }

    const history = await Attendance.find({ classId: queryClassId })
      .sort({ sessionDate: -1 })
      .limit(50);

    return res.json({
      success: true,
      data: history,
    });
  } catch (error) {
    console.error("Get class attendance error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve attendance history",
    });
  }
};

// GET /api/attendance/student/:studentId
exports.getMyAttendance = async (req, res) => {
  try {
    const studentUid = req.params.studentId || req.user?.uid || "student";

    const allAttendances = await Attendance.find({
      "records.studentUid": studentUid,
    })
      .populate("classId", "name subject code")
      .sort({ sessionDate: -1 });

    let totalSessions = 0;
    let presentCount = 0;
    let absentCount = 0;
    let lateCount = 0;

    const studentHistory = allAttendances.map((att) => {
      totalSessions++;
      const record = att.records.find((r) => r.studentUid === studentUid);
      const status = record ? record.status : "absent";
      if (status === "present") presentCount++;
      else if (status === "late") lateCount++;
      else absentCount++;

      return {
        attendanceId: att._id,
        classId: att.classId?._id,
        className: att.classId?.name || "Classroom",
        subject: att.classId?.subject || "General",
        sessionDate: att.sessionDate,
        topic: att.topic,
        status,
        remarks: record?.remarks || "",
      };
    });

    const percentage = totalSessions > 0
      ? Math.round(((presentCount + (lateCount * 0.5)) / totalSessions) * 100)
      : 100;

    return res.json({
      success: true,
      data: {
        totalSessions,
        presentCount,
        absentCount,
        lateCount,
        percentage,
        sessions: studentHistory,
      },
    });
  } catch (error) {
    console.error("Get student attendance error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve student attendance",
    });
  }
};
