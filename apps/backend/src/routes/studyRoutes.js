const express = require("express");
const { mlRequest, ML_BASE_URL } = require("../services/mlClient");
const authenticate = require("../middleware/authenticate");
const { classAccess } = require("../utils/classAccess");
const router = express.Router();

const fail = (res, error) => res.status(error.status || 502).json({ success: false, message: error.message || "ML service request failed." });

router.get("/health", async (_req, res) => {
  try {
    const baseUrl = (process.env.ML_SERVICE_URL || ML_BASE_URL).replace(/\/$/, "");
    const timeoutMs = Math.min(Number(process.env.ML_TIMEOUT_MS || 5000), 10000);
    const response = await fetch(`${baseUrl}/health`, { signal: AbortSignal.timeout(timeoutMs) });
    const data = await response.json().catch(() => ({}));
    const isReady = response.ok && (data.status === "ok" || data.status === "ready" || data.success === true);
    res.status(isReady ? 200 : 503).json({
      success: isReady,
      status: isReady ? "ready" : "unavailable",
      llmConfigured: data.llm_configured ?? null,
    });
  } catch {
    res.status(503).json({ success: false, status: "unavailable" });
  }
});

router.use(authenticate);

router.post("/mentor", async (req, res) => {
  const { message, sessionId, courseId } = req.body || {};
  if (typeof message !== "string" || !message.trim() || message.length > 4000) {
    return res.status(400).json({ success: false, message: "message must contain 1 to 4000 characters." });
  }

  // Server-side verification of course access/enrollment
  let verifiedCourseId = null;
  if (courseId && typeof courseId === "string" && courseId.trim()) {
    const access = await classAccess(courseId.trim(), req.user);
    if (access.status) {
      return res.status(access.status).json({ success: false, message: access.message });
    }
    verifiedCourseId = courseId.trim();
  }

  // Server-generated session_id rooted in verified user identity and valid course context
  const clientSession = typeof sessionId === "string" && sessionId.trim()
    ? sessionId.trim().replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 48)
    : "";
  const contextTag = verifiedCourseId ? `c_${verifiedCourseId}` : "general";
  const serverSessionId = `u_${req.user.uid}_${contextTag}${clientSession ? `_${clientSession}` : ""}`.slice(0, 180);

  try {
    const result = await mlRequest(
      "/mentor/chat",
      {
        session_id: serverSessionId,
        message: message.trim(),
        ...(verifiedCourseId ? { course_id: verifiedCourseId } : {}),
      },
      { userId: req.user.uid }
    );
    res.json({ success: true, data: { text: result.reply } });
  } catch (error) { fail(res, error); }
});

router.post("/quiz", async (req, res) => {
  const { text, count = 3, difficulty = "medium" } = req.body || {};
  if (typeof text !== "string" || !text.trim() || text.length > 50000) {
    return res.status(400).json({ success: false, message: "Lesson notes are required (1 to 50000 characters) to generate a quiz." });
  }
  if (!Number.isInteger(Number(count)) || Number(count) < 1 || Number(count) > 20) {
    return res.status(400).json({ success: false, message: "count must be an integer from 1 to 20." });
  }
  if (!new Set(["easy", "medium", "hard"]).has(difficulty)) {
    return res.status(400).json({ success: false, message: "difficulty must be easy, medium, or hard." });
  }
  try {
    const result = await mlRequest(
      "/quiz",
      {
        text: text.trim(),
        num_questions: Number(count),
        difficulty,
      },
      { userId: req.user.uid }
    );
    res.json({ success: true, data: result });
  } catch (error) { fail(res, error); }
});

module.exports = router;
