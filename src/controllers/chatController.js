const Message = require("../models/Message");

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || "http://localhost:8001";

/**
 * GET /api/chat/:classId
 * Returns recent chat messages for a classroom (limit 50, ascending order)
 */
exports.getClassroomMessages = async (req, res) => {
  try {
    const { classId } = req.params;
    if (!classId) {
      return res.status(400).json({ success: false, message: "classId is required" });
    }

    const messages = await Message.find({ classId, isSpam: { $ne: true } })
      .sort({ createdAt: -1 })
      .limit(50);

    return res.status(200).json({
      success: true,
      data: messages.reverse(),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch messages: " + error.message,
    });
  }
};

/**
 * POST /api/chat/:classId
 * Validates against ML spam detector and saves message
 */
exports.sendMessage = async (req, res) => {
  try {
    const { classId } = req.params;
    const { text, senderUid, senderName, senderRole } = req.body;

    if (!classId || !text || !text.trim()) {
      return res.status(400).json({
        success: false,
        message: "classId and non-empty text are required",
      });
    }

    let isSpam = false;
    let reasons = [];

    // Optional call to ML service spam detection
    try {
      const mlHeaders = {
        "Content-Type": "application/json",
        "X-User-Id": senderUid || req.user?.uid || "anonymous",
      };
      if (process.env.ML_API_TOKEN) {
        mlHeaders["X-API-Key"] = process.env.ML_API_TOKEN;
      }

      const mlRes = await fetch(`${ML_SERVICE_URL}/spam/check`, {
        method: "POST",
        headers: mlHeaders,
        body: JSON.stringify({
          meeting_id: classId,
          user_id: senderUid || "anonymous",
          message: text.trim(),
        }),
        signal: AbortSignal.timeout(4000),
      });
      if (mlRes.ok) {
        const mlData = await mlRes.json();
        if (mlData && mlData.is_spam) {
          isSpam = true;
          reasons = mlData.reasons || ["Spam content detected by ML classifier"];
          return res.status(422).json({
            success: false,
            isSpam: true,
            action: mlData.action || "warn",
            reasons,
            message: "Message rejected: " + reasons.join(", "),
          });
        }
      }
    } catch (mlErr) {
      // If ML service is unreachable, continue gracefully without blocking normal chat
    }

    const message = await Message.create({
      classId,
      senderUid: senderUid || req.user?.uid || req.user?.id || "student-01",
      senderName: senderName || req.user?.name || "Student",
      senderRole: senderRole || (req.user?.isTeacher ? "teacher" : "student"),
      text: text.trim(),
      isSpam: false,
    });

    return res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to send message: " + error.message,
    });
  }
};

/**
 * POST /api/chat/spam-check
 * Backend proxy endpoint for pre-validating message text against ML spam classifier
 */
exports.checkSpam = async (req, res) => {
  try {
    const { meeting_id, user_id, message } = req.body || {};
    if (!message || !message.trim()) {
      return res.status(200).json({ is_spam: false, score: 0, action: "allow", strikes: 0, reasons: [] });
    }

    const mlHeaders = {
      "Content-Type": "application/json",
      "X-User-Id": user_id || req.user?.uid || "anonymous",
    };
    if (process.env.ML_API_TOKEN) {
      mlHeaders["X-API-Key"] = process.env.ML_API_TOKEN;
    }

    let mlUrl = ML_SERVICE_URL;
    if (!/^https?:\/\//i.test(mlUrl)) {
      mlUrl = `https://${mlUrl}`;
    }

    const mlRes = await fetch(`${mlUrl}/spam/check`, {
      method: "POST",
      headers: mlHeaders,
      body: JSON.stringify({
        meeting_id: meeting_id || "general",
        user_id: user_id || "anonymous",
        message: message.trim(),
      }),
      signal: AbortSignal.timeout(4000),
    });

    if (mlRes.ok) {
      const mlData = await mlRes.json();
      return res.status(200).json(mlData);
    }
  } catch (err) {
    // Fail open
  }

  // Fallback heuristic
  const trimmed = (req.body?.message || "").trim();
  const isRepeatedChar = /(.)\1{7,}/.test(trimmed);
  const urlMatches = (trimmed.match(/(https?:\/\/|www\.)\S+/gi) || []).length;
  const isTooLong = trimmed.length > 500;
  if (isRepeatedChar || urlMatches > 2 || isTooLong) {
    const reasons = [];
    if (isRepeatedChar) reasons.push("Repeated characters");
    if (urlMatches > 2) reasons.push("Excessive external links");
    if (isTooLong) reasons.push("Message too long");
    return res.status(200).json({
      is_spam: true,
      score: 3,
      action: "block",
      strikes: 1,
      reasons,
    });
  }

  return res.status(200).json({
    is_spam: false,
    score: 0,
    action: "allow",
    strikes: 0,
    reasons: [],
  });
};
