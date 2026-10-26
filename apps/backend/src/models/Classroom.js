const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, default: "" },
  code: { type: String, required: true, unique: true },
  teacherUid: { type: String, required: true },
  students: [String],
}, { timestamps: true, collection: "classrooms" });

module.exports = mongoose.models.Classroom || mongoose.model("Classroom", schema);
