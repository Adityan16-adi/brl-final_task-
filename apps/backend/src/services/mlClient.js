const DEFAULT_ML_BASE_URL = "https://brl-final-task.onrender.com";
const ML_BASE_URL = (process.env.ML_SERVICE_URL || DEFAULT_ML_BASE_URL).replace(/\/$/, "");

async function mlRequest(path, body, options = {}) {
  const controller = new AbortController();
  const timeoutMs = Number(process.env.ML_TIMEOUT_MS || 30000);
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {}),
  };

  const apiToken = process.env.ML_API_TOKEN?.trim();
  if (apiToken) {
    headers["X-API-Key"] = apiToken;
  }

  if (options.userId) {
    headers["X-User-Id"] = String(options.userId);
  }

  const baseUrl = (process.env.ML_SERVICE_URL || DEFAULT_ML_BASE_URL).replace(/\/$/, "");

  try {
    const response = await fetch(`${baseUrl}${path}`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const payload = await response.json().catch(() => ({}));

    if (!response.ok) {
      if (response.status === 401) {
        const error = new Error("ML service authentication failed. Verify server-side ML token configuration.");
        error.status = 502;
        throw error;
      }

      if (response.status === 429) {
        const error = new Error("ML service rate limit reached. Please wait a moment and try again.");
        error.status = 429;
        throw error;
      }

      const detail = response.status < 500 && typeof payload.detail === "string" ? payload.detail : null;
      const error = new Error(detail || (response.status >= 500 ? "ML service is temporarily unavailable." : "ML service request failed."));
      error.status = response.status >= 500 ? 502 : response.status;
      throw error;
    }

    return payload;
  } catch (error) {
    if (error.name === "AbortError") {
      const timeoutError = new Error(`ML service request timed out after ${Math.round(timeoutMs / 1000)} seconds.`);
      timeoutError.status = 504;
      throw timeoutError;
    }
    if (
      error.code === "ECONNREFUSED" ||
      error.cause?.code === "ECONNREFUSED" ||
      error.code === "ENOTFOUND" ||
      error.cause?.code === "ENOTFOUND" ||
      error instanceof TypeError
    ) {
      const unavailable = new Error("ML service is unavailable or unreachable. Verify service health and connectivity.");
      unavailable.status = 503;
      throw unavailable;
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = { mlRequest, ML_BASE_URL };
