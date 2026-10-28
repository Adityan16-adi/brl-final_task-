const ML_SERVICE_URL = process.env.ML_SERVICE_URL || "https://brl-final-task.onrender.com";

function getMlUrl() {
  let url = ML_SERVICE_URL;
  if (!/^https?:\/\//i.test(url)) {
    url = `https://${url}`;
  }
  return url;
}

function getMlHeaders(req) {
  const userId = req.user?.uid || (req.user?._id ? String(req.user._id) : "student-user");
  const headers = {
    "Content-Type": "application/json",
    "X-User-Id": userId,
  };
  if (process.env.ML_API_TOKEN) {
    headers["X-API-Key"] = process.env.ML_API_TOKEN;
  }
  return headers;
}

/**
 * POST /api/ml/summarize
 * Proxy to ML service /summarize
 */
exports.summarize = async (req, res) => {
  const { text, style } = req.body || {};

  if (typeof text !== "string" || !text.trim() || text.trim().length > 50000) {
    return res.status(400).json({
      success: false,
      message: "Text must be a non-empty string under 50,000 characters.",
    });
  }

  const validStyles = ["short", "bullets", "detailed"];
  const resolvedStyle = validStyles.includes(style) ? style : "bullets";

  const mlUrl = getMlUrl();
  const headers = getMlHeaders(req);

  try {
    const mlRes = await fetch(`${mlUrl}/summarize`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        text: text.trim(),
        style: resolvedStyle,
      }),
      signal: AbortSignal.timeout(60000),
    });

    if (mlRes.ok) {
      const data = await mlRes.json();
      return res.status(200).json(data);
    }

    if (mlRes.status >= 400 && mlRes.status < 500) {
      if (mlRes.status === 401 || mlRes.status === 403) {
        return res.status(503).json({
          success: false,
          message: "AI service is unavailable right now. Please try again later.",
        });
      }
      let detail = "Bad request to AI service.";
      try {
        const errData = await mlRes.json();
        detail = errData.detail || errData.message || detail;
      } catch (_) {}
      return res.status(mlRes.status).json({
        success: false,
        message: typeof detail === "string" ? detail : JSON.stringify(detail),
      });
    }

    return res.status(503).json({
      success: false,
      message: "AI service is waking up. Please try again in a minute.",
    });
  } catch (_) {
    return res.status(503).json({
      success: false,
      message: "AI service is waking up. Please try again in a minute.",
    });
  }
};

/**
 * POST /api/ml/quiz
 * Proxy to ML service /quiz
 */
exports.quiz = async (req, res) => {
  const { text, num_questions, difficulty } = req.body || {};

  if (typeof text !== "string" || !text.trim() || text.trim().length > 50000) {
    return res.status(400).json({
      success: false,
      message: "Text must be a non-empty string under 50,000 characters.",
    });
  }

  let nq = parseInt(num_questions, 10);
  if (isNaN(nq)) {
    nq = 5;
  } else {
    nq = Math.min(20, Math.max(1, nq));
  }

  const validDifficulties = ["easy", "medium", "hard"];
  const resolvedDifficulty = validDifficulties.includes(difficulty) ? difficulty : "medium";

  const mlUrl = getMlUrl();
  const headers = getMlHeaders(req);

  try {
    const mlRes = await fetch(`${mlUrl}/quiz`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        text: text.trim(),
        num_questions: nq,
        difficulty: resolvedDifficulty,
      }),
      signal: AbortSignal.timeout(60000),
    });

    if (mlRes.ok) {
      const data = await mlRes.json();
      return res.status(200).json(data);
    }

    if (mlRes.status >= 400 && mlRes.status < 500) {
      if (mlRes.status === 401 || mlRes.status === 403) {
        return res.status(503).json({
          success: false,
          message: "AI service is unavailable right now. Please try again later.",
        });
      }
      let detail = "Bad request to AI service.";
      try {
        const errData = await mlRes.json();
        detail = errData.detail || errData.message || detail;
      } catch (_) {}
      return res.status(mlRes.status).json({
        success: false,
        message: typeof detail === "string" ? detail : JSON.stringify(detail),
      });
    }

    return res.status(503).json({
      success: false,
      message: "AI service is waking up. Please try again in a minute.",
    });
  } catch (_) {
    return res.status(503).json({
      success: false,
      message: "AI service is waking up. Please try again in a minute.",
    });
  }
};
