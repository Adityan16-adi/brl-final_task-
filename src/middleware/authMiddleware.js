const { auth } = require("../../config/firebase");
const User = require("../models/User");

const verifyToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({
                success: false,
                message: "Access denied. Token required."
            });
        }

        const token = authHeader.split(" ")[1];

        // Support development and test mock bearer tokens in non-production environments
        if (process.env.NODE_ENV !== "production" && token.startsWith("mock-jwt-token-")) {
            const uid = token.replace("mock-jwt-token-", "").trim();
            const isTeacher = uid.toLowerCase().includes("teacher");
            const role = isTeacher ? "teacher" : "student";
            const name = isTeacher ? "Demo Teacher" : "Demo Student";
            const email = `${uid}@demo.com`;

            // Ensure development user document exists in MongoDB with appropriate role
            let user = await User.findOne({ uid });
            if (!user) {
                user = await User.create({ uid, name, email, role });
            }

            req.user = { uid, email, name, role: user.role };
            return next();
        }

        if (!auth) {
            return res.status(503).json({
                success: false,
                message: "Authentication service unavailable. Firebase credentials not configured."
            });
        }

        const decodedToken = await auth.verifyIdToken(token);

        req.user = decodedToken;

        next();
    } catch (error) {
        console.log("Firebase Verify Error:", error.message);
        return res.status(401).json({
            success: false,
            message: "Invalid or expired token."
        });
    }
};

module.exports = verifyToken;