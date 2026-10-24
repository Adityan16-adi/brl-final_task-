// ML Microservice API Adapter
// Connects Web frontend to FastAPI ML service on port 8001 (or VITE_ML_API_BASE_URL)
// with seamless fallback to local mock responder when the ML service is not running.

const ML_BASE = (import.meta.env.VITE_ML_API_BASE_URL || "http://localhost:8001").replace(/\/$/, "");

// Predefined local fallback questions
const fallbackQuestions = [
  { prompt: "Which cell structure is most associated with releasing usable energy?", options: ["Mitochondrion", "Ribosome", "Cell wall", "Vacuole"], answer: 0 },
  { prompt: "What is the main role of a cell membrane?", options: ["Store genetic information", "Control what enters and leaves", "Build proteins", "Release oxygen"], answer: 1 },
  { prompt: "Where is most genetic information in an animal cell stored?", options: ["Cytoplasm", "Golgi apparatus", "Nucleus", "Lysosome"], answer: 2 },
];

let webSessionId = `web-${Date.now()}`;

export async function askMentor(prompt) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const res = await fetch(`${ML_BASE}/mentor/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        session_id: webSessionId,
        message: prompt,
      }),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (res.ok) {
      const data = await res.json();
      if (data && data.reply) {
        return { text: data.reply };
      }
    }
  } catch {
    // ML service offline or network error: fall back gracefully to local preview responder
  }

  const normalized = (prompt || "").toLowerCase();
  const subjectKey = normalized.includes("algebra") || normalized.includes("बीजगणित")
    ? "Mathematics"
    : "Cell structures";

  return {
    responseKey: "Let’s break that down. For {{subject}}, start by naming the main idea, then connect it to one example from your lesson. What part feels least clear right now?",
    subjectKey,
  };
}

export async function generateQuiz({ count = 3, topic = "Cell structures" } = {}) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);

    const res = await fetch(`${ML_BASE}/quiz`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        text: topic || "Biology cell structures and functions",
        num_questions: Math.min(Math.max(Number(count) || 3, 1), 10),
        difficulty: "medium",
      }),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (res.ok) {
      const data = await res.json();
      const rawQuestions = Array.isArray(data) ? data : (Array.isArray(data?.questions) ? data.questions : []);
      if (rawQuestions.length > 0) {
        return {
          questions: rawQuestions.map((q) => ({
            prompt: q.prompt || q.question || "Question",
            options: Array.isArray(q.options) ? q.options : [],
            answer: typeof q.answer === "number" ? q.answer : (typeof q.answer_index === "number" ? q.answer_index : 0),
          })),
        };
      }
    }
  } catch {
    // Fall back to predefined questions if ML service is unreachable
  }

  const num = Math.min(Number(count) || 3, fallbackQuestions.length);
  return {
    questions: fallbackQuestions.slice(0, num).map((q) => ({
      ...q,
      options: [...q.options],
    })),
  };
}

export async function checkMessage(text) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);

    const res = await fetch(`${ML_BASE}/spam/check`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        meeting_id: "preview-room",
        user_id: "web-user",
        message: text,
      }),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (res.ok) {
      const data = await res.json();
      const flagged = typeof data.flagged === "boolean" ? data.flagged : Boolean(data.is_spam);
      const reason = data.reason || (Array.isArray(data.reasons) && data.reasons.length > 0 ? data.reasons.join(", ") : (flagged ? "Flagged by ML spam filter." : "Message verified."));
      return {
        flagged,
        reason,
      };
    }
  } catch {
    // Fall back to regex filter if ML service is unreachable
  }

  const flagged = /free money|click this link|buy now/i.test(text || "");
  return {
    flagged,
    reason: flagged ? "This phrase matches a sample review rule." : "No sample review flags found.",
  };
}
