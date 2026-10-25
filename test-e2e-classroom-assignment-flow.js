/**
 * End-to-End Verification Test for Classroom Creation, Enrollment, and Assignment Flow
 * Validates the complete lifecycle required by the mobile and web clients against the live server.
 */

const http = require("http");
const { app, server, startServer } = require("./server");

async function runE2ETests() {
  console.log("=== STARTING FULL END-TO-END FLOW VERIFICATION ===");

  await startServer();
  const port = process.env.PORT || 5000;
  const baseUrl = `http://127.0.0.1:${port}`;

  const teacherToken = "mock-jwt-token-mock-teacher-01";
  const studentToken = "mock-jwt-token-mock-student-01";

  function request(path, options = {}) {
    return new Promise((resolve, reject) => {
      const url = new URL(path, baseUrl);
      const reqOptions = {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method: options.method || "GET",
        headers: options.headers || {},
      };

      const req = http.request(reqOptions, (res) => {
        let raw = "";
        res.on("data", (chunk) => (raw += chunk));
        res.on("end", () => {
          let data = null;
          try {
            data = JSON.parse(raw);
          } catch (_) {
            data = raw;
          }
          resolve({
            status: res.statusCode,
            headers: res.headers,
            data,
          });
        });
      });

      req.on("error", reject);
      if (options.body) {
        req.write(typeof options.body === "string" ? options.body : JSON.stringify(options.body));
      }
      req.end();
    });
  }

  try {
    // 1. Health check
    const health = await request("/api/health");
    console.log("1. Health check:", health.status, health.data);
    if (health.status !== 200 || health.data.database !== "connected") {
      throw new Error("Health check failed or database not connected");
    }

    // 2. CORS Preflight verification for Flutter Web (OPTIONS request)
    const corsPreflight = await request("/api/classrooms", {
      method: "OPTIONS",
      headers: {
        Origin: "http://localhost:54321",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "content-type, authorization",
      },
    });
    console.log("2. CORS Preflight OPTIONS /api/classrooms:", corsPreflight.status);
    console.log("   Access-Control-Allow-Origin:", corsPreflight.headers["access-control-allow-origin"]);
    if (corsPreflight.status !== 200 && corsPreflight.status !== 204) {
      throw new Error(`CORS preflight failed with status ${corsPreflight.status}`);
    }

    // 3. Teacher creates a classroom
    const createClassRes = await request("/api/classrooms", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${teacherToken}`,
      },
      body: {
        name: "Quantum Computing 101",
        subject: "Physics",
        description: "Introduction to qubits, quantum gates, and circuits.",
        schedule: "Mon, Wed 10:00 AM",
      },
    });
    console.log("3. Teacher create classroom:", createClassRes.status, createClassRes.data.message);
    if (createClassRes.status !== 201 || !createClassRes.data.classroom?.code) {
      throw new Error("Failed to create classroom");
    }
    const classroom = createClassRes.data.classroom;
    const classCode = classroom.code;
    console.log("   Classroom ID:", classroom._id, "Join Code:", classCode);

    // 4. Student lists classrooms
    const listClassesRes = await request("/api/classrooms", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${studentToken}`,
      },
    });
    console.log("4. Student list classrooms:", listClassesRes.status, "Count:", listClassesRes.data.classrooms?.length);
    if (listClassesRes.status !== 200 || !Array.isArray(listClassesRes.data.classrooms)) {
      throw new Error("Failed to list classrooms");
    }

    // 5. Student joins classroom using the generated join code
    const joinRes = await request("/api/classrooms/join", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${studentToken}`,
      },
      body: {
        code: classCode,
      },
    });
    console.log("5. Student join classroom:", joinRes.status, joinRes.data.message);
    if (joinRes.status !== 200) {
      throw new Error(`Failed to join classroom: ${joinRes.data.message}`);
    }

    // 6. Classroom details verification
    const detailsRes = await request(`/api/classrooms/${classroom._id}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${teacherToken}`,
      },
    });
    console.log("6. Classroom details enrolled students:", detailsRes.data.classroom?.studentCount);
    if (detailsRes.status !== 200 || detailsRes.data.classroom?.studentCount < 1) {
      throw new Error("Classroom details student count mismatch");
    }

    // 7. Teacher creates an assignment
    const createAssignRes = await request("/api/assignments", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${teacherToken}`,
      },
      body: {
        classId: classroom._id,
        title: "Qubit Entanglement Problem Set",
        subject: "Physics",
        dueDate: "2026-11-01",
        maxMarks: 25,
        description: "Calculate Bell state fidelity and measurement probabilities.",
      },
    });
    console.log("7. Teacher create assignment:", createAssignRes.status, createAssignRes.data.message);
    if (createAssignRes.status !== 201 || !createAssignRes.data.data?._id) {
      throw new Error("Failed to create assignment");
    }
    const assignment = createAssignRes.data.data;
    console.log("   Assignment ID:", assignment._id, "Title:", assignment.title);

    // 8. Student gets assignments
    const listAssignRes = await request("/api/assignments", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${studentToken}`,
      },
    });
    console.log("8. Student get assignments:", listAssignRes.status, "Count:", listAssignRes.data.data?.length);
    if (listAssignRes.status !== 200 || !listAssignRes.data.data?.some((a) => a._id === assignment._id)) {
      throw new Error("Newly created assignment not found in assignments list");
    }

    // 9. Student submits assignment solution
    const submitRes = await request(`/api/submissions/assignment/${assignment._id}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${studentToken}`,
      },
      body: {
        studentId: "mock-student-01",
        text: "Bell state |Phi+> = (|00> + |11>)/sqrt(2). The measurement density matrix yields trace 1.",
      },
    });
    console.log("9. Student submit assignment:", submitRes.status, submitRes.data.message);
    if (submitRes.status !== 201 || !submitRes.data.data?._id) {
      throw new Error("Failed to submit assignment");
    }
    const submissionId = submitRes.data.data._id;

    // 10. Teacher views submissions for the assignment
    const subsRes = await request(`/api/submissions/assignment/${assignment._id}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${teacherToken}`,
      },
    });
    console.log("10. Teacher view submissions:", subsRes.status, "Count:", subsRes.data.data?.length);
    if (subsRes.status !== 200 || subsRes.data.data?.length < 1) {
      throw new Error("Teacher could not find student submission");
    }

    // 11. Teacher grades the student submission
    const gradeRes = await request(`/api/submissions/${submissionId}/grade`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${teacherToken}`,
      },
      body: {
        marks: 24,
        feedback: "Outstanding derivation and correct density matrix formulation!",
      },
    });
    console.log("11. Teacher grade submission:", gradeRes.status, "Marks:", gradeRes.data.data?.marks);
    if (gradeRes.status !== 200 || gradeRes.data.data?.marks !== 24) {
      throw new Error("Grading submission failed");
    }

    console.log("=== ALL END-TO-END FLOW CHECKS PASSED PERFECTLY! ===");
    process.exit(0);
  } catch (err) {
    console.error("E2E Test Failed:", err);
    process.exit(1);
  } finally {
    server.close();
  }
}

runE2ETests();
