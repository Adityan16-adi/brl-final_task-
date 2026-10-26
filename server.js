
const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

require("dotenv").config({ path: require("path").resolve(__dirname, ".env") });
require("./config/firebase");

const classroomRoutes = require("./src/routes/classroomRoutes");
const authRoutes = require("./src/routes/authRoutes");
const connectDB = require("./config/db");
const verifyToken = require("./src/middleware/authMiddleware");

const app = express();
const server = http.createServer(app);
const webOrigins = (process.env.WEB_ORIGIN || "http://localhost:5173").split(",").map((origin) => origin.trim());

const io = new Server(server, {
    cors: {
        origin: webOrigins,
        methods: ["GET", "POST"],
    },
});

require("./src/sockets/handRaise")(io);

app.use(cors({ origin: webOrigins }));
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/classrooms", classroomRoutes);

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

const PORT = process.env.PORT || 3000;

const startServer = async () => {
    await connectDB();

    server.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
        console.log("Socket.IO is ready!");
    });
};

startServer();
