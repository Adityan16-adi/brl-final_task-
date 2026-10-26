const mongoose = require("mongoose");
const Classroom = require("../models/Classroom");

async function classAccess(classId, user) {
  if (!mongoose.isValidObjectId(classId)) return { status: 400, message: "classId must be a valid MongoDB ObjectId." };
  const classroom = await Classroom.findById(classId);
  if (!classroom) return { status: 404, message: "Class not found." };
  const teacher = classroom.teacherUid === user.uid;
  const student = classroom.students.includes(user.uid);
  if (!teacher && !student) return { status: 403, message: "You are not a member of this class." };
  return { classroom, teacher, student };
}

module.exports = { classAccess };
