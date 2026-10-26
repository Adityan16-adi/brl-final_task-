const mongoose = require("mongoose");

const sessionSchema = new mongoose.Schema(
  {
    classId: { type: mongoose.Schema.Types.ObjectId, ref: "Classroom", required: true },
    startedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, default: "Live class" },
    minMinutes: { type: Number, default: Number(process.env.ATTENDANCE_MIN_MINUTES) || 30 },
    isActive: { type: Boolean, default: true },
    endedAt: { type: Date },
    records: [
      {
        studentId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        firstJoinedAt: { type: Date },
        lastSeen: { type: Date },
        totalSeconds: { type: Number, default: 0 },
        status: { type: String, enum: ["joined", "present", "absent"], default: "joined" },
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model("ClassSession", sessionSchema);