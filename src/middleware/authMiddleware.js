const {auth} = require("../../config/firebase");

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