
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const { deleteFromCloudinary } = uploadToCloudinary;
const Assignment = require("../models/Assignment");

// POST /api/assignments — create an assignment
exports.createAssignment = async (req, res) => {
  let newlyUploadedPublicId = null;
  let newlyUploadedResourceType = null;

  try {
    const {
      classId,
      title,
      description,
      dueDate,
      maxMarks,
      createdBy,
    } = req.body || {};

    if (!classId || !title || !dueDate || !createdBy) {
      return res.status(400).json({
        success: false,
        message: "classId, title, dueDate and createdBy are required",
      });
    }

    let fileData = {};

    if (req.file) {
      const result = await uploadToCloudinary(
        req.file.buffer,
        "assignments"
      );

      fileData = {
        fileUrl: result.secure_url,
        filePublicId: result.public_id,
        fileResourceType: result.resource_type,
      };
      newlyUploadedPublicId = result.public_id;
      newlyUploadedResourceType = result.resource_type;
    }

    const assignment = await Assignment.create({
      classId,
      title,
      description: description || "",
      dueDate,
      maxMarks,
      createdBy,
      ...fileData,
    });

    return res.status(201).json({
      success: true,
      message: "Assignment created",
      data: assignment,
    });
  } catch (error) {
    if (newlyUploadedPublicId) {
      await deleteFromCloudinary(newlyUploadedPublicId, newlyUploadedResourceType);
    }
    if (error.message && error.message.includes("Cloud storage is not configured")) {
      return res.status(503).json({
        success: false,
        message: "Storage service not configured. Unable to upload file.",
      });
    }
    console.error("Create assignment error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to create assignment",
    });
  }
};

// GET /api/assignments/class/:classId
exports.getAssignmentsByClass = async (req, res) => {
  try {
    const assignments = await Assignment.find({
      classId: req.params.classId,
    }).sort({ dueDate: 1 });

    return res.json({ success: true, data: assignments });
  } catch (error) {
    console.error("Get assignments error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve assignments",
    });
  }
};

// GET /api/assignments/:id
exports.getAssignmentById = async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);

    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: "Assignment not found",
      });
    }

    return res.json({ success: true, data: assignment });
  } catch (error) {
    console.error("Get assignment error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve assignment",
    });
  }
};

// PUT /api/assignments/:id
exports.updateAssignment = async (req, res) => {
  let newlyUploadedPublicId = null;
  let newlyUploadedResourceType = null;

  try {
    const { title, description, dueDate, maxMarks } = req.body || {};
    const updates = {};

    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;
    if (dueDate !== undefined) updates.dueDate = dueDate;
    if (maxMarks !== undefined) updates.maxMarks = maxMarks;

    const existing = await Assignment.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Assignment not found",
      });
    }

    if (req.file) {
      const result = await uploadToCloudinary(
        req.file.buffer,
        "assignments"
      );

      updates.fileUrl = result.secure_url;
      updates.filePublicId = result.public_id;
      updates.fileResourceType = result.resource_type;
      newlyUploadedPublicId = result.public_id;
      newlyUploadedResourceType = result.resource_type;
    }

    const assignment = await Assignment.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    // Safe cleanup: Only delete old asset AFTER the database update has succeeded
    if (req.file && existing.filePublicId && existing.filePublicId !== updates.filePublicId) {
      await deleteFromCloudinary(existing.filePublicId, existing.fileResourceType);
    }

    return res.json({
      success: true,
      message: "Assignment updated",
      data: assignment,
    });
  } catch (error) {
    if (newlyUploadedPublicId) {
      await deleteFromCloudinary(newlyUploadedPublicId, newlyUploadedResourceType);
    }
    if (error.message && error.message.includes("Cloud storage is not configured")) {
      return res.status(503).json({
        success: false,
        message: "Storage service not configured. Unable to upload file.",
      });
    }
    console.error("Update assignment error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to update assignment",
    });
  }
};

// DELETE /api/assignments/:id
exports.deleteAssignment = async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);

    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: "Assignment not found",
      });
    }

    await Assignment.findByIdAndDelete(req.params.id);

    // Safe cleanup: Only delete from Cloudinary AFTER DB record deletion succeeds
    if (assignment.filePublicId) {
      await deleteFromCloudinary(assignment.filePublicId, assignment.fileResourceType);
    }

    return res.json({
      success: true,
      message: "Assignment deleted",
    });
  } catch (error) {
    console.error("Delete assignment error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to delete assignment",
    });
  }
};
