const ML_SERVICE_URL = process.env.ML_SERVICE_URL || "https://brl-final-task.onrender.com";

/**
 * POST /api/mentor/chat
 * Proxy endpoint to hosted ML service with server-held ML_API_TOKEN authentication
 */
exports.chat = async (req, res) => {
  try {
    const { message, session_id, course_id } = req.body || {};

    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: "Message is required.",
      });
    }

    const userId = req.user?.uid || (req.user?._id ? String(req.user._id) : "student-user");
    const sessionId = session_id || `${userId}:${course_id || "general"}:default`;

    const headers = {
      "Content-Type": "application/json",
      "X-User-Id": userId,
    };

    if (process.env.ML_API_TOKEN) {
      headers["X-API-Key"] = process.env.ML_API_TOKEN;
    }

    let mlUrl = ML_SERVICE_URL;
    if (!/^https?:\/\//i.test(mlUrl)) {
      mlUrl = `https://${mlUrl}`;
    }

    const mlRes = await fetch(`${mlUrl}/mentor/chat`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        session_id: sessionId,
        message: message.trim(),
        course_id: course_id || undefined,
      }),
      signal: AbortSignal.timeout(60000), // 60s timeout for LLM inference
    });

    if (mlRes.status === 401) {
      console.error("ML service returned 401 Unauthorized: check ML_API_TOKEN configuration.");
      return res.status(500).json({
        success: false,
        message: "AI mentor configuration error on server.",
      });
    }

    if (mlRes.status === 429) {
      return res.status(429).json({
        success: false,
        message: "AI rate limit reached, please try again in a few moments.",
      });
    }

    if (!mlRes.ok) {
      return res.status(503).json({
        success: false,
        message: "AI mentor is currently unavailable. Tap to retry.",
      });
    }

    const data = await mlRes.json();
    const reply = data.reply || data.response;

    return res.status(200).json({
      success: true,
      reply,
    });
  } catch (error) {
    console.error("Mentor proxy error:", error.message);
    return res.status(503).json({
      success: false,
      message: "AI mentor is currently unavailable. Tap to retry.",
    });
  }
};

/**
 * POST /api/mentor/materials
 * Index materials into ML mentor context
 */
exports.addMaterials = async (req, res) => {
  try {
    const { course_id, text } = req.body || {};
    if (!course_id || !text) {
      return res.status(400).json({
        success: false,
        message: "course_id and text are required.",
      });
    }

    const userId = req.user?.uid || "teacher-user";
    const headers = {
      "Content-Type": "application/json",
      "X-User-Id": userId,
    };
    if (process.env.ML_API_TOKEN) {
      headers["X-API-Key"] = process.env.ML_API_TOKEN;
    }

    let mlUrl = ML_SERVICE_URL;
    if (!/^https?:\/\//i.test(mlUrl)) {
      mlUrl = `https://${mlUrl}`;
    }

    const mlRes = await fetch(`${mlUrl}/mentor/materials`, {
      method: "POST",
      headers,
      body: JSON.stringify({ course_id, text }),
      signal: AbortSignal.timeout(15000),
    });

    if (!mlRes.ok) {
      return res.status(mlRes.status).json({
        success: false,
        message: "Failed to index materials with ML service.",
      });
    }

    const data = await mlRes.json();
    return res.status(200).json({ success: true, ...data });
  } catch (error) {
    return res.status(503).json({
      success: false,
      message: "AI mentor is currently unavailable.",
    });
  }
};

/**
 * POST /api/mentor/reset
 * Reset chat session
 */
exports.resetSession = async (req, res) => {
  try {
    const { session_id } = req.query || req.body || {};
    if (!session_id) {
      return res.status(400).json({
        success: false,
        message: "session_id is required.",
      });
    }

    const userId = req.user?.uid || "student-user";
    const headers = {
      "Content-Type": "application/json",
      "X-User-Id": userId,
    };
    if (process.env.ML_API_TOKEN) {
      headers["X-API-Key"] = process.env.ML_API_TOKEN;
    }

    let mlUrl = ML_SERVICE_URL;
    if (!/^https?:\/\//i.test(mlUrl)) {
      mlUrl = `https://${mlUrl}`;
    }

    const mlRes = await fetch(`${mlUrl}/mentor/reset?session_id=${encodeURIComponent(session_id)}`, {
      method: "POST",
      headers,
      signal: AbortSignal.timeout(10000),
    });

    if (!mlRes.ok) {
      return res.status(mlRes.status).json({
        success: false,
        message: "Failed to reset mentor session.",
      });
    }

    const data = await mlRes.json();
    return res.status(200).json({ success: true, ...data });
  } catch (error) {
    return res.status(503).json({
      success: false,
      message: "AI mentor is currently unavailable.",
    });
  }
};
