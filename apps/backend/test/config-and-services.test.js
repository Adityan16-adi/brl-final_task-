const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");

const env = require("../src/config/env");

test("environment file path is anchored to apps/backend, not the caller cwd", () => {
  assert.equal(env.envPath, path.resolve(__dirname, "../.env"));
});

test("startup validation identifies required settings without printing values", () => {
  const names = ["MONGO_URI", "CLOUDINARY_CLOUD_NAME", "CLOUDINARY_API_KEY", "CLOUDINARY_API_SECRET", "FIREBASE_PROJECT_ID"];
  const tracked = [...names, "PORT"];
  const previous = Object.fromEntries(tracked.map((name) => [name, process.env[name]]));
  try {
    for (const name of names) delete process.env[name];
    assert.throws(() => env.validateEnv(), /MONGO_URI.*FIREBASE_PROJECT_ID/);
    Object.assign(process.env, {
      MONGO_URI: "mongodb://example.invalid/test",
      CLOUDINARY_CLOUD_NAME: "test-cloud",
      CLOUDINARY_API_KEY: "test-key",
      CLOUDINARY_API_SECRET: "test-secret",
      FIREBASE_PROJECT_ID: "test-project",
      PORT: "5000",
    });
    assert.deepEqual(env.validateEnv(), { port: 5000 });
    process.env.PORT = "70000";
    assert.throws(() => env.validateEnv(), /PORT must be an integer/);
  } finally {
    for (const name of tracked) {
      if (previous[name] === undefined) delete process.env[name];
      else process.env[name] = previous[name];
    }
  }
});

test("Cloudinary upload helper resolves its in-service configuration module", () => {
  const pathToConfig = require.resolve("../src/config/cloudinary");
  assert.equal(pathToConfig, path.resolve(__dirname, "../src/config/cloudinary.js"));
  assert.equal(typeof require("../src/utils/uploadToCloudinary"), "function");
});

