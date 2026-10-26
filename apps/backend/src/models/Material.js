const mongoose = require("mongoose");

const materialSchema = new mongoose.Schema(
  {
    classId: { type: mongoose.Schema.Types.ObjectId, ref: "Classroom", required: true },
    uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    type: { type: String, enum: ["image", "note", "video", "link"], default: "note" },
    fileUrl: { type: String, default: "" },
    filePublicId: { type: String, default: "" },
    thumbnailUrl: { type: String, default: "" },
    link: { type: String, default: "" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Material", materialSchema);
