const uploadToCloudinary = require('../utils/uploadToCloudinary');
const Assignment = require("../models/Assignment");
const mongoose = require("mongoose");
const { classAccess } = require("../utils/classAccess");

// POST /api/assignments  -> create a new assignment
exports.createAssignment = async (req, res) => {
  try {
    const { classId, title, description, dueDate, maxMarks } = req.body;

    if (!classId || !title || !dueDate) {
      return res
        .status(400)
        .json({ success: false, message: "classId, title and dueDate are required" });
    }

    const access = await classAccess(classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher) return res.status(403).json({ success: false, message: "Only the class teacher can create assignments." });
    if (Number.isNaN(Date.parse(dueDate)) || (maxMarks !== undefined && (!Number.isFinite(Number(maxMarks)) || Number(maxMarks) < 0))) {
      return res.status(400).json({ success: false, message: "dueDate must be a valid date and maxMarks must be non-negative." });
    }
    let fileData = {};
if (req.file) {
  const result = await uploadToCloudinary(req.file.buffer, "assignments");
  fileData = {
    fileUrl: result.secure_url,
    filePublicId: result.public_id,
    fileResourceType: result.resource_type,
  };
}

const assignment = await Assignment.create({
  classId,
  title,
  description,
  dueDate,
  maxMarks,
  createdBy: req.user._id,
  ...fileData
});

    res.status(201).json({ success: true, message: "Assignment created", data: assignment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/assignments/class/:classId  -> get all assignments of one class
exports.getAssignmentsByClass = async (req, res) => {
  try {
    const access = await classAccess(req.params.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
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
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Assignment ID must be a valid MongoDB ObjectId." });
    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }
    const access = await classAccess(assignment.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    res.json({ success: true, data: assignment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/assignments/:id
exports.updateAssignment = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Assignment ID must be a valid MongoDB ObjectId." });
    const existing = await Assignment.findById(req.params.id);
    if (!existing) return res.status(404).json({ success: false, message: "Assignment not found" });
    const access = await classAccess(existing.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher || String(existing.createdBy) !== String(req.user._id)) return res.status(403).json({ success: false, message: "Only the assignment's class teacher can update it." });
    const { title, description, dueDate, maxMarks } = req.body;
    const update = { title, description, dueDate, maxMarks };
    for (const key of Object.keys(update)) if (update[key] === undefined) delete update[key];
    if (req.file) {
      const result = await uploadToCloudinary(req.file.buffer, "assignments");
      Object.assign(update, { fileUrl: result.secure_url, filePublicId: result.public_id, fileResourceType: result.resource_type });
    }
    const assignment = await Assignment.findByIdAndUpdate(
      req.params.id,
      update,
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
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Assignment ID must be a valid MongoDB ObjectId." });
    const existing = await Assignment.findById(req.params.id);
    if (!existing) return res.status(404).json({ success: false, message: "Assignment not found" });
    const access = await classAccess(existing.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher || String(existing.createdBy) !== String(req.user._id)) return res.status(403).json({ success: false, message: "Only the assignment's class teacher can delete it." });
    const assignment = await Assignment.findByIdAndDelete(req.params.id);
    if (!assignment) {
      return res.status(404).json({ success: false, message: "Assignment not found" });
    }
    res.json({ success: true, message: "Assignment deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
