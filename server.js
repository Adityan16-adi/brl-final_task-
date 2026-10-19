const express = require("express");
require("dotenv").config();
require("./config/firebase");

const classroomRoutes = require("./src/routes/classroomRoutes");
const authRoutes = require("./src/routes/authRoutes");

const app = express();

app.use(express.json());
app.use("/api/auth", authRoutes);
app.use("/api/classrooms",classroomRoutes);
console.log("Classroom routes mounted");

app.get("/", (req, res) => {
    res.send("Smart Classroom Backend is running!");
});

const connectDB = require("./config/db");
const verifyToken = require("./src/middleware/authMiddleware");

app.get("/protected", verifyToken, (req, res) => {
    res.status(200).json({
        success: true,
        message: "Authentication successful!",
        uid: req.user.uid
    });
});

const PORT = process.env.PORT || 3000;

const startServer = async () => {
    await connectDB();

    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
};

startServer();