const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  role: { type: String, enum: ["teacher", "student"], default: "student" },
}, { timestamps: true, collection: "users" });

module.exports = mongoose.models.User || mongoose.model("User", schema);
