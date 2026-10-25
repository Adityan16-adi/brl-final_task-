const express = require("express");
const router = express.Router();

const upload = require("../middleware/upload");
const verifyToken = require("../middleware/authMiddleware");
const {
    register,
    login,
    getMe,
    syncUser,
    googleLogin,
    updateProfile
} = require("../controllers/authController");

router.post("/register", register);
router.post("/login", login);
router.post("/google", googleLogin);
router.get("/me", verifyToken, getMe);
router.post("/sync", verifyToken, syncUser);
router.put("/profile", verifyToken, upload.single("avatar"), updateProfile);

module.exports = router;
