const ClassSession = require("../models/ClassSession");

const MAX_GAP_SECONDS = 90; // longer gaps are not counted

const findRecord = (session, studentId) =>
  session.records.find((r) => String(r.studentId) === String(studentId));

// adds elapsed time since lastSeen and updates status
const tick = (session, record, now) => {
  const gap = (now - record.lastSeen) / 1000;
  record.totalSeconds += Math.min(Math.max(gap, 0), MAX_GAP_SECONDS);
  record.lastSeen = now;
  if (record.status !== "present" && record.totalSeconds >= session.minMinutes * 60) {
    record.status = "present";
  }
};

// POST /api/sessions  { classId, startedBy, title, minMinutes }
exports.startSession = async (req, res) => {
  try {
    const { classId, startedBy, title, minMinutes } = req.body || {};
    if (!classId || !startedBy) {
      return res.status(400).json({ success: false, message: "classId and startedBy are required" });
    }
    const session = await ClassSession.create({ classId, startedBy, title, ...(minMinutes && { minMinutes }) });
    res.status(201).json({ success: true, data: session });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// POST /api/sessions/:id/join  { studentId }
exports.joinSession = async (req, res) => {
  try {
    const { studentId } = req.body || {};
    if (!studentId) return res.status(400).json({ success: false, message: "studentId is required" });

    const session = await ClassSession.findById(req.params.id);
    if (!session || !session.isActive) {
      return res.status(404).json({ success: false, message: "Session not found or ended" });
    }
    const now = new Date();
    let record = findRecord(session, studentId);
    if (!record) {
      session.records.push({ studentId, firstJoinedAt: now, lastSeen: now });
    } else {
      record.lastSeen = now; // rejoin: restart the clock, no gap counted
    }
    await session.save();
    res.json({ success: true, data: findRecord(session, studentId) });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// POST /api/sessions/:id/heartbeat  { studentId }  (app calls every 60 seconds)
exports.heartbeat = async (req, res) => {
  try {
    const { studentId } = req.body || {};
    const session = await ClassSession.findById(req.params.id);
    if (!session || !session.isActive) {
      return res.status(404).json({ success: false, message: "Session not found or ended" });
    }
    const record = findRecord(session, studentId);
    if (!record) return res.status(400).json({ success: false, message: "Join the session first" });

    tick(session, record, new Date());
    await session.save();
    res.json({
      success: true,
      data: {
        status: record.status,
        minutesAttended: Math.floor(record.totalSeconds / 60),
        minutesRequired: session.minMinutes,
      },
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// POST /api/sessions/:id/leave  { studentId }
exports.leaveSession = async (req, res) => {
  try {
    const { studentId } = req.body || {};
    const session = await ClassSession.findById(req.params.id);
    if (!session) return res.status(404).json({ success: false, message: "Session not found" });
    const record = findRecord(session, studentId);
    if (!record) return res.status(400).json({ success: false, message: "Not joined" });

    tick(session, record, new Date());
    await session.save();
    res.json({ success: true, data: record });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// PUT /api/sessions/:id/end  (teacher)
exports.endSession = async (req, res) => {
  try {
    const session = await ClassSession.findById(req.params.id);
    if (!session) return res.status(404).json({ success: false, message: "Session not found" });

    const now = new Date();
    session.records.forEach((r) => {
      if (r.status === "joined") {
        tick(session, r, now);
        if (r.status !== "present") r.status = "absent";
      }
    });
    session.isActive = false;
    session.endedAt = now;
    await session.save();
    res.json({ success: true, data: session });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// GET /api/sessions/:id/attendance
exports.getSessionAttendance = async (req, res) => {
  try {
    const session = await ClassSession.findById(req.params.id);
    if (!session) return res.status(404).json({ success: false, message: "Session not found" });
    const data = session.records.map((r) => ({
      studentId: r.studentId,
      status: r.status,
      minutesAttended: Math.floor(r.totalSeconds / 60),
    }));
    res.json({ success: true, minutesRequired: session.minMinutes, data });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// GET /api/sessions/class/:classId/student/:studentId  -> percentage
exports.getStudentSummary = async (req, res) => {
  try {
    const { classId, studentId } = req.params;
    const sessions = await ClassSession.find({ classId, isActive: false });
    let present = 0;
    sessions.forEach((s) => {
      const r = findRecord(s, studentId);
      if (r && r.status === "present") present++;
    });
    const total = sessions.length;
    res.json({
      success: true,
      data: { total, present, absent: total - present, percentage: total ? Math.round((present / total) * 100) : 0 },
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};