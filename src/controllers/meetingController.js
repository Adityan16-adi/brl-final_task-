const { AccessToken } = require("livekit-server-sdk");
const Classroom = require("../models/Classroom");

const getLiveKitToken = async (req, res) => {
    try {
        const classroomId = req.params.id || req.body.classroomId;

        if (!classroomId || !/^[a-fA-F0-9]{24}$/.test(classroomId)) {
            return res.status(400).json({
                success: false,
                message: "A valid classroom ID is required"
            });
        }

        const classroom = await Classroom.findById(classroomId);
        if (!classroom) {
            return res.status(404).json({
                success: false,
                message: "Classroom not found"
            });
        }

        const isTeacher = String(classroom.teacherUid) === req.user.uid || req.user.role === "teacher";
        const isEnrolled = isTeacher || (classroom.students && classroom.students.some(s => String(s.uid || s) === req.user.uid));

        if (!isEnrolled) {
            return res.status(403).json({
                success: false,
                message: "Forbidden: You are not enrolled in this classroom"
            });
        }

        const apiKey = process.env.LIVEKIT_API_KEY;
        const apiSecret = process.env.LIVEKIT_API_SECRET;
        const livekitUrl = process.env.LIVEKIT_URL;

        if (!apiKey || !apiSecret || !livekitUrl || apiKey.includes("your_") || livekitUrl.includes("your_")) {
            return res.status(503).json({
                success: false,
                status: "awaiting_credentials",
                message: "LiveKit video streaming provider is not configured. Please set LIVEKIT_API_KEY, LIVEKIT_API_SECRET, and LIVEKIT_URL in backend environment."
            });
        }

        const roomName = `classroom-${classroomId}`;
        const participantIdentity = req.user.uid;
        const participantName = req.user.name || req.user.email?.split("@")[0] || "Participant";

        const at = new AccessToken(apiKey, apiSecret, {
            identity: participantIdentity,
            name: participantName,
            ttl: "4h",
        });

        at.addGrant({
            roomJoin: true,
            room: roomName,
            canPublish: true,
            canSubscribe: true,
            canPublishData: true,
            roomAdmin: isTeacher,
        });

        const token = await at.toJwt();

        res.status(200).json({
            success: true,
            token,
            serverUrl: livekitUrl,
            roomName,
            participant: {
                identity: participantIdentity,
                name: participantName,
                isTeacher
            }
        });
    } catch (error) {
        console.error("LiveKit token generation error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to generate meeting room token"
        });
    }
};

module.exports = { getLiveKitToken };
