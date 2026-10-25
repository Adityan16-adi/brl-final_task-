const express = require("express");
const cors = require("cors");
const http = require("http");
const path = require("path");
const fs = require("fs");
const mongoose = require("mongoose");
const { Server } = require("socket.io");

require("dotenv").config();
require("./config/firebase");

const classroomRoutes = require("./src/routes/classroomRoutes");
const authRoutes = require("./src/routes/authRoutes");
const connectDB = require("./config/db");
const verifyToken = require("./src/middleware/authMiddleware");

const app = express();
const server = http.createServer(app);

const corsOptions = {
    origin: true,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept", "X-Requested-With", "Origin"],
};

const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"],
    },
});

require("./src/sockets/handRaise")(io);

app.use(cors(corsOptions));

// Security headers middleware
app.use((req, res, next) => {
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("X-Frame-Options", "DENY");
    res.setHeader("X-XSS-Protection", "1; mode=block");
    res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
    next();
});

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Ensure local uploads directory exists and is statically served
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use("/uploads", express.static(uploadsDir));

app.use("/api/auth", authRoutes);
app.use("/api/classrooms", classroomRoutes);
app.use("/api/assignments", require("./src/routes/assignmentRoutes"));
app.use("/api/submissions", require("./src/routes/submissionRoutes"));
app.use("/api/materials", require("./src/routes/materialRoutes"));
app.use("/api/calendar", require("./src/routes/calendarRoutes"));
app.use("/api/notifications", require("./src/routes/notificationRoutes"));
app.use("/api/attendance", require("./src/routes/attendanceRoutes"));
app.use("/api/meetings", require("./src/routes/meetingRoutes"));
app.use("/api/chat", require("./src/routes/chatRoutes"));

const healthHandler = (req, res) => {
    const isDbConnected = mongoose.connection.readyState === 1;
    const status = isDbConnected ? "ok" : "degraded";
    const statusCode = isDbConnected ? 200 : 503;
    res.status(statusCode).json({
        status,
        service: "core-backend",
        database: isDbConnected ? "connected" : "disconnected",
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
    });
};

app.get("/api/health", healthHandler);
app.get("/health", healthHandler);

// Readiness probe for container orchestrators (Kubernetes, Docker, Cloud Run, Render)
const readyHandler = async (req, res) => {
    const isDbConnected = mongoose.connection.readyState === 1;
    const isCloudinaryActive = require("./src/utils/uploadToCloudinary").isCloudinaryConfigured();
    const isFirebaseActive = !!require("./config/firebase").auth;
    const isLiveKitActive = !!(
        process.env.LIVEKIT_API_KEY &&
        process.env.LIVEKIT_API_SECRET &&
        process.env.LIVEKIT_URL &&
        !process.env.LIVEKIT_API_KEY.includes("your_")
    );

    const isProduction = process.env.NODE_ENV === "production";
    const jwtSecret = process.env.JWT_SECRET;
    const isJwtConfigured = !isProduction || (
        jwtSecret &&
        jwtSecret.trim().length >= 32 &&
        jwtSecret !== "smart-classroom-secure-jwt-secret-key-2026"
    );

    const teacherSignupStatus = isProduction
        ? (process.env.TEACHER_SIGNUP_KEY && process.env.TEACHER_SIGNUP_KEY.trim().length >= 16 && process.env.TEACHER_SIGNUP_KEY !== "TEACHER_INVITE_2026"
            ? "configured"
            : "disabled-missing-key")
        : "development-key-active";

    let mlStatus = "unknown";
    try {
        let mlUrl = process.env.ML_SERVICE_URL || "http://localhost:8001";
        if (!/^https?:\/\//i.test(mlUrl)) {
            mlUrl = `http://${mlUrl}`;
        }
        const mlCheck = await fetch(`${mlUrl}/health`, { signal: AbortSignal.timeout(2000) });
        mlStatus = mlCheck.ok ? "connected" : "unhealthy";
    } catch {
        mlStatus = "disconnected";
    }

    const isReady = isDbConnected && isJwtConfigured;
    const statusCode = isReady ? 200 : 503;

    res.status(statusCode).json({
        ready: isReady,
        checks: {
            database: isDbConnected ? "ready" : "unconnected",
            storage: isCloudinaryActive
                ? "cloudinary-cloud"
                : (isProduction ? "ephemeral-local-disk-warning" : "local-disk-fallback"),
            auth: {
                jwtNative: isJwtConfigured ? "configured" : "insecure-production-jwt",
                firebaseAdmin: isFirebaseActive ? "configured" : "unconfigured",
                teacherProvisioning: teacherSignupStatus,
            },
            mlService: mlStatus,
            videoStreaming: isLiveKitActive ? "livekit-cloud" : "awaiting-credentials",
        },
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
    });
};

app.get("/api/ready", readyHandler);
app.get("/ready", readyHandler);

app.get("/", (req, res) => {
    res.send("Smart Classroom Backend is running!");
});

app.get("/protected", verifyToken, (req, res) => {
    res.status(200).json({
        success: true,
        message: "Authentication successful!",
        uid: req.user.uid,
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

const PORT = process.env.PORT || 5000;

const startServer = async () => {
    if (process.env.NODE_ENV === "production") {
        const secret = process.env.JWT_SECRET;
        if (!secret || secret.trim().length < 32 || secret === "smart-classroom-secure-jwt-secret-key-2026") {
            console.error("FATAL: In production mode, JWT_SECRET must be externally configured with at least 32 characters.");
            process.exit(1);
        }
        const teacherKey = process.env.TEACHER_SIGNUP_KEY;
        if (!teacherKey || teacherKey.trim().length < 16 || teacherKey === "TEACHER_INVITE_2026") {
            console.warn("SECURITY NOTICE: TEACHER_SIGNUP_KEY is not configured with a strong key in production. Teacher self-registration is securely disabled.");
        }
    }

    await connectDB();
    await require("./src/utils/seedDemoData")();

    server.listen(PORT, "0.0.0.0", () => {
        console.log(`Server running on 0.0.0.0:${PORT}`);
        console.log("Socket.IO is ready!");
    });
};

const gracefulShutdown = () => {
    console.log("Received shutdown signal. Closing HTTP and Socket.IO server...");
    server.close(() => {
        console.log("Server closed.");
        mongoose.connection.close(false).then(() => {
            console.log("MongoDB connection closed.");
            process.exit(0);
        }).catch(() => process.exit(0));
    });
    setTimeout(() => {
        console.error("Forcing shutdown after timeout.");
        process.exit(1);
    }, 10000).unref();
};

process.on("SIGTERM", gracefulShutdown);
process.on("SIGINT", gracefulShutdown);

if (require.main === module) {
    startServer();
}

module.exports = { app, server, startServer, gracefulShutdown };
