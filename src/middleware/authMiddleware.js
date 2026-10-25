const jwt = require("jsonwebtoken");
const { auth } = require("../../config/firebase");
const User = require("../models/User");

const DEFAULT_JWT_SECRET = "smart-classroom-secure-jwt-secret-key-2026";

const getJwtSecret = () => {
    const secret = process.env.JWT_SECRET;
    if (process.env.NODE_ENV === "production") {
        if (!secret || secret.trim().length < 32 || secret === DEFAULT_JWT_SECRET) {
            throw new Error("FATAL_AUTH_CONFIG: In production mode, JWT_SECRET must be externally configured with at least 32 characters.");
        }
        return secret.trim();
    }
    return (secret && secret.trim()) || DEFAULT_JWT_SECRET;
};

const verifyToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({
                success: false,
                message: "Access denied. Token required."
            });
        }

        const token = authHeader.split(" ")[1]?.trim();
        if (!token) {
            return res.status(401).json({
                success: false,
                message: "Access denied. Token required."
            });
        }

        // Support development mock bearer tokens in non-production environments
        if (token.startsWith("mock-jwt-token-")) {
            if (process.env.NODE_ENV === "production") {
                return res.status(401).json({
                    success: false,
                    message: "Mock tokens are disabled in production mode."
                });
            }

            const uid = token.replace("mock-jwt-token-", "").trim();
            const isTeacher = uid.toLowerCase().includes("teacher");
            const role = isTeacher ? "teacher" : "student";
            const name = isTeacher ? "Demo Teacher" : "Demo Student";
            const email = `${uid}@demo.com`;

            let user = await User.findOne({ uid });
            if (!user) {
                user = await User.create({ uid, name, email, role });
            }

            req.user = { uid: user.uid, email: user.email, name: user.name, role: user.role, _id: user._id };
            return next();
        }

        // Attempt genuine JWT token verification
        try {
            const secret = getJwtSecret();
            const decoded = jwt.verify(token, secret);
            let user = await User.findOne({ uid: decoded.uid });
            if (user) {
                req.user = { uid: user.uid, email: user.email, name: user.name, role: user.role, _id: user._id };
            } else {
                req.user = { uid: decoded.uid, email: decoded.email, name: decoded.name, role: decoded.role || "student", _id: decoded._id };
            }
            return next();
        } catch (jwtErr) {
            if (jwtErr.name === "TokenExpiredError") {
                return res.status(401).json({
                    success: false,
                    message: "Invalid or expired token."
                });
            }
            if (jwtErr.message && jwtErr.message.startsWith("FATAL_AUTH_CONFIG")) {
                return res.status(503).json({
                    success: false,
                    message: "Authentication service unavailable: insecure server configuration in production."
                });
            }
            // If it's another JWT error, it could be a Firebase ID token
        }

        // Fallback to Firebase ID Token if Firebase Admin is configured
        if (auth && typeof auth.verifyIdToken === "function") {
            try {
                const decodedToken = await auth.verifyIdToken(token);
                let user = await User.findOne({ uid: decodedToken.uid });
                req.user = {
                    uid: decodedToken.uid,
                    email: decodedToken.email || user?.email,
                    name: decodedToken.name || user?.name,
                    role: user?.role || "student",
                    _id: user?._id
                };
                return next();
            } catch (firebaseErr) {
                return res.status(401).json({
                    success: false,
                    message: "Invalid or expired token."
                });
            }
        }

        return res.status(401).json({
            success: false,
            message: "Invalid or expired token."
        });
    } catch (error) {
        console.error("Auth Middleware Error:", error);
        return res.status(500).json({
            success: false,
            message: "Authentication processing failed."
        });
    }
};

const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Forbidden: Only ${allowedRoles.join(" or ")} accounts can perform this action.`
            });
        }
        next();
    };
};

const requireTeacher = requireRole("teacher");

verifyToken.verifyToken = verifyToken;
verifyToken.requireRole = requireRole;
verifyToken.requireTeacher = requireTeacher;
verifyToken.getJwtSecret = getJwtSecret;

module.exports = verifyToken;
