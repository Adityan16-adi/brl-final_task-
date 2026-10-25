const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authMiddleware");
const {
    register,
    login,
    getMe,
    syncUser,
    googleLogin
} = require("../controllers/authController");

router.post("/register", register);
router.post("/login", login);
router.post("/google", googleLogin);
router.get("/me", verifyToken, getMe);
router.post("/sync", verifyToken, syncUser);

module.exports = router;
