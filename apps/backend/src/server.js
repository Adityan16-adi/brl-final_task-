const express = require("express");
const cors = require("cors");
const path = require("path");
require("./config/env");
const connectDB = require("./config/db");
const { closeDB } = require("./config/db");
const { validateEnv } = require("./config/env");

const app = express();

app.use(cors({ origin: (process.env.WEB_ORIGIN || "http://localhost:5173").split(",").map((origin) => origin.trim()) }));
app.use(express.json());

app.use("/uploads", express.static(path.join(__dirname, "../uploads")));
app.use("/api/assignments", require("./routes/assignmentRoutes"));
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/submissions", require("./routes/submissionRoutes"));
app.use("/api/notifications", require("./routes/notificationRoutes"));
app.use("/api/materials", require("./routes/materialRoutes"));
app.use("/api/calendar", require("./routes/calendarRoutes"));
app.use("/api/attendance", require("./routes/attendanceRoutes"));
app.use("/api/study", require("./routes/studyRoutes"));

app.get("/api/health", (req, res) => {
  const mongoose = require("mongoose");
  const ready = mongoose.connection.readyState === 1;
  res.status(ready ? 200 : 503).json({ success: ready, status: ready ? "ready" : "database_unavailable" });
});

app.use((error, _req, res, _next) => {
  const status = error.name === "MulterError" ? 400 : 500;
  const message = status === 400 ? error.message : "The server could not complete the request.";
  res.status(status).json({ success: false, message });
});

async function start() {
  const { port } = validateEnv();
  await connectDB();
  const server = app.listen(port, () => console.log(`API ready on port ${port}`));
  const shutdown = async (signal) => {
    console.log(`${signal} received; shutting down`);
    server.close(async () => {
      try { await closeDB(); process.exit(0); }
      catch (error) { console.error("Shutdown failed:", error.message); process.exit(1); }
    });
  };
  process.once("SIGINT", () => shutdown("SIGINT"));
  process.once("SIGTERM", () => shutdown("SIGTERM"));
  return server;
}

if (require.main === module) {
  start().catch((error) => {
    console.error(`Backend startup failed: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = { app, start };
