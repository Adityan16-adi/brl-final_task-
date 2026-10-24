const { MongoMemoryServer } = require("mongodb-memory-server");
const mongoose = require("mongoose");
const http = require("http");

async function runTests() {
  console.log("=== STARTING APPS/BACKEND INTEGRATION TEST SUITE ===");

  const mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  process.env.MONGO_URI = uri;
  console.log("1. MongoMemoryServer started at:", uri);

  const { connectDB } = require("./apps/backend/src/server");
  await connectDB();
  console.log("2. apps/backend Mongoose connected.");

  // apps/backend has its own isolated mongoose instance in its node_modules
  let appsMongoose;
  try {
    appsMongoose = require("./apps/backend/node_modules/mongoose");
  } catch {
    appsMongoose = mongoose;
  }

  const { app } = require("./apps/backend/src/server");
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}`;
  console.log("3. apps/backend listening on port:", port);

  async function api(path, options = {}) {
    const res = await fetch(`${base}${path}`, {
      ...options,
      headers: options.body instanceof FormData
        ? (options.headers || {})
        : { "Content-Type": "application/json", ...(options.headers || {}) },
    });
    const json = await res.json().catch(() => ({}));
    return { status: res.status, ok: res.ok, data: json };
  }

  // Test 1: Health check
  const healthRes = await api("/api/health");
  console.log("Test 1: GET /api/health ->", healthRes.status, healthRes.data);
  if (healthRes.status !== 200 || healthRes.data.status !== "ok" || healthRes.data.database !== "connected") {
    throw new Error(`Health check failed: expected status 200 and database connected, got ${healthRes.status}`);
  }

  const dummyClassId = new mongoose.Types.ObjectId();
  const dummyTeacherId = new mongoose.Types.ObjectId();
  const dummyStudentId = new mongoose.Types.ObjectId();

  // Test 2: Create Assignment
  const assignRes = await api("/api/assignments", {
    method: "POST",
    body: JSON.stringify({
      classId: dummyClassId,
      createdBy: dummyTeacherId,
      title: "Chemistry Lab Report",
      description: "Submit PDF report",
      dueDate: new Date(Date.now() + 86400000).toISOString(),
      maxMarks: 100,
    }),
  });
  console.log("Test 2: POST /api/assignments ->", assignRes.status, assignRes.data.message);
  if (assignRes.status !== 201) throw new Error("Assignment creation failed");
  const assignmentId = assignRes.data.data._id;

  // Test 3: List assignments
  const listRes = await api(`/api/assignments/class/${dummyClassId}`);
  console.log("Test 3: GET /api/assignments/class/:classId ->", listRes.status, "Count:", listRes.data.data.length);
  if (listRes.status !== 200 || listRes.data.data.length !== 1) throw new Error("List assignments failed");

  // Test 4: Submit assignment (text only, succeeds without Cloudinary)
  const subRes = await api(`/api/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: JSON.stringify({
      studentId: dummyStudentId,
      text: "Lab report text submission",
    }),
  });
  console.log("Test 4: POST /api/submissions/assignment/:id (text only) ->", subRes.status, subRes.data.message);
  if (subRes.status !== 201) throw new Error("Submission failed");
  const submissionId = subRes.data.data._id;

  // Test 5: Resubmit assignment (updates existing submission)
  const resubRes = await api(`/api/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: JSON.stringify({
      studentId: dummyStudentId,
      text: "Lab report text submission - revision 2",
    }),
  });
  console.log("Test 5: POST /api/submissions/assignment/:id (resubmit) ->", resubRes.status, "ID:", resubRes.data.data._id);
  if (resubRes.status !== 201 || resubRes.data.data._id !== submissionId) {
    throw new Error("Resubmission did not update existing submission");
  }

  // Test 6: File upload verification (503 if unconfigured, 201 if configured)
  const isCloudConfigured = require("./apps/backend/src/utils/uploadToCloudinary").isCloudinaryConfigured();
  const fileForm = new FormData();
  fileForm.append("studentId", dummyStudentId.toString());
  fileForm.append("text", "Attempting file upload check");
  fileForm.append("file", new Blob(["dummy report"], { type: "application/pdf" }), "report.pdf");
  const uploadRes = await api(`/api/submissions/assignment/${assignmentId}`, {
    method: "POST",
    body: fileForm,
  });
  console.log("Test 6: POST /api/submissions with file ->", uploadRes.status, uploadRes.data.message);
  if (isCloudConfigured) {
    if (uploadRes.status !== 201 && uploadRes.status !== 200) {
      throw new Error(`Expected HTTP 201 for configured storage upload, got ${uploadRes.status}`);
    }
  } else {
    if (uploadRes.status !== 503) {
      throw new Error(`Expected HTTP 503 for unconfigured storage upload, got ${uploadRes.status}`);
    }
  }

  // Test 7: Create Material (link based, succeeds without Cloudinary)
  const matRes = await api("/api/materials", {
    method: "POST",
    body: JSON.stringify({
      classId: dummyClassId,
      uploadedBy: dummyTeacherId,
      title: "Chemistry Syllabus",
      link: "https://example.com/syllabus",
    }),
  });
  console.log("Test 7: POST /api/materials (link-based) ->", matRes.status, matRes.data.message);
  if (matRes.status !== 201) throw new Error("Material creation failed");
  const matId = matRes.data.data._id;

  // Test 8: List materials
  const matList = await api(`/api/materials/class/${dummyClassId}`);
  console.log("Test 8: GET /api/materials/class/:classId ->", matList.status, "Count:", matList.data.data.length);
  if (matList.status !== 200 || matList.data.data.length !== 1) throw new Error("List materials failed");

  // Test 9: Calendar events
  const calRes = await api(`/api/calendar/class/${dummyClassId}`);
  console.log("Test 9: GET /api/calendar/class/:classId ->", calRes.status, "Events:", calRes.data.data.length);
  if (calRes.status !== 200) throw new Error("Calendar failed");

  // Clean up
  await api(`/api/materials/${matId}`, { method: "DELETE" });
  await api(`/api/assignments/${assignmentId}`, { method: "DELETE" });

  server.close();
  if (appsMongoose && appsMongoose.disconnect) {
    await appsMongoose.disconnect();
  }
  await mongoose.disconnect();
  await mongod.stop();

  console.log("=== ALL 9 APPS/BACKEND INTEGRATION TESTS PASSED SUCCESSFULLY! ===");
}

runTests().catch((err) => {
  console.error("Test failure in apps/backend:", err);
  process.exit(1);
});
