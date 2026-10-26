const mongoose = require("mongoose");
const Attendance = require("../models/Attendance");
const User = require("../models/User");
const { classAccess } = require("../utils/classAccess");

// GET /api/attendance/class/:classId?date=YYYY-MM-DD
exports.getClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;
    const access = await classAccess(classId, req.user);
    if (access.status) {
      return res.status(access.status).json({ success: false, message: access.message });
    }

    const classroom = access.classroom;
    const { date } = req.query;

    if (date && (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(date)))) {
      return res.status(400).json({ success: false, message: "date must be in YYYY-MM-DD format." });
    }

    const enrolledStudents = await User.find({ uid: { $in: classroom.students || [] } })
      .select("uid name email")
      .lean();

    const query = { classId };
    if (date) query.date = date;

    const records = await Attendance.find(query).sort({ date: -1, studentName: 1 }).lean();

    return res.json({
      success: true,
      data: {
        className: classroom.name,
        students: enrolledStudents.map((s) => ({
          id: s.uid,
          name: s.name,
          email: s.email,
        })),
        records,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/attendance/class/:classId
exports.recordClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;
    const access = await classAccess(classId, req.user);
    if (access.status) {
      return res.status(access.status).json({ success: false, message: access.message });
    }

    if (!access.teacher) {
      return res.status(403).json({ success: false, message: "Only the class teacher can record attendance." });
    }

    const { date, records } = req.body || {};

    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(date))) {
      return res.status(400).json({ success: false, message: "date is required and must be in YYYY-MM-DD format." });
    }

    if (!Array.isArray(records) || records.length === 0) {
      return res.status(400).json({ success: false, message: "records must be a non-empty array." });
    }

    const validStatuses = new Set(["Present", "Absent", "Late", "Excused"]);
    const enrolledSet = new Set(access.classroom.students || []);

    for (const item of records) {
      if (!item.studentId || typeof item.studentId !== "string") {
        return res.status(400).json({ success: false, message: "Each record must include a valid studentId string." });
      }
      if (!validStatuses.has(item.status)) {
        return res.status(400).json({ success: false, message: `Invalid status '${item.status}'. Must be Present, Absent, Late, or Excused.` });
      }
      if (!enrolledSet.has(item.studentId)) {
        return res.status(400).json({ success: false, message: `Student '${item.studentId}' is not enrolled in this class.` });
      }
    }

    const studentDocs = await User.find({ uid: { $in: access.classroom.students || [] } })
      .select("uid name")
      .lean();
    const nameMap = Object.fromEntries(studentDocs.map((s) => [s.uid, s.name]));

    const operations = [];
    for (const item of records) {
      operations.push(
        Attendance.findOneAndUpdate(
          { classId, studentId: item.studentId, date },
          {
            classId,
            studentId: item.studentId,
            studentName: item.studentName || nameMap[item.studentId] || item.studentId,
            date,
            status: item.status,
            recordedBy: req.user.uid,
          },
          { upsert: true, new: true, runValidators: true }
        )
      );
    }

    await Promise.all(operations);

    const updated = await Attendance.find({ classId, date }).sort({ studentName: 1 }).lean();
    return res.status(200).json({
      success: true,
      message: "Attendance saved successfully.",
      data: updated,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/attendance/student/me
exports.getStudentAttendance = async (req, res) => {
  try {
    const studentId = req.user.uid;
    const { classId } = req.query;

    if (classId) {
      const access = await classAccess(classId, req.user);
      if (access.status) {
        return res.status(access.status).json({ success: false, message: access.message });
      }
    }

    const query = { studentId };
    if (classId) query.classId = classId;

    const records = await Attendance.find(query).sort({ date: -1 }).lean();
    return res.json({ success: true, data: records });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
