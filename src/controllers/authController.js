const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const User = require("../models/User");

const DEFAULT_JWT_SECRET = "smart-classroom-secure-jwt-secret-key-2026";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

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

const generateToken = (user) => {
    const secret = getJwtSecret();
    return jwt.sign(
        {
            uid: user.uid,
            email: user.email,
            name: user.name,
            role: user.role,
            _id: user._id
        },
        secret,
        { expiresIn: JWT_EXPIRES_IN }
    );
};

const register = async (req, res) => {
    try {
        const { email, password, name, role, teacherCode } = req.body || {};

        if (!email || !email.trim()) {
            return res.status(400).json({
                success: false,
                message: "Email is required."
            });
        }

        const normalizedEmail = email.trim().toLowerCase();
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
            return res.status(400).json({
                success: false,
                message: "A valid email address is required."
            });
        }

        if (!password || password.length < 6) {
            return res.status(400).json({
                success: false,
                message: "Password must be at least 6 characters long."
            });
        }

        const existingUser = await User.findOne({ email: normalizedEmail });
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: "An account with this email already exists."
            });
        }

        // Prevent privilege escalation: only authorized users with a teacher code can claim the teacher role
        let userRole = "student";
        if (role === "teacher") {
            const isProduction = process.env.NODE_ENV === "production";
            const configuredKey = process.env.TEACHER_SIGNUP_KEY?.trim();

            if (isProduction) {
                // In production, TEACHER_INVITE_2026 is strictly forbidden and an explicit strong key is required
                if (!configuredKey || configuredKey === "TEACHER_INVITE_2026" || configuredKey.length < 16) {
                    return res.status(403).json({
                        success: false,
                        message: "Teacher self-registration is disabled in production: TEACHER_SIGNUP_KEY must be configured with a secure key (minimum 16 characters) by the administrator."
                    });
                }
                if (!teacherCode || teacherCode.trim() !== configuredKey) {
                    return res.status(403).json({
                        success: false,
                        message: "Invalid teacher provisioning code."
                    });
                }
            } else {
                // Non-production development/test mode
                const devKey = configuredKey || "TEACHER_INVITE_2026";
                if (!teacherCode || teacherCode.trim() !== devKey) {
                    return res.status(403).json({
                        success: false,
                        message: "A valid teacher provisioning code is required to register a teacher account."
                    });
                }
            }
            userRole = "teacher";
        }

        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);
        const uid = `user_${crypto.randomUUID()}`;
        const displayName = (name && name.trim()) || normalizedEmail.split("@")[0];

        const newUser = await User.create({
            uid,
            name: displayName,
            email: normalizedEmail,
            role: userRole,
            passwordHash
        });

        const token = generateToken(newUser);

        res.status(201).json({
            success: true,
            message: "Registration successful.",
            token,
            user: {
                _id: newUser._id,
                uid: newUser.uid,
                name: newUser.name,
                email: newUser.email,
                role: newUser.role
            }
        });
    } catch (error) {
        if (error.message && error.message.startsWith("FATAL_AUTH_CONFIG")) {
            console.error("Authentication security error:", error.message);
            return res.status(503).json({
                success: false,
                message: "Authentication service unavailable: insecure server configuration in production."
            });
        }
        console.error("Register Error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to register user."
        });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body || {};

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and password are required."
            });
        }

        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ email: normalizedEmail }).select("+passwordHash");

        if (!user) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password."
            });
        }

        if (!user.passwordHash) {
            return res.status(401).json({
                success: false,
                message: "This account was registered using social login. Please sign in with Firebase."
            });
        }

        const isMatch = await bcrypt.compare(password, user.passwordHash);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password."
            });
        }

        const token = generateToken(user);

        res.status(200).json({
            success: true,
            message: "Login successful.",
            token,
            user: {
                _id: user._id,
                uid: user.uid,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        if (error.message && error.message.startsWith("FATAL_AUTH_CONFIG")) {
            console.error("Authentication security error:", error.message);
            return res.status(503).json({
                success: false,
                message: "Authentication service unavailable: insecure server configuration in production."
            });
        }
        console.error("Login Error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to authenticate."
        });
    }
};

const getMe = async (req, res) => {
    try {
        if (!req.user || !req.user.uid) {
            return res.status(401).json({
                success: false,
                message: "Not authenticated."
            });
        }

        const user = await User.findOne({ uid: req.user.uid });
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found."
            });
        }

        res.status(200).json({
            success: true,
            user: {
                _id: user._id,
                uid: user.uid,
                name: user.name,
                email: user.email,
                role: user.role,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            }
        });
    } catch (error) {
        console.error("GetMe Error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to get current user."
        });
    }
};

const syncUser = async (req, res) => {
    try {
        const { uid, email, name, role } = req.user;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: "Email is required"
            });
        }

        const updateData = {
            uid,
            email,
            name: name || email.split("@")[0]
        };
        if (role) {
            updateData.role = role;
        }

        const user = await User.findOneAndUpdate(
            { uid },
            updateData,
            {
                new: true,
                upsert: true,
                runValidators: true,
                setDefaultsOnInsert: true
            }
        );

        res.status(200).json({
            success: true,
            message: "User profile synced successfully",
            user: {
                _id: user._id,
                uid: user.uid,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to sync user profile"
        });
    }
};

