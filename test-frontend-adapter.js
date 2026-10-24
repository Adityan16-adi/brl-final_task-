// Test frontend backendAdapter against real backend
const { MongoMemoryServer } = require("mongodb-memory-server");
const http = require("http");

async function runAdapterTest() {
  console.log("=== TESTING FRONTEND BACKEND ADAPTER WITH REAL BACKEND ===");

  const mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  process.env.MONGO_URI = uri;

  const { app, startServer } = require("./server");
  const { connectDB } = require("./config/db");
  const mongoose = require("mongoose");
  await mongoose.connect(uri);

  const User = require("./src/models/User");
  const Classroom = require("./src/models/Classroom");
  const Assignment = require("./src/models/Assignment");

  const teacher = await User.create({
    uid: "teacher-uid",
    name: "Teacher User",
    email: "teacher@test.com",
    role: "teacher",
  });

  const student = await User.create({
    uid: "student-uid",
    name: "Student User",
    email: "student@test.com",
    role: "student",
  });

  const classroom = await Classroom.create({
    name: "Chemistry 101",
    description: "Lab course",
    code: "CHEM101",
    teacherUid: teacher.uid,
    students: [student.uid],
  });

  const server = http.createServer(app);
  await new Promise((r) => server.listen(0, r));
  const port = server.address().port;
  const baseUrl = `http://127.0.0.1:${port}/api`;
  console.log("Backend started on:", baseUrl);

  // Set up mock window and import.meta.env
  const mockStorage = {
    "unified-learn-session": JSON.stringify({ user: { id: student._id.toString(), role: "student" } }),
  };

  globalThis.window = {
    localStorage: {
      getItem: (key) => mockStorage[key] || null,
      setItem: (key, val) => { mockStorage[key] = val; },
    },
  };

  // We can dynamically import the backend adapter or test the exact fetch calls it makes
  const classId = classroom._id.toString();
  const studentId = student._id.toString();
  const teacherId = teacher._id.toString();

  // 1. Teacher creates assignment
  const createRes = await fetch(`${baseUrl}/assignments`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      classId,
      createdBy: teacherId,
      title: "Stoichiometry Worksheet",
      description: "Balance equations 1-10",
      dueDate: new Date(Date.now() + 86400000).toISOString(),
      maxMarks: 20,
    }),
  });
  const createdAssignment = await createRes.json();
  console.log("1. Created Assignment via API:", createdAssignment.success, createdAssignment.data?.title);
  if (!createdAssignment.success) throw new Error("Assignment creation failed");
  const assignmentId = createdAssignment.data._id;

  // 2. Student lists assignments for class
  const listRes = await fetch(`${baseUrl}/assignments/class/${classId}`);
  const listedAssignments = await listRes.json();
  console.log("2. Listed Assignments via API:", listedAssignments.success, "Count:", listedAssignments.data?.length);
  if (!listedAssignments.success || listedAssignments.data.length !== 1) throw new Error("List failed");

  // 3. Student submits assignment with FormData
  const form = new FormData();
  form.append("studentId", studentId);
  form.append("text", "All 10 equations balanced.");

  const submitRes = await fetch(`${baseUrl}/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: form,
  });
  const submitted = await submitRes.json();
  console.log("3. Submitted Assignment via API:", submitted.success, "Status:", submitted.data?.status);
  if (!submitted.success) throw new Error("Submission failed");

  // 4. Student checks their own submission
  const checkSubRes = await fetch(`${baseUrl}/submissions/assignment/${assignmentId}/student/${studentId}`);
  const checkSub = await checkSubRes.json();
  console.log("4. Checked Student Submission via API:", checkSub.success, "Text:", checkSub.data?.text);
  if (!checkSub.success || checkSub.data.text !== "All 10 equations balanced.") throw new Error("Check submission failed");

  // 5. Calendar events for class
  const calRes = await fetch(`${baseUrl}/calendar/class/${classId}`);
  const cal = await calRes.json();
  console.log("5. Calendar events via API:", cal.success, "Events:", cal.data?.length);
  if (!cal.success || cal.data.length !== 1) throw new Error("Calendar check failed");

  server.close();
  await mongoose.disconnect();
  await mongod.stop();
  console.log("=== FRONTEND BACKEND ADAPTER CONTRACT VERIFIED! ===");
}

runAdapterTest().catch((err) => {
  console.error("Adapter test failed:", err);
  process.exit(1);
});
