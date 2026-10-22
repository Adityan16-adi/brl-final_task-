const Assignment = require("../models/Assignment");

// GET /api/calendar/class/:classId?month=2026-10
exports.getClassEvents = async (req, res) => {
  try {
    const filter = { classId: req.params.classId };

    // optional month filter, format YYYY-MM
    if (req.query.month) {
      const [year, month] = req.query.month.split("-").map(Number);
      if (!year || !month) {
        return res.status(400).json({ success: false, message: "month must be YYYY-MM" });
      }
      filter.dueDate = {
        $gte: new Date(Date.UTC(year, month - 1, 1)),
        $lt: new Date(Date.UTC(year, month, 1)),
      };
    }

    const assignments = await Assignment.find(filter).sort({ dueDate: 1 });

    const events = assignments.map((a) => ({
      id: a._id,
      title: a.title,
      type: "assignment",
      date: a.dueDate,
      maxMarks: a.maxMarks,
    }));

    res.json({ success: true, data: events });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};