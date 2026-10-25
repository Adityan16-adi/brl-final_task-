const http = require("http");
const jwt = require("jsonwebtoken");
const connectDB = require("./config/db");

let API_BASE = process.env.API_BASE || "http://localhost:5000";

async function request(path, options = {}) {
  const url = `${API_BASE}${path}`;
  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {}),
  };

  const res = await fetch(url, {
    method: options.method || "GET",
    headers,
    body: options.body,
  });

  let data;
  try {
    data = await res.json();
  } catch (err) {
    data = null;
  }

  return { status: res.status, data };
}

async function runAuthSecurityTests() {
  console.log("=== STARTING AUTH & SECURITY TESTS ===");
  await connectDB();

  const { app } = require("./server");
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  API_BASE = `http://127.0.0.1:${port}`;
  console.log(`Test server running at ${API_BASE}`);
  let passed = 0;
  let total = 0;

  function assert(condition, message) {
    total++;
    if (!condition) {
      console.error(`❌ FAIL [Check ${total}]: ${message}`);
      throw new Error(`Assertion failed: ${message}`);
    } else {
      console.log(`✅ PASS [Check ${total}]: ${message}`);
      passed++;
    }
  }

  const timestamp = Date.now();
  const testStudentEmail = `student_${timestamp}@test.edu`;
  const testTeacherEmail = `teacher_${timestamp}@test.edu`;
  const testPassword = "SecurePassword123!";

  // 1. Missing fields in register
  const regMissing = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({ email: "", password: "123" }),
  });
  assert(regMissing.status === 400, "Registration rejects empty email with 400");

  // 2. Short password in register
  const regShortPass = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({ email: testStudentEmail, password: "123" }),
  });
  assert(regShortPass.status === 400, "Registration rejects short password (< 6 chars) with 400");

  // 3. Valid student registration
  const regStudent = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({
      email: testStudentEmail,
      password: testPassword,
      name: "Alice Student",
      role: "student",
    }),
  });
  assert(regStudent.status === 201, "Registration succeeds with 201");
  assert(!!regStudent.data.token, "Registration response includes signed JWT token");
  assert(regStudent.data.user.role === "student", "Registered student role matches");
  assert(!regStudent.data.user.passwordHash, "Password hash is never returned in registration response");
  const studentToken = regStudent.data.token;

  // 4. Duplicate registration rejected
  const regDup = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({
      email: testStudentEmail,
      password: testPassword,
      name: "Duplicate User",
    }),
  });
  assert(regDup.status === 409, "Duplicate email registration rejected with 409 Conflict");

  // 5. Login with invalid password
  const loginBadPass = await request("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ email: testStudentEmail, password: "WrongPassword" }),
  });
  assert(loginBadPass.status === 401, "Login with invalid password rejected with 401");

  // 6. Login with correct password
  const loginOk = await request("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ email: testStudentEmail, password: testPassword }),
  });
  assert(loginOk.status === 200, "Login with valid credentials succeeds with 200");
  assert(!!loginOk.data.token, "Login returns fresh JWT token");
  assert(!loginOk.data.user.passwordHash, "Password hash is never returned in login response");

  // 7. GET /api/auth/me with valid Bearer token
  const meRes = await request("/api/auth/me", {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  assert(meRes.status === 200, "GET /api/auth/me succeeds with 200 using Bearer JWT");
  assert(meRes.data.user.email === testStudentEmail, "GET /api/auth/me returns matching profile");
  assert(!meRes.data.user.passwordHash, "Password hash is never returned in me profile");

  // 8. GET /api/auth/me with invalid/tampered token
  const tamperedToken = studentToken.slice(0, -6) + "abcdef";
  const tamperedRes = await request("/api/auth/me", {
    headers: { Authorization: `Bearer ${tamperedToken}` },
  });
  assert(tamperedRes.status === 401, "Tampered JWT token rejected with 401");

  // 9. GET /api/auth/me without token
  const noTokenRes = await request("/api/auth/me");
  assert(noTokenRes.status === 401, "Missing Authorization token rejected with 401");

  // 10. Privilege Escalation Prevention: Self-assigning teacher role without code
  const regTeacherNoCode = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({
      email: `fake_teacher_${timestamp}@test.edu`,
      password: testPassword,
      name: "Sneaky User",
      role: "teacher",
    }),
  });
  assert(regTeacherNoCode.status === 403, "Teacher registration without provisioning code rejected with 403 Forbidden");

  // 11. Privilege Escalation Prevention: Teacher registration with wrong code
  const regTeacherBadCode = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({
      email: `fake_teacher2_${timestamp}@test.edu`,
      password: testPassword,
      name: "Sneaky User",
      role: "teacher",
      teacherCode: "WRONG_CODE_123",
    }),
  });
  assert(regTeacherBadCode.status === 403, "Teacher registration with invalid code rejected with 403 Forbidden");

  // 12. Legitimate Teacher registration with correct provisioning code
  const regTeacher = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({
      email: testTeacherEmail,
      password: testPassword,
      name: "Prof. Alan Turing",
      role: "teacher",
      teacherCode: process.env.TEACHER_SIGNUP_KEY || "TEACHER_INVITE_2026",
    }),
  });
  assert(regTeacher.status === 201, "Teacher registration with valid code succeeds with 201");
  assert(regTeacher.data.user.role === "teacher", "Teacher account has role 'teacher'");
  const teacherToken = regTeacher.data.token;

  // 13. Teacher creates classroom -> Should SUCCEED (201)
  const teacherClassroom = await request("/api/classrooms", {
    method: "POST",
    headers: { Authorization: `Bearer ${teacherToken}` },
    body: JSON.stringify({
      name: "Quantum Computing 101",
      subject: "Physics & CS",
      description: "Advanced topics in quantum algorithms",
      schedule: "Mon/Wed 10:00 AM",
    }),
  });
  assert(teacherClassroom.status === 201, "Teacher successfully creates classroom (201 Created)");
  const classroomId = teacherClassroom.data.classroom._id;

  // 14. Student tries to create classroom -> Should be FORBIDDEN (403)
  const studentClassroom = await request("/api/classrooms", {
    method: "POST",
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({
      name: "Hacker Classroom",
      subject: "Security",
    }),
  });
  assert(studentClassroom.status === 403, "Student is blocked from creating classroom with 403 Forbidden");

  // 15. LiveKit Room Token: Teacher requests token for their classroom
  // When LiveKit credentials are not in environment, safely returns 503 awaiting_credentials
  const liveKitRes = await request(`/api/classrooms/${classroomId}/meeting/token`, {
    method: "POST",
    headers: { Authorization: `Bearer ${teacherToken}` },
  });
  assert(
    liveKitRes.status === 503 && liveKitRes.data?.status === "awaiting_credentials",
    "LiveKit token generation returns 503 awaiting_credentials when provider keys are not yet configured"
  );

  // 16. LiveKit Room Token: Unauthenticated request rejected
  const unauthLiveKit = await request(`/api/classrooms/${classroomId}/meeting/token`, {
    method: "POST",
  });
  assert(unauthLiveKit.status === 401, "Unauthenticated meeting token request rejected with 401");

  // 17. LiveKit Room Token: Non-enrolled user rejected with 403
  const otherStudentEmail = `unregistered_student_${timestamp}@test.edu`;
  const regOther = await request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({
      email: otherStudentEmail,
      password: testPassword,
      name: "Other Student",
      role: "student",
    }),
  });
  const otherToken = regOther.data.token;
  const unenrolledLiveKit = await request(`/api/classrooms/${classroomId}/meeting/token`, {
    method: "POST",
    headers: { Authorization: `Bearer ${otherToken}` },
  });
  assert(unenrolledLiveKit.status === 403, "Unenrolled student requesting meeting token is rejected with 403 Forbidden");

  // 18. Production mode strictly rejects mock tokens
  const prevEnv = process.env.NODE_ENV;
  try {
    process.env.NODE_ENV = "production";
    const authMiddleware = require("./src/middleware/authMiddleware");
    let statusReturned = null;
    let jsonReturned = null;
    const mockReq = { headers: { authorization: "Bearer mock-jwt-token-teacher-1" } };
    const mockRes = {
      status(s) {
        statusReturned = s;
        return {
          json(j) {
            jsonReturned = j;
          },
        };
      },
    };
    await authMiddleware(mockReq, mockRes, () => {});
    assert(statusReturned === 401, "Production mode rejects mock tokens with 401 Unauthorized");
    assert(jsonReturned?.message?.includes("disabled in production"), "Production message explains mock tokens are disabled");

    // 19. Production mode rejects weak/missing JWT_SECRET safely
    let threwFatal = false;
    try {
      const prevSecret = process.env.JWT_SECRET;
      delete process.env.JWT_SECRET;
      authMiddleware.getJwtSecret();
      process.env.JWT_SECRET = prevSecret;
    } catch (err) {
      if (err.message?.includes("FATAL_AUTH_CONFIG")) {
        threwFatal = true;
      }
    }
    assert(threwFatal, "Production mode safely rejects unconfigured/weak JWT_SECRET with FATAL error");

    // 20. Production mode rejects default TEACHER_INVITE_2026 key
    const authController = require("./src/controllers/authController");
    const prevTeacherKey = process.env.TEACHER_SIGNUP_KEY;
    delete process.env.TEACHER_SIGNUP_KEY;

    let prodStatus = null;
    let prodJson = null;
    const mockTeacherReq = {
      body: {
        email: `prod_teacher_${Date.now()}@test.edu`,
        password: testPassword,
        name: "Prod Teacher",
        role: "teacher",
        teacherCode: "TEACHER_INVITE_2026",
      },
    };
    const mockTeacherRes = {
      status(s) {
        prodStatus = s;
        return {
          json(j) {
            prodJson = j;
          },
        };
      },
    };

    await authController.register(mockTeacherReq, mockTeacherRes);
    assert(prodStatus === 403, "Production mode strictly forbids TEACHER_INVITE_2026 and unconfigured teacher signup");
    assert(prodJson?.message?.includes("disabled in production"), "Production message explains teacher self-registration is disabled");

    // 21. Production mode with strong TEACHER_SIGNUP_KEY allows valid provisioning
    process.env.JWT_SECRET = "super_secure_production_jwt_secret_key_32_chars_or_more";
    process.env.TEACHER_SIGNUP_KEY = "super_secure_production_teacher_signup_key_2026";
    let validProdStatus = null;
    const validProdRes = {
      status(s) {
        validProdStatus = s;
        return { json() {} };
      },
    };
    await authController.register(
      {
        body: {
          email: `valid_prod_teacher_${Date.now()}@test.edu`,
          password: testPassword,
          name: "Authorized Teacher",
          role: "teacher",
          teacherCode: "super_secure_production_teacher_signup_key_2026",
        },
      },
      validProdRes
    );
    assert(validProdStatus === 201, "Production mode allows teacher registration when strong TEACHER_SIGNUP_KEY matches");
    process.env.TEACHER_SIGNUP_KEY = prevTeacherKey;
  } finally {
    process.env.NODE_ENV = prevEnv;
  }

  console.log(`\n========================================`);
  console.log(`🎉 ALL ${passed}/${total} AUTH, RBAC & LIVEKIT SECURITY CHECKS PASSED!`);
  console.log(`========================================\n`);
  process.exit(0);
}

runAuthSecurityTests().catch((err) => {
  console.error("Test execution failed:", err);
  process.exit(1);
});
