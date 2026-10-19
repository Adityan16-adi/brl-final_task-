const express = require("express");
const router = express.Router();
const { getClassEvents } = require("../controllers/calendarController");

router.get("/class/:classId", getClassEvents);

module.exports = router;