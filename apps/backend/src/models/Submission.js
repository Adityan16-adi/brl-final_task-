const mongoose = require("mongoose");

const submissionAttachmentSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    name: { type: String, default: "" },
    publicId: { type: String, default: "" },
    resourceType: { type: String, default: "raw" },
    fileType: { type: String, default: "" },
    size: { type: Number, default: 0 },
  },
  { _id: false }
);

const submissionSchema = new mongoose.Schema(
  {
    assignmentId: { type: mongoose.Schema.Types.ObjectId, ref: "Assignment", required: true },
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    text: { type: String, default: "" },
    link: { type: String, default: "" },
    fileUrl: { type: String, default: "" },
    filePublicId: { type: String, default: "" },
    fileResourceType: { type: String, default: "" },
    attachments: [submissionAttachmentSchema],
    submittedAt: { type: Date, default: Date.now },
    isLate: { type: Boolean, default: false },
    marks: { type: Number, default: null },
    feedback: { type: String, default: "" },
    status: { type: String, enum: ["submitted", "graded"], default: "submitted" },
  },
  { timestamps: true }
);

// one submission per student per assignment
submissionSchema.index({ assignmentId: 1, studentId: 1 }, { unique: true });

module.exports = mongoose.model("Submission", submissionSchema);
