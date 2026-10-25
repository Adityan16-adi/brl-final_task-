const jwt = require("jsonwebtoken");
const { auth } = require("../../config/firebase");
const User = require("../models/User");
const Classroom = require("../models/Classroom");
const { getJwtSecret } = require("../middleware/authMiddleware");

module.exports = (io) => {
    // Authenticate socket connections via JWT or Firebase ID token
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth?.token;

            if (!token) {
                return next(new Error("Authentication required"));
            }

            // Check for development mock tokens in non-production
            if (token.startsWith("mock-jwt-token-")) {
                if (process.env.NODE_ENV === "production") {
                    return next(new Error("Mock tokens are disabled in production mode"));
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

                socket.user = {
                    uid: user.uid,
                    name: user.name,
                    role: user.role,
                    _id: user._id
                };
                return next();
            }

            // Attempt native JWT verification
            try {
                const secret = getJwtSecret();
                const decoded = jwt.verify(token, secret);
                const user = await User.findOne({ uid: decoded.uid });
                if (user) {
                    socket.user = {
                        uid: user.uid,
                        name: user.name,
                        role: user.role,
                        _id: user._id
                    };
                    return next();
                }
            } catch (jwtErr) {
                // Fall through to Firebase check
            }

            // Fallback to Firebase ID Token if Firebase Admin is configured
            if (auth && typeof auth.verifyIdToken === "function") {
                try {
                    const decodedToken = await auth.verifyIdToken(token);
                    const user = await User.findOne({ uid: decodedToken.uid });
                    if (!user) {
                        return next(new Error("User profile not found"));
                    }
                    socket.user = {
                        uid: user.uid,
                        name: user.name,
                        role: user.role,
                        _id: user._id
                    };
                    return next();
                } catch (firebaseErr) {
                    return next(new Error("Invalid or expired token"));
                }
            }

            return next(new Error("Invalid or expired token"));
        } catch (error) {
            next(new Error("Authentication failed: " + error.message));
        }
    });

    io.on("connection", (socket) => {
        console.log("Authenticated socket connected:", socket.id);

        // Join classroom
        socket.on("join-classroom", async (classroomId, callback) => {
            try {
                if (
                    typeof classroomId !== "string" ||
                    !classroomId.trim() ||
                    !/^[a-fA-F0-9]{24}$/.test(classroomId)
                ) {
                    return callback({
                        success: false,
                        message: "Invalid classroom ID format"
                    });
                }

                const classroom = await Classroom.findById(classroomId);

                if (!classroom) {
                    return callback({
                        success: false,
                        message: "Classroom not found"
                    });
                }

                const isTeacher =
                    String(classroom.teacherUid) === socket.user.uid;

                const isEnrolled =
                    classroom.students &&
                    classroom.students.some(
                        (student) =>
                            String(student.uid || student) === socket.user.uid
                    );

                if (!isTeacher && !isEnrolled) {
                    return callback({
                        success: false,
                        message: "You are not enrolled in this classroom"
                    });
                }

                await socket.join(`classroom:${classroomId}`);

                callback({
                    success: true,
                    message: `Joined classroom:${classroomId}`
                });
            } catch (error) {
                console.error("Error in join-classroom:", error);
                callback({
                    success: false,
                    message: "Internal server error"
                });
            }
        });

        // Raise hand
        socket.on("raise-hand", (data, callback) => {
            try {
                const { classroomId } = data || {};

                if (!classroomId) {
                    return callback?.({
                        success: false,
                        message: "classroomId is required"
                    });
                }

                const room = `classroom:${classroomId}`;

                if (!socket.rooms.has(room)) {
                    return callback?.({
                        success: false,
                        message: "You must join the classroom first"
                    });
                }

                if (socket.user.role !== "student") {
                    return callback?.({
                        success: false,
                        message: "Only students can raise hands"
                    });
                }

                io.to(room).emit("hand-raised", {
                    uid: socket.user.uid,
                    name: socket.user.name
                });

                callback?.({ success: true });
            } catch (error) {
                console.error("Error in raise-hand:", error);
                callback?.({
                    success: false,
                    message: "Internal server error"
                });
            }
        });

        // Lower hand
        socket.on("lower-hand", (data, callback) => {
            try {
                const { classroomId } = data || {};

                if (!classroomId) {
                    return callback?.({
                        success: false,
                        message: "classroomId is required"
                    });
                }

                const room = `classroom:${classroomId}`;

                if (!socket.rooms.has(room)) {
                    return callback?.({
                        success: false,
                        message: "You must join the classroom first"
                    });
                }

                if (socket.user.role !== "student") {
                    return callback?.({
                        success: false,
                        message: "Only students can lower hands"
                    });
                }

                io.to(room).emit("hand-lowered", {
                    uid: socket.user.uid,
                    name: socket.user.name
                });

                callback?.({ success: true });
            } catch (error) {
                console.error("Error in lower-hand:", error);
                callback?.({
                    success: false,
                    message: "Internal server error"
                });
            }
        });

        // Mic status
        socket.on("mic-status", (data, callback) => {
            try {
                const { classroomId, isMuted } = data || {};

                if (!classroomId || typeof isMuted !== "boolean") {
                    return callback?.({
                        success: false,
                        message: "classroomId and isMuted (boolean) are required"
                    });
                }

                const room = `classroom:${classroomId}`;

                if (!socket.rooms.has(room)) {
                    return callback?.({
                        success: false,
                        message: "You must join the classroom first"
                    });
                }

                io.to(room).emit("mic-status-changed", {
                    uid: socket.user.uid,
                    name: socket.user.name,
                    isMuted
                });

                callback?.({ success: true });
            } catch (error) {
                console.error("Error in mic-status:", error);
                callback?.({
                    success: false,
                    message: "Internal server error"
                });
            }
        });

        // Camera status
        socket.on("camera-status", (data, callback) => {
            try {
                const { classroomId, isVideoOff } = data || {};

                if (!classroomId || typeof isVideoOff !== "boolean") {
                    return callback?.({
                        success: false,
                        message: "classroomId and isVideoOff (boolean) are required"
                    });
                }

                const room = `classroom:${classroomId}`;

                if (!socket.rooms.has(room)) {
                    return callback?.({
                        success: false,
                        message: "You must join the classroom first"
                    });
                }

                io.to(room).emit("camera-status-changed", {
                    uid: socket.user.uid,
                    name: socket.user.name,
                    isVideoOff
                });

                callback?.({ success: true });
            } catch (error) {
                console.error("Error in camera-status:", error);
                callback?.({
                    success: false,
                    message: "Internal server error"
                });
            }
        });

        socket.on("disconnect", () => {
            console.log("Socket disconnected:", socket.id);
        });
    });
};