test("protected API rejects requests without a Firebase token", async () => {
  const authenticate = require("../src/middleware/authenticate");
  const response = { statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
  await authenticate({ headers: {} }, response, () => assert.fail("next must not run"));
  assert.equal(response.statusCode, 401);
  assert.match(response.body.message, /Firebase ID token/);
});

test("class access validates ObjectIds and checks server-side membership", async (t) => {
  const Classroom = require("../src/models/Classroom");
  const original = Classroom.findById;
  t.after(() => { Classroom.findById = original; });
  const classDoc = { teacherUid: "teacher-uid", students: ["student-uid"] };
  Classroom.findById = async () => classDoc;
  const { classAccess } = require("../src/utils/classAccess");
  assert.equal((await classAccess("invalid", { uid: "teacher-uid" })).status, 400);
  const teacher = await classAccess("507f1f77bcf86cd799439011", { uid: "teacher-uid" });
  assert.equal(teacher.teacher, true);
  const student = await classAccess("507f1f77bcf86cd799439011", { uid: "student-uid" });
  assert.equal(student.student, true);
  assert.equal((await classAccess("507f1f77bcf86cd799439011", { uid: "outsider" })).status, 403);
});

test("ML client forwards the Python response contract", async (t) => {
  const originalFetch = global.fetch;
  const originalUrl = process.env.ML_SERVICE_URL;
  t.after(() => {
    global.fetch = originalFetch;
    if (originalUrl === undefined) delete process.env.ML_SERVICE_URL;
    else process.env.ML_SERVICE_URL = originalUrl;
  });

  process.env.ML_SERVICE_URL = "http://127.0.0.1:8001";
  let requested;
  global.fetch = async (url, options) => {
    requested = { url, body: JSON.parse(options.body) };
    return { ok: true, json: async () => ({ reply: "A real model response" }) };
  };
  const { mlRequest } = require("../src/services/mlClient");
  const payload = await mlRequest("/mentor/chat", { session_id: "s", message: "question" });
  assert.equal(requested.url, "http://127.0.0.1:8001/mentor/chat");
  assert.deepEqual(requested.body, { session_id: "s", message: "question" });
  assert.deepEqual(payload, { reply: "A real model response" });
});

test("ML client defaults to the deployed Render URL when ML_SERVICE_URL is unset", async (t) => {
  const originalFetch = global.fetch;
  const originalUrl = process.env.ML_SERVICE_URL;
  t.after(() => {
    global.fetch = originalFetch;
    if (originalUrl === undefined) delete process.env.ML_SERVICE_URL;
    else process.env.ML_SERVICE_URL = originalUrl;
  });

  delete process.env.ML_SERVICE_URL;
  let requestedUrl;
  global.fetch = async (url) => {
    requestedUrl = url;
    return { ok: true, json: async () => ({ reply: "ok" }) };
  };
  const { mlRequest } = require("../src/services/mlClient");
  await mlRequest("/mentor/chat", { session_id: "s", message: "question" });
  assert.equal(requestedUrl, "https://brl-final-task.onrender.com/mentor/chat");
});

test("ML client reports unavailable service rather than synthesizing a response", async (t) => {
  const originalFetch = global.fetch;
  t.after(() => { global.fetch = originalFetch; });
  global.fetch = async () => { throw new TypeError("fetch failed"); };
  const { mlRequest } = require("../src/services/mlClient");
  await assert.rejects(mlRequest("/mentor/chat", {}), { status: 503, message: /ML service is unavailable/ });
});

test("ML client forwards X-API-Key and X-User-Id headers", async (t) => {
  const originalFetch = global.fetch;
  const originalToken = process.env.ML_API_TOKEN;
  t.after(() => {
    global.fetch = originalFetch;
    if (originalToken === undefined) delete process.env.ML_API_TOKEN;
    else process.env.ML_API_TOKEN = originalToken;
  });

  process.env.ML_API_TOKEN = "test-ml-key";
  let capturedHeaders;
  global.fetch = async (_url, options) => {
    capturedHeaders = options.headers;
    return { ok: true, json: async () => ({ reply: "ok" }) };
  };

  const { mlRequest } = require("../src/services/mlClient");
  await mlRequest("/mentor/chat", { message: "hi" }, { userId: "verified-user-456" });
  assert.equal(capturedHeaders["X-API-Key"], "test-ml-key");
  assert.equal(capturedHeaders["X-User-Id"], "verified-user-456");
  assert.equal(capturedHeaders["Content-Type"], "application/json");
});

test("ML client maps upstream 401, 429, and timeout errors properly", async (t) => {
  const originalFetch = global.fetch;
  t.after(() => { global.fetch = originalFetch; });

  const { mlRequest } = require("../src/services/mlClient");

  // 401 Unauthorized -> 502 Bad Gateway
  global.fetch = async () => ({
    ok: false,
    status: 401,
    json: async () => ({ detail: "Missing or invalid API key." }),
  });
  await assert.rejects(mlRequest("/mentor/chat", {}), {
    status: 502,
    message: /ML service authentication failed/,
  });

  // 429 Rate Limit -> 429
  global.fetch = async () => ({
    ok: false,
    status: 429,
    json: async () => ({ detail: "Rate limit reached" }),
  });
  await assert.rejects(mlRequest("/mentor/chat", {}), {
    status: 429,
    message: /rate limit reached/,
  });

  // AbortError -> 504 Gateway Timeout
  global.fetch = async () => {
    const error = new Error("The operation was aborted");
    error.name = "AbortError";
    throw error;
  };
  await assert.rejects(mlRequest("/mentor/chat", {}), {
    status: 504,
    message: /timed out/,
  });
});

test("study routes enforce course access and generate verified session IDs", async (t) => {
  const Classroom = require("../src/models/Classroom");
  const originalFindById = Classroom.findById;
  const originalFetch = global.fetch;
  t.after(() => {
    Classroom.findById = originalFindById;
    global.fetch = originalFetch;
  });

  Classroom.findById = async (id) => {
    if (id === "507f1f77bcf86cd799439011") {
      return { teacherUid: "teacher-uid", students: ["student-uid"] };
    }
    return null;
  };

  let forwardedBody;
  global.fetch = async (_url, options) => {
    forwardedBody = JSON.parse(options.body);
    return { ok: true, json: async () => ({ reply: "AI mentor answer" }) };
  };

  const studyRoutes = require("../src/routes/studyRoutes");
  // Find the mentor handler: layer with route.path === '/mentor'
  const mentorLayer = studyRoutes.stack.find((l) => l.route?.path === "/mentor");
  assert.ok(mentorLayer, "mentor route exists");
  const mentorHandler = mentorLayer.route.stack[0].handle;

  // 1. Outsider trying to claim course
  const outsiderRes = { statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(b) { this.body = b; return this; } };
  await mentorHandler(
    { body: { message: "hello", courseId: "507f1f77bcf86cd799439011" }, user: { uid: "outsider-uid" } },
    outsiderRes
  );
  assert.equal(outsiderRes.statusCode, 403);
  assert.match(outsiderRes.body.message, /not a member/);

  // 2. Enrolled student with verified course access
  const studentRes = { statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(b) { this.body = b; return this; } };
  await mentorHandler(
    { body: { message: "explain photosynthesis", courseId: "507f1f77bcf86cd799439011", sessionId: "chat-tab-1" }, user: { uid: "student-uid" } },
    studentRes
  );
  assert.equal(studentRes.statusCode, 200);
  assert.equal(studentRes.body.data.text, "AI mentor answer");
  assert.equal(forwardedBody.course_id, "507f1f77bcf86cd799439011");
  assert.match(forwardedBody.session_id, /^u_student-uid_c_507f1f77bcf86cd799439011/);
});

test("attendance recording enforces teacher authorization and validates input", async (t) => {
  const Classroom = require("../src/models/Classroom");
  const originalFindById = Classroom.findById;
  t.after(() => { Classroom.findById = originalFindById; });
  Classroom.findById = async () => ({
    name: "Biology 10",
    teacherUid: "teacher-uid",
    students: ["student-uid"],
  });

  const { recordClassAttendance } = require("../src/controllers/attendanceController");

  // Non-teacher student trying to record attendance
  const studentRes = { statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(b) { this.body = b; return this; } };
  await recordClassAttendance(
    { params: { classId: "507f1f77bcf86cd799439011" }, user: { uid: "student-uid" }, body: { date: "2026-10-25", records: [{ studentId: "student-uid", status: "Present" }] } },
    studentRes
  );
  assert.equal(studentRes.statusCode, 403);
  assert.match(studentRes.body.message, /Only the class teacher/);

  // Teacher providing invalid status
  const teacherRes = { statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(b) { this.body = b; return this; } };
  await recordClassAttendance(
    { params: { classId: "507f1f77bcf86cd799439011" }, user: { uid: "teacher-uid" }, body: { date: "2026-10-25", records: [{ studentId: "student-uid", status: "InvalidStatus" }] } },
    teacherRes
  );
  assert.equal(teacherRes.statusCode, 400);
  assert.match(teacherRes.body.message, /Invalid status/);
});
