const express = require("express");
const cors = require("cors");
const path = require("path");
const mongoose = require("mongoose");
require("dotenv").config();
const connectDB = require("./config/db");

const app = express();

const corsOptions = {
  origin: true,
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "Accept", "X-Requested-With", "Origin"],
};

app.use(cors(corsOptions));
app.use(express.json());

app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

// Mount core routes
app.use("/api/auth", require("../../../src/routes/authRoutes"));
app.use("/api/classrooms", require("../../../src/routes/classroomRoutes"));
app.use("/api/assignments", require("./routes/assignmentRoutes"));
app.use("/api/submissions", require("./routes/submissionRoutes"));
app.use("/api/notifications", require("./routes/notificationRoutes"));
app.use("/api/materials", require("./routes/materialRoutes"));
app.use("/api/calendar", require("./routes/calendarRoutes"));

app.get("/api/health", (req, res) => {
  const isDbConnected = mongoose.connection.readyState === 1;
  const status = isDbConnected ? "ok" : "degraded";
  const statusCode = isDbConnected ? 200 : 503;
  res.status(statusCode).json({
    status,
    database: isDbConnected ? "connected" : "disconnected",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// Express error-handling middleware (catches Multer filter errors, etc.)
app.use((err, req, res, next) => {
  const statusCode = err.status || err.statusCode || 400;
  res.status(statusCode).json({
    success: false,
    message: err.message || "An unexpected error occurred",
  });
});

const PORT = process.env.PORT || 5001;

if (require.main === module) {
  connectDB();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = { app, connectDB };
