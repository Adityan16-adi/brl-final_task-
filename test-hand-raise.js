require("dotenv").config();

const { io } = require("socket.io-client");

const socket = io("http://localhost:3000", {
    auth: {
        token: process.env.TEST_FIREBASE_TOKEN
    }
});

const classroomId = process.env.TEST_CLASSROOM_ID;

socket.on("connect", () => {
    console.log("Connected successfully:", socket.id);

    socket.emit("join-classroom", classroomId, (response) => {
        console.log("Join classroom:", response);

        if (!response || !response.success) {
            socket.disconnect();
            return;
        }

        socket.emit(
            "mic-status",
            { classroomId, enabled: false },
            (response) => {
                console.log("Mic status:", response);
            }
        );

        socket.emit(
            "camera-status",
            { classroomId, enabled: true },
            (response) => {
                console.log("Camera status:", response);
            }
        );

        socket.emit("raise-hand", { classroomId }, (result) => {
            console.log("Raise hand:", result);

            socket.emit("lower-hand", { classroomId }, (lowerResult) => {
                console.log("Lower hand:", lowerResult);
                socket.disconnect();
            });
        });
    });
});

socket.on("hand-raised", (data) => {
    console.log("Hand raised event received:", data);
});

socket.on("hand-lowered", (data) => {
    console.log("Hand lowered event received:", data);
});

socket.on("connect_error", (error) => {
    console.log("Connection error:", error.message);
});