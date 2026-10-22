const express = require("express");
const cors = require("cors");
require("dotenv").config();
require("./config/firebase");
 

const classroomRoutes = require("./src/routes/classroomRoutes");
const authRoutes = require("./src/routes/authRoutes");

const app = express();
app.use(cors());

app.use(express.json());
app.use("/api/auth", authRoutes);
app.use("/api/classrooms",classroomRoutes);
app.use("/api/assignments", require("./src/routes/assignmentRoutes"));
app.use("/api/submissions", require("./src/routes/submissionRoutes"));
app.use("/api/materials", require("./src/routes/materialRoutes"));
app.use("/api/calendar", require("./src/routes/calendarRoutes"));
app.use("/api/notifications", require("./src/routes/notificationRoutes"));
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

const PORT = process.env.PORT || 5000;

const startServer = async () => {
    await connectDB();

    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
};

startServer();