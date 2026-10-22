const { auth } = require("../../config/firebase");
const User = require("../models/User");
const Classroom = require("../models/Classroom");

module.exports = (io) => {
    // Firebase authentication
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth?.token;

            if (!token) {
                return next(new Error("Authentication required"));
            }

            const decodedToken = await auth.verifyIdToken(token);
            const user = await User.findOne({ uid: decodedToken.uid });

            if (!user) {
                return next(new Error("User profile not found"));
            }

            socket.user = {
                uid: user.uid,
                name: user.name,
                role: user.role
            };

            next();
        } catch (error) {
            next(new Error("Invalid or expired token"));
        }
    });

    io.on("connection", (socket) => {
        console.log("Authenticated socket connected:", socket.id);

        // Join classroom
        socket.on("join-classroom", async (classroomId, callback) => {
            try {
                if (
                    typeof classroomId !== "string" ||
                    !/^[a-fA-F0-9]{24}$/.test(classroomId)
                ) {
                    return callback?.({
                        success: false,
                        message: "Invalid classroom ID"
                    });
                }

                const classroom = await Classroom.findById(classroomId);

                if (!classroom) {
                    return callback?.({
                        success: false,
                        message: "Classroom not found"
                    });
                }

                const isTeacher =
                    String(classroom.teacherUid) === socket.user.uid;

                const isStudent = classroom.students.some(
                    (student) =>
                        String(student.uid || student) === socket.user.uid
                );

                if (!isTeacher && !isStudent) {
                    return callback?.({
                        success: false,
                        message: "Access denied"
                    });
                }

                await socket.join(`classroom:${classroomId}`);

                callback?.({
                    success: true,
                    message: "Joined classroom successfully"
                });
            } catch (error) {
                console.error("Join classroom error:", error.message);

                callback?.({
                    success: false,
                    message: "Unable to join classroom"
                });
            }
        });

        // Raise hand
        socket.on("raise-hand", (data, callback) => {
            if (!data || typeof data.classroomId !== "string") {
                return callback?.({
                    success: false,
                    message: "Invalid request"
                });
            }

            const room = `classroom:${data.classroomId}`;

            if (!socket.rooms.has(room)) {
                return callback?.({
                    success: false,
                    message: "Join the classroom first"
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

            callback?.({
                success: true,
                message: "Hand raised successfully"
            });
        });

        // Lower hand
        socket.on("lower-hand", (data, callback) => {
            if (!data || typeof data.classroomId !== "string") {
                return callback?.({
                    success: false,
                    message: "Invalid request"
                });
            }

            const room = `classroom:${data.classroomId}`;

            if (!socket.rooms.has(room)) {
                return callback?.({
                    success: false,
                    message: "Join the classroom first"
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

            callback?.({
                success: true,
                message: "Hand lowered successfully"
            });
        });


        // Microphone status
        socket.on("mic-status", (data, callback) => {
            if (
                !data ||
                typeof data.classroomId !== "string" ||
                typeof data.enabled !== "boolean"
            ) {
                return callback?.({
                    success: false,
                    message: "Invalid microphone status"
                });
            }

            const room = `classroom:${data.classroomId}`;

            if (!socket.rooms.has(room)) {
                return callback?.({
                    success: false,
                    message: "Join the classroom first"
                });
            }

            io.to(room).emit("mic-status-updated", {
                uid: socket.user.uid,
                name: socket.user.name,
                enabled: data.enabled
            });

            callback?.({
                success: true,
                message: "Microphone status updated"
            });
        });

        // Camera status
        socket.on("camera-status", (data, callback) => {
            if (
                !data ||
                typeof data.classroomId !== "string" ||
                typeof data.enabled !== "boolean"
            ) {
                return callback?.({
                    success: false,
                    message: "Invalid camera status"
                });
            }

            const room = `classroom:${data.classroomId}`;

            if (!socket.rooms.has(room)) {
                return callback?.({
                    success: false,
                    message: "Join the classroom first"
                });
            }

            io.to(room).emit("camera-status-updated", {
                uid: socket.user.uid,
                name: socket.user.name,
                enabled: data.enabled
            });

            callback?.({
                success: true,
                message: "Camera status updated"
            });
        });


        // Disconnect
        socket.on("disconnect", () => {
            console.log("Socket disconnected:", socket.id);
        });
    });
};