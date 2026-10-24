const { MongoMemoryServer } = require("mongodb-memory-server");
const mongoose = require("mongoose");
const http = require("http");

async function runTests() {
  console.log("=== STARTING BACKEND INTEGRATION TEST SUITE ===");

  const mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  process.env.MONGO_URI = uri;
  console.log("1. MongoMemoryServer started at:", uri);

  await mongoose.connect(uri);
  console.log("2. Mongoose connected to in-memory database.");

  // Import models
  const User = require("./src/models/User");
  const Classroom = require("./src/models/Classroom");
  const Assignment = require("./src/models/Assignment");
  const Submission = require("./src/models/Submission");
  const Material = require("./src/models/Material");
  const Notification = require("./src/models/Notification");

  // Create disposable test records
  const teacherUser = await User.create({
    uid: "teacher-uid-123",
    name: "Dr. Jane Smith",
    email: "teacher@example.com",
    role: "teacher",
  });

  const studentUser = await User.create({
    uid: "student-uid-456",
    name: "Alex Johnson",
    email: "student@example.com",
    role: "student",
  });

  const classroom = await Classroom.create({
    name: "Physics 101",
    description: "Introductory Mechanics",
    code: "PHY101",
    teacherUid: teacherUser.uid,
    students: [studentUser.uid],
  });

  console.log("3. Created test Users & Classroom:");
  console.log("   Teacher ID:", teacherUser._id.toString());
  console.log("   Student ID:", studentUser._id.toString());
  console.log("   Classroom ID:", classroom._id.toString());

  // Test root server endpoints
  const { app: rootApp } = require("./server");
  const rootServer = http.createServer(rootApp);
  await new Promise((resolve) => rootServer.listen(0, resolve));
  const rootPort = rootServer.address().port;
  const rootBase = `http://127.0.0.1:${rootPort}`;
  console.log("4. Root backend server listening on port:", rootPort);

  // Helper request
  async function api(path, options = {}) {
    const res = await fetch(`${rootBase}${path}`, {
      ...options,
      headers: options.body instanceof FormData
        ? (options.headers || {})
        : { "Content-Type": "application/json", ...(options.headers || {}) },
    });
    const json = await res.json().catch(() => ({}));
    return { status: res.status, ok: res.ok, data: json };
  }

  // Check 1: Health check
  const healthRes = await api("/api/health");
  console.log("Test 1: GET /api/health ->", healthRes.status, healthRes.data);
  if (healthRes.status !== 200 || healthRes.data.status !== "ok" || healthRes.data.database !== "connected") {
    throw new Error(`Health check failed: expected status 200 and database connected, got ${healthRes.status}`);
  }

  // Check 2: Protected without token -> 401 or 503 (fails closed)
  const protectedRes = await api("/protected");
  console.log("Test 2: GET /protected (no token) ->", protectedRes.status, protectedRes.data.message);
  if (protectedRes.status !== 401 && protectedRes.status !== 503) {
    throw new Error(`Expected protected endpoint to fail closed (401 or 503), got ${protectedRes.status}`);
  }

  // Check 3: Assignment Creation (without file)
  const newAssign = await api("/api/assignments", {
    method: "POST",
    body: JSON.stringify({
      classId: classroom._id,
      createdBy: teacherUser._id,
      title: "Newton's Laws Homework",
      description: "Complete problems 1 through 5",
      dueDate: new Date(Date.now() + 86400000).toISOString(),
      maxMarks: 50,
    }),
  });
  console.log("Test 3: POST /api/assignments ->", newAssign.status, newAssign.data.message);
  if (newAssign.status !== 201) throw new Error("Assignment creation failed");
  const assignmentId = newAssign.data.data._id;

  // Check 4: List Assignments by class
  const listAssign = await api(`/api/assignments/class/${classroom._id}`);
  console.log("Test 4: GET /api/assignments/class/:classId ->", listAssign.status, "Count:", listAssign.data.data.length);
  if (listAssign.status !== 200 || listAssign.data.data.length === 0) throw new Error("List assignments failed");

  // Check 5: Get Assignment by ID
  const getAssign = await api(`/api/assignments/${assignmentId}`);
  console.log("Test 5: GET /api/assignments/:id ->", getAssign.status, "Title:", getAssign.data.data.title);
  if (getAssign.status !== 200) throw new Error("Get assignment failed");

  // Check 6: Update Assignment
  const updateAssign = await api(`/api/assignments/${assignmentId}`, {
    method: "PUT",
    body: JSON.stringify({ title: "Newton's Laws Homework - Revised", maxMarks: 60 }),
  });
  console.log("Test 6: PUT /api/assignments/:id ->", updateAssign.status, "Updated title:", updateAssign.data.data?.title);
  if (updateAssign.status !== 200) throw new Error("Update assignment failed");

  // Check 7: Submit Assignment (text only, succeeds without Cloudinary)
  const submitRes = await api(`/api/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: JSON.stringify({
      studentId: studentUser._id,
      text: "Here is my completed Newton's laws homework solution.",
    }),
  });
  console.log("Test 7: POST /api/submissions/assignment/:id ->", submitRes.status, submitRes.data.message);
  if (submitRes.status !== 201) throw new Error("Text submission failed");
  const submissionId = submitRes.data.data._id;

  // Check 8: Resubmit Assignment (upsert updates existing record)
  const resubmitRes = await api(`/api/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: JSON.stringify({
      studentId: studentUser._id,
      text: "Here is my revised solution with extra steps shown.",
    }),
  });
  console.log("Test 8: POST /api/submissions/assignment/:id (resubmission) ->", resubmitRes.status, "Updated ID:", resubmitRes.data.data._id);
  if (resubmitRes.status !== 201 || resubmitRes.data.data._id !== submissionId) {
    throw new Error("Resubmission did not update existing submission");
  }

  // Check 9: File upload verification (503 if unconfigured, 201 if configured)
  const isCloudConfigured = require("./src/utils/uploadToCloudinary").isCloudinaryConfigured();
  const fileForm = new FormData();
  fileForm.append("studentId", studentUser._id.toString());
  fileForm.append("text", "Attempting file upload check");
  fileForm.append("file", new Blob(["dummy content"], { type: "text/plain" }), "solution.txt");
  const uploadRes = await api(`/api/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: fileForm,
  });
  console.log("Test 9: POST /api/submissions with file ->", uploadRes.status, uploadRes.data.message);
  if (isCloudConfigured) {
    if (uploadRes.status !== 201 && uploadRes.status !== 200) {
      throw new Error(`Expected HTTP 201 for configured storage upload, got ${uploadRes.status}`);
    }
  } else {
    if (uploadRes.status !== 503) {
      throw new Error(`Expected HTTP 503 for unconfigured storage upload, got ${uploadRes.status}`);
    }
  }

  // Check 10: Get Submissions for Assignment (Teacher view)
  const teacherSubs = await api(`/api/submissions/assignment/${assignmentId}`);
  console.log("Test 10: GET /api/submissions/assignment/:id ->", teacherSubs.status, "Count:", teacherSubs.data.data.length);
  if (teacherSubs.status !== 200) throw new Error("Teacher submissions failed");

  // Check 11: Get Student Submission (Student view)
  const studentSub = await api(`/api/submissions/assignment/${assignmentId}/student/${studentUser._id}`);
  console.log("Test 11: GET /api/submissions/assignment/:id/student/:studentId ->", studentSub.status, "Status:", studentSub.data.data.status);
  if (studentSub.status !== 200) throw new Error("Student submission retrieval failed");

  // Check 12: Grade Submission
  const gradeRes = await api(`/api/submissions/${submissionId}/grade`, {
    method: "PUT",
    body: JSON.stringify({
      marks: 55,
      feedback: "Great work on problem 3!",
    }),
  });
  console.log("Test 12: PUT /api/submissions/:id/grade ->", gradeRes.status, "Marks:", gradeRes.data.data.marks, "Status:", gradeRes.data.data.status);
  if (gradeRes.status !== 200 || gradeRes.data.data.status !== "graded") throw new Error("Grading failed");

  // Check 13: Notification verification (verify student received grade notification)
  const notifRes = await api(`/api/notifications/user/${studentUser._id}`);
  console.log("Test 13: GET /api/notifications/user/:userId ->", notifRes.status, "Count:", notifRes.data.data.length);
  if (notifRes.status !== 200 || notifRes.data.data.length === 0) throw new Error("Notification not generated");
  const notifId = notifRes.data.data[0]._id;

  // Check 14: Notification unread count
  const unreadRes = await api(`/api/notifications/user/${studentUser._id}/unread-count`);
  console.log("Test 14: GET /api/notifications/user/:userId/unread-count ->", unreadRes.status, "Unread:", unreadRes.data.data.count);

  // Check 15: Mark notification read
  const markReadRes = await api(`/api/notifications/${notifId}/read`, { method: "PUT" });
  console.log("Test 15: PUT /api/notifications/:id/read ->", markReadRes.status, "isRead:", markReadRes.data.data.isRead);

  // Check 16: Learning Materials (Link-based, succeeds without Cloudinary)
  const matRes = await api("/api/materials", {
    method: "POST",
    body: JSON.stringify({
      classId: classroom._id,
      uploadedBy: teacherUser._id,
      title: "Mechanics Lecture Slide Deck",
      description: "Week 1 slide deck on kinematics",
      link: "https://example.com/slides/week1",
    }),
  });
  console.log("Test 16: POST /api/materials (link-based) ->", matRes.status, matRes.data.message);
  if (matRes.status !== 201) throw new Error("Material creation failed");
  const matId = matRes.data.data._id;

  const matList = await api(`/api/materials/class/${classroom._id}`);
  console.log("Test 17: GET /api/materials/class/:classId ->", matList.status, "Count:", matList.data.data.length);

  const matGet = await api(`/api/materials/${matId}`);
  console.log("Test 18: GET /api/materials/:id ->", matGet.status, "Title:", matGet.data.data.title);

  // Check 19: Calendar Events
  const calRes = await api(`/api/calendar/class/${classroom._id}`);
  console.log("Test 19: GET /api/calendar/class/:classId ->", calRes.status, "Events:", calRes.data.data.length);
  if (calRes.status !== 200) throw new Error("Calendar retrieval failed");

  // === CLASSROOM CREATION & JOINING INTEGRATION CHECKS ===
  const teacherToken = "mock-jwt-token-teacher-uid-123";
  const studentToken = "mock-jwt-token-student-uid-456";

  // Check 20: Missing required fields on classroom creation are rejected
  const missingName = await api("/api/classrooms", {
    method: "POST",
    headers: { Authorization: `Bearer ${teacherToken}` },
    body: JSON.stringify({ subject: "Physics" }),
  });
  console.log("Test 20a: POST /api/classrooms (missing name) ->", missingName.status, missingName.data.message);
  if (missingName.status !== 400) throw new Error("Expected 400 for missing classroom name");

  const missingSubject = await api("/api/classrooms", {
    method: "POST",
    headers: { Authorization: `Bearer ${teacherToken}` },
    body: JSON.stringify({ name: "Quantum Mechanics" }),
  });
  console.log("Test 20b: POST /api/classrooms (missing subject) ->", missingSubject.status, missingSubject.data.message);
  if (missingSubject.status !== 400) throw new Error("Expected 400 for missing subject");

  // Check 21: Students cannot create classrooms
  const studentCreate = await api("/api/classrooms", {
    method: "POST",
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({ name: "Student Class", subject: "Study Group" }),
  });
  console.log("Test 21: POST /api/classrooms (student role) ->", studentCreate.status, studentCreate.data.message);
  if (studentCreate.status !== 403) throw new Error("Expected 403 when student attempts to create classroom");

  // Check 22: Teacher creates a class successfully
  const teacherCreate = await api("/api/classrooms", {
    method: "POST",
    headers: { Authorization: `Bearer ${teacherToken}` },
    body: JSON.stringify({
      name: "Advanced Astrophysics",
      subject: "Astronomy",
      description: "Cosmology, general relativity, and stellar evolution.",
      schedule: "Tue, Thu 02:00 PM",
    }),
  });
  console.log("Test 22: POST /api/classrooms (teacher) ->", teacherCreate.status, teacherCreate.data.message);
  if (teacherCreate.status !== 201 || !teacherCreate.data.classroom?.code) {
    throw new Error("Classroom creation failed or missing join code");
  }
  const createdClass = teacherCreate.data.classroom;
  const createdCode = createdClass.code;
  console.log("   Generated Join Code:", createdCode, "ID:", createdClass._id);

  // Check 23: Invalid code produces 404
  const invalidJoin = await api("/api/classrooms/join", {
    method: "POST",
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({ code: "NOTEXIST" }),
  });
  console.log("Test 23: POST /api/classrooms/join (invalid code) ->", invalidJoin.status, invalidJoin.data.message);
  if (invalidJoin.status !== 404) throw new Error("Expected 404 for invalid classroom code");

  // Check 24: Missing code produces 400
  const missingCode = await api("/api/classrooms/join", {
    method: "POST",
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({ code: "   " }),
  });
  console.log("Test 24: POST /api/classrooms/join (empty code) ->", missingCode.status, missingCode.data.message);
  if (missingCode.status !== 400) throw new Error("Expected 400 for empty classroom code");

  // Check 25: Teachers cannot join as students
  const teacherJoin = await api("/api/classrooms/join", {
    method: "POST",
    headers: { Authorization: `Bearer ${teacherToken}` },
    body: JSON.stringify({ code: createdCode }),
  });
  console.log("Test 25: POST /api/classrooms/join (teacher role) ->", teacherJoin.status, teacherJoin.data.message);
  if (teacherJoin.status !== 403) throw new Error("Expected 403 when teacher attempts to join classroom");

  // Check 26: Student joins using valid code
  const studentJoin = await api("/api/classrooms/join", {
    method: "POST",
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({ code: createdCode }),
  });
  console.log("Test 26: POST /api/classrooms/join (valid code) ->", studentJoin.status, studentJoin.data.message);
  if (studentJoin.status !== 200 || !studentJoin.data.classroom?.students?.includes("student-uid-456")) {
    throw new Error("Student join failed or student not added to classroom list");
  }

  // Check 27: Duplicate enrollment is rejected with 409
  const duplicateJoin = await api("/api/classrooms/join", {
    method: "POST",
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({ code: createdCode }),
  });
  console.log("Test 27: POST /api/classrooms/join (duplicate) ->", duplicateJoin.status, duplicateJoin.data.message);
  if (duplicateJoin.status !== 409) throw new Error("Expected 409 for duplicate classroom enrollment");

  // Check 28: Class list refresh for teacher and student
  const teacherClasses = await api("/api/classrooms", {
    headers: { Authorization: `Bearer ${teacherToken}` },
  });
  console.log("Test 28a: GET /api/classrooms (teacher) ->", teacherClasses.status, "Count:", teacherClasses.data.count);
  const foundInTeacher = teacherClasses.data.classrooms.find((c) => c.code === createdCode);
  if (!foundInTeacher || foundInTeacher.studentCount !== 1) {
    throw new Error("Created classroom not found in teacher class list with correct studentCount");
  }

  const studentClasses = await api("/api/classrooms", {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  console.log("Test 28b: GET /api/classrooms (student) ->", studentClasses.status, "Count:", studentClasses.data.count);
  const foundInStudent = studentClasses.data.classrooms.find((c) => c.code === createdCode);
  if (!foundInStudent) throw new Error("Joined classroom not found in student class list");

  // Check 29: Class details by ID returns join code and enrolled student list
  const classDetails = await api(`/api/classrooms/${createdClass._id}`, {
    headers: { Authorization: `Bearer ${teacherToken}` },
  });
  console.log("Test 29: GET /api/classrooms/:id ->", classDetails.status, "Enrolled students:", classDetails.data.classroom?.studentProfiles?.length);
  if (classDetails.status !== 200 || !classDetails.data.classroom?.studentProfiles?.some((s) => s.uid === "student-uid-456")) {
    throw new Error("Classroom details missing enrolled student profiles");
  }

  // Clean up disposable records
  await api(`/api/materials/${matId}`, { method: "DELETE" });
  await api(`/api/assignments/${assignmentId}`, { method: "DELETE" });

  rootServer.close();
  await mongoose.disconnect();
  await mongod.stop();

  console.log("=== ALL 29 BACKEND INTEGRATION CHECKS PASSED SUCCESSFULLY! ===");
}

runTests().catch((err) => {
  console.error("Test failure:", err);
  process.exit(1);
});
