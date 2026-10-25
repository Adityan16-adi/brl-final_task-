const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
    uid: {
        type: String,
        required: true,
        unique: true
    },
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    role: {
        type: String,
        enum: ["teacher", "student"],
        default: "student"
    },
    passwordHash: {
        type: String,
        default: null,
        select: false
    }
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);
