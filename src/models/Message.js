const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema(
  {
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Classroom",
      required: true,
      index: true,
    },
    senderUid: {
      type: String,
      required: true,
    },
    senderName: {
      type: String,
      required: true,
      default: "User",
    },
    senderRole: {
      type: String,
      enum: ["teacher", "student"],
      default: "student",
    },
    text: {
      type: String,
      required: true,
      trim: true,
    },
    isSpam: {
      type: Boolean,
      default: false,
    },
    spamReasons: [String],
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Message", messageSchema);
