const bcrypt = require("bcryptjs");
const User = require("../models/User");
const Classroom = require("../models/Classroom");
const Assignment = require("../models/Assignment");
const Material = require("../models/Material");

/**
 * Seeds demo teacher, student, classroom, and starter coursework
 * so that both the Flutter mobile app and web frontend can immediately
 * connect and demonstrate full functionality out of the box.
 */
async function seedDemoData() {
  try {
    if (process.env.NODE_ENV === "production" && !process.env.ENABLE_DEMO_SEED) {
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash("demo1234", salt);

    // 1. Seed Demo Teacher
    let teacher = await User.findOne({ email: "teacher@demo.com" });
    if (!teacher) {
      teacher = await User.create({
        uid: "demo-teacher",
        name: "Demo Teacher",
        email: "teacher@demo.com",
        role: "teacher",
        passwordHash,
      });
      console.log("🌱 Demo teacher account seeded: teacher@demo.com (demo1234)");
    }

    // 2. Seed Demo Student
    let student = await User.findOne({ email: "student@demo.com" });
    if (!student) {
      student = await User.create({
        uid: "demo-student",
        name: "Demo Student",
        email: "student@demo.com",
        role: "student",
        passwordHash,
      });
      console.log("🌱 Demo student account seeded: student@demo.com (demo1234)");
    }

    // 3. Seed Default Classroom
    let classroom = await Classroom.findOne({ code: "PHY101" });
    if (!classroom) {
      classroom = await Classroom.create({
        name: "Physics 101",
        subject: "Physics",
        description: "Introductory Mechanics and Physical Systems",
        schedule: "Mon, Wed, Fri 10:00 AM",
        code: "PHY101",
        teacherUid: teacher.uid,
        students: [student.uid],
      });
      console.log("🌱 Demo classroom seeded: Physics 101 (Code: PHY101)");
    }

    // 4. Seed Default Assignment
    let assignment = await Assignment.findOne({ classId: classroom._id });
    if (!assignment) {
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + 7);
      await Assignment.create({
        classId: classroom._id,
        title: "Newton's Laws Problem Set",
        description: "Solve problem sets 1 through 5 on friction and free-body diagrams.",
        dueDate,
        maxMarks: 100,
        createdBy: teacher._id,
        teacherUid: teacher.uid,
      });
      console.log("🌱 Demo assignment seeded: Newton's Laws Problem Set");
    }

    // 5. Seed Default Study Material
    let material = await Material.findOne({ classId: classroom._id });
    if (!material) {
      await Material.create({
        classId: classroom._id,
        title: "Lecture 1: Kinematics and Vectors",
        description: "Comprehensive notes covering velocity, acceleration, and 2D projectile motion.",
        type: "note",
        uploadedBy: teacher._id,
      });
      console.log("🌱 Demo material seeded: Lecture 1: Kinematics and Vectors");
    }
  } catch (err) {
    console.warn("⚠️ Demo data seeding note:", err.message);
  }
}

module.exports = seedDemoData;