const googleLogin = async (req, res) => {
    try {
        const { idToken, role, teacherCode } = req.body || {};

        if (!idToken || typeof idToken !== "string" || !idToken.trim()) {
            return res.status(400).json({
                success: false,
                message: "Firebase ID token is required."
            });
        }

        const { auth } = require("../../config/firebase");
        if (!auth) {
            return res.status(503).json({
                success: false,
                message: "Firebase authentication service is not configured on this server."
            });
        }

        let decoded;
        try {
            decoded = await auth.verifyIdToken(idToken.trim());
        } catch (verifyErr) {
            return res.status(401).json({
                success: false,
                message: "Invalid or expired Firebase ID token: " + verifyErr.message
            });
        }

        const uid = decoded.uid;
        const email = decoded.email ? decoded.email.trim().toLowerCase() : null;
        if (!email) {
            return res.status(400).json({
                success: false,
                message: "Google account must have an associated email address."
            });
        }

        const name = decoded.name || decoded.displayName || email.split("@")[0];
        const picture = decoded.picture || undefined;

        let user = await User.findOne({ $or: [{ uid }, { email }] });
        if (user) {
            // Existing user
            let changed = false;
            if (user.uid !== uid) {
                user.uid = uid;
                changed = true;
            }
            if (picture && !user.avatarUrl) {
                user.avatarUrl = picture;
                changed = true;
            }
            if (changed) {
                await user.save();
            }

            const token = generateToken(user);
            return res.status(200).json({
                success: true,
                message: "Login successful.",
                token,
                user: {
                    _id: user._id,
                    uid: user.uid,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    avatarUrl: user.avatarUrl
                }
            });
        }

        // New user: requires role selection
        if (!role || (role !== "student" && role !== "teacher")) {
            return res.status(200).json({
                success: false,
                needsRoleSelection: true,
                uid,
                email,
                name,
                picture,
                message: "Account not found. Please select your role to complete registration."
            });
        }

        let userRole = "student";
        if (role === "teacher") {
            const isProduction = process.env.NODE_ENV === "production";
            const configuredKey = process.env.TEACHER_SIGNUP_KEY?.trim();

            if (isProduction) {
                if (!configuredKey || configuredKey === "TEACHER_INVITE_2026" || configuredKey.length < 16) {
                    return res.status(403).json({
                        success: false,
                        message: "Teacher self-registration is disabled in production: TEACHER_SIGNUP_KEY must be configured with a secure key (minimum 16 characters) by the administrator."
                    });
                }
                if (!teacherCode || teacherCode.trim() !== configuredKey) {
                    return res.status(403).json({
                        success: false,
                        message: "Invalid teacher provisioning code."
                    });
                }
            } else {
                const devKey = configuredKey || "TEACHER_INVITE_2026";
                if (!teacherCode || teacherCode.trim() !== devKey) {
                    return res.status(403).json({
                        success: false,
                        message: "A valid teacher provisioning code is required to register a teacher account."
                    });
                }
            }
            userRole = "teacher";
        }

        const newUser = await User.create({
            uid,
            name: name || email.split("@")[0],
            email,
            role: userRole,
            avatarUrl: picture
        });

        const token = generateToken(newUser);
        return res.status(201).json({
            success: true,
            message: "Registration successful.",
            token,
            user: {
                _id: newUser._id,
                uid: newUser.uid,
                name: newUser.name,
                email: newUser.email,
                role: newUser.role,
                avatarUrl: newUser.avatarUrl
            }
        });
    } catch (error) {
        console.error("Google Auth Error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to authenticate with Google."
        });
    }
};

const updateProfile = async (req, res) => {
    try {
        const { name, avatarUrl } = req.body || {};
        const uid = req.user?.uid;

        if (!uid) {
            return res.status(401).json({
                success: false,
                message: "Authentication required to update profile."
            });
        }

        const updateData = {};
        if (typeof name === "string" && name.trim()) {
            updateData.name = name.trim();
        }

        if (req.file) {
            try {
                const uploadToCloudinary = require("../utils/uploadToCloudinary");
                const result = await uploadToCloudinary(req.file.buffer, "avatars");
                updateData.avatarUrl = result.url;
            } catch (uploadErr) {
                console.warn("Avatar Cloudinary upload error:", uploadErr.message);
            }
        } else if (typeof avatarUrl === "string" && avatarUrl.trim()) {
            updateData.avatarUrl = avatarUrl.trim();
        }

        const user = await User.findOneAndUpdate(
            { uid },
            { $set: updateData },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found."
            });
        }

        res.status(200).json({
            success: true,
            message: "Profile updated successfully.",
            user: {
                _id: user._id,
                uid: user.uid,
                name: user.name,
                email: user.email,
                role: user.role,
                avatarUrl: user.avatarUrl
            }
        });
    } catch (error) {
        console.error("Update Profile Error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update profile."
        });
    }
};

module.exports = { register, login, getMe, syncUser, googleLogin, updateProfile, generateToken, getJwtSecret };
