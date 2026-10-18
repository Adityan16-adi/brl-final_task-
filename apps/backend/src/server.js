const express = require("express");
const cors = require("cors");
require("dotenv").config();
const connectDB = require("./config/db");
connectDB();

const app = express();

app.use(cors());
app.use(express.json());
const path = require("path");
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));
app.use("/api/assignments", require("./routes/assignmentRoutes"));
app.use("/api/notifications", require("./routes/notificationRoutes"));

app.get("/api/health", (req, res) => {
  res.json({ success: true, message: "Backend is running" });
});

const PORT = process.env.PORT || 5000;
app.use("/api/assignments", require("./routes/assignmentRoutes"));
app.use("/api/submissions", require("./routes/submissionRoutes"));
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});