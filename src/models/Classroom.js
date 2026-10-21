const mongoose = require("mongoose");

const classroomSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        default: ""
    },
    code: {
        type: String,
        required: true,
        unique: true
    },
    teacherUid: {
        type: String,
        required: true
    },
    students: [{
        type: String
    }]
}, { timestamps: true });

module.exports = mongoose.model("Classroom", classroomSchema);