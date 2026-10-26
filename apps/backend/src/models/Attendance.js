const mongoose = require("mongoose");

const attendanceSchema = new mongoose.Schema(
  {
    classId: { type: mongoose.Schema.Types.ObjectId, ref: "Classroom", required: true },
    studentId: { type: String, required: true, trim: true },
    studentName: { type: String, default: "", trim: true },
    date: { type: String, required: true, match: /^\d{4}-\d{2}-\d{2}$/ },
    status: {
      type: String,
      enum: ["Present", "Absent", "Late", "Excused"],
      default: "Present",
      required: true,
    },
    recordedBy: { type: String, required: true },
  },
  { timestamps: true }
);

// Prevent duplicate records for the same student, class, and date
attendanceSchema.index({ classId: 1, studentId: 1, date: 1 }, { unique: true });

module.exports = mongoose.models.Attendance || mongoose.model("Attendance", attendanceSchema);

