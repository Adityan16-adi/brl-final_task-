const mongoose = require("mongoose");

const attendanceRecordSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  studentUid: {
    type: String,
    required: true,
  },
  studentName: {
    type: String,
    default: "Student",
  },
  status: {
    type: String,
    enum: ["present", "absent", "late", "excused"],
    default: "present",
  },
  remarks: {
    type: String,
    default: "",
  },
});

const attendanceSchema = new mongoose.Schema(
  {
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Classroom",
      required: true,
      index: true,
    },
    sessionDate: {
      type: Date,
      required: true,
      default: Date.now,
    },
    markedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    markedByUid: {
      type: String,
    },
    records: [attendanceRecordSchema],
    topic: {
      type: String,
      default: "Class Session",
    },
  },
  { timestamps: true }
);

attendanceSchema.index({ classId: 1, sessionDate: 1 });

module.exports = mongoose.model("Attendance", attendanceSchema);
