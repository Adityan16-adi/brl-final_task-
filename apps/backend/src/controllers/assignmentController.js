const Assignment = require("../models/Assignment");

// POST /api/assignments  -> create a new assignment
exports.createAssignment = async (req, res) => {
  try {
    const { classId, title, description, dueDate, maxMarks, createdBy } = req.body;

    if (!classId || !title || !dueDate) {
      return res
        .status(400)
        .json({ success: false, message: "classId, title and dueDate are required" });
    }

  const attachments = (req.files || []).map((f) => ({
  name: f.originalname,
  url: `/uploads/${f.filename}`,
}));

const assignment = await Assignment.create({
  classId,
  title,
  description,
  dueDate,
  maxMarks,
  createdBy,
  attachments,
});

    res.status(201).json({ success: true, message: "Assignment created", data: assignment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/assignments/class/:classId  -> get all assignments of one class
exports.getAssignmentsByClass = async (req, res) => {
  try {
    const assignments = await Assignment.find({ classId: req.params.classId }).sort({
      dueDate: 1,
    });
    res.json({ success: true, data: assignments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
// GET /api/assignments/:id
exports.getAssignmentById = async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }
    res.json({ success: true, data: assignment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/assignments/:id
exports.updateAssignment = async (req, res) => {
  try {
    const { title, description, dueDate, maxMarks } = req.body;
    const assignment = await Assignment.findByIdAndUpdate(
      req.params.id,
      { title, description, dueDate, maxMarks },
      { new: true, runValidators: true, omitUndefined: true }
    );
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }
    res.json({ success: true, message: "Assignment updated", data: assignment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/assignments/:id
exports.deleteAssignment = async (req, res) => {
  try {
    const assignment = await Assignment.findByIdAndDelete(req.params.id);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }
    res.json({ success: true, message: "Assignment deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};