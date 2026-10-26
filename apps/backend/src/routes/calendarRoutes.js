const express = require("express");
const router = express.Router();
const authenticate = require("../middleware/authenticate");
const { getClassEvents } = require("../controllers/calendarController");

router.use(authenticate);
router.get("/class/:classId", getClassEvents);

module.exports = router;
