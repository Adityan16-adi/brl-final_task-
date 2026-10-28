const express = require("express");
const router = express.Router();
const mlController = require("../controllers/mlController");
const verifyToken = require("../middleware/authMiddleware");

router.post("/summarize", verifyToken, mlController.summarize);
router.post("/quiz", verifyToken, mlController.quiz);

module.exports = router;
