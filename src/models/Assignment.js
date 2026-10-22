const mongoose = require("mongoose");

const assignmentSchema = new mongoose.Schema(
  {
    fileUrl: String,
filePublicId: String,
fileResourceType: String,
    classId: { type: mongoose.Schema.Types.ObjectId, ref: "Classroom", required: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    dueDate: { type: Date, required: true },
    maxMarks: { type: Number, default: 100 },
    attachments: [{ name: String, url: String }],
  },
  { timestamps: true }
);

module.exports = mongoose.model("Assignment", assignmentSchema);