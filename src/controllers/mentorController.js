const ML_SERVICE_URL = process.env.ML_SERVICE_URL || "https://brl-final-task.onrender.com";

/**
 * GET /api/mentor/health
 * Ping ML service /health to trigger warm-up
 */
exports.health = async (req, res) => {
  try {
    const userId = req.user?.uid || (req.user?._id ? String(req.user._id) : "student-user");
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

    const mlRes = await fetch(`${mlUrl}/health`, {
      method: "GET",
      headers,
      signal: AbortSignal.timeout(60000),
    });

    if (mlRes.ok) {
      let data = {};
      const ct = mlRes.headers.get("content-type") || "";
      if (ct.includes("application/json")) {
        data = await mlRes.json().catch(() => ({}));
      }
      return res.status(200).json({
        success: true,
        status: "healthy",
        data,
      });
    }

    return res.status(503).json({
      success: false,
      status: "waking_up",
      message: "AI service is waking up.",
    });
  } catch (error) {
    return res.status(503).json({
      success: false,
      status: "waking_up",
      message: "AI service is waking up.",
    });
  }
};

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

    const bodyPayload = JSON.stringify({
      session_id: sessionId,
      message: message.trim(),
      course_id: course_id || undefined,
    });

    // Helper for single fetch attempt with 60s timeout
    const doFetch = async () => {
      return await fetch(`${mlUrl}/mentor/chat`, {
        method: "POST",
        headers,
        body: bodyPayload,
        signal: AbortSignal.timeout(60000), // 60s timeout for LLM inference
      });
    };

    let mlRes;
    try {
      mlRes = await doFetch();
      // Retry once on 502/504 cold-start
      if (mlRes.status === 502 || mlRes.status === 504) {
        console.warn(`ML service returned ${mlRes.status}, retrying once in 2s...`);
        await new Promise((resolve) => setTimeout(resolve, 2000));
        mlRes = await doFetch();
      }
    } catch (fetchErr) {
      // If first attempt failed with timeout or network error, retry once
      console.warn(`ML service fetch error (${fetchErr.message}), retrying once...`);
      try {
        await new Promise((resolve) => setTimeout(resolve, 1500));
        mlRes = await doFetch();
      } catch (retryErr) {
        console.error("ML service retry error:", retryErr.message);
        return res.status(504).json({
          success: false,
          message: "AI is waking up, please wait a moment...",
        });
      }
    }

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

    if (mlRes.status === 502 || mlRes.status === 504) {
      return res.status(504).json({
        success: false,
        message: "AI is waking up, please wait a moment...",
      });
    }

    if (!mlRes.ok) {
      return res.status(503).json({
        success: false,
        message: "AI mentor is currently unavailable. Tap to retry.",
      });
    }

    // Safely parse JSON, never crash on HTML
    let data;
    try {
      data = await mlRes.json();
    } catch (parseErr) {
      console.error("Failed to parse ML response JSON:", parseErr.message);
      return res.status(503).json({
        success: false,
        message: "AI mentor is currently unavailable. Tap to retry.",
      });
    }

    const reply = data.reply || data.response;
    if (!reply) {
      return res.status(503).json({
        success: false,
        message: "AI mentor returned an empty response. Tap to retry.",
      });
    }

    return res.status(200).json({
      success: true,
      reply,
    });
  } catch (error) {
    console.error("Mentor proxy error:", error.message);
    return res.status(504).json({
      success: false,
      message: "AI is waking up, please wait a moment...",
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
