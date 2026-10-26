const Material = require("../models/Material");
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const mongoose = require("mongoose");
const { classAccess } = require("../utils/classAccess");

const detectType = (mimetype = "") => {
  if (mimetype.startsWith("image/")) return "image";
  if (mimetype.startsWith("video/")) return "video";
  return "note";
};

// POST /api/materials  (form-data: classId, uploadedBy, title, description, file, link)
exports.createMaterial = async (req, res) => {
  try {
    const { classId, title, description, link, thumbnailUrl } = req.body || {};
    if (!classId || !title) {
      return res
        .status(400)
        .json({ success: false, message: "classId and title are required" });
    }
    const access = await classAccess(classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher) return res.status(403).json({ success: false, message: "Only the class teacher can add learning materials." });
    if (!req.file && !link) {
      return res.status(400).json({ success: false, message: "Attach a file or give a link" });
    }

    let storedFile = {};
    if (req.file) {
      const result = await uploadToCloudinary(req.file.buffer, "materials");
      storedFile = { fileUrl: result.secure_url, filePublicId: result.public_id };
    }
    const type = req.file ? detectType(req.file.mimetype) : "link";
    const material = await Material.create({
      classId,
      uploadedBy: req.user._id,
      title,
      description,
      type,
      ...storedFile,
      thumbnailUrl: type === "image" && req.file ? storedFile.fileUrl : thumbnailUrl || "",
      link,
    });

    res.status(201).json({ success: true, message: "Material added", data: material });
  } catch (error) {
    res.status(error.name === "ValidationError" ? 400 : 500).json({ success: false, message: error.message });
  }
};

// GET /api/materials/class/:classId   (optional ?type=video)
exports.getMaterialsByClass = async (req, res) => {
  try {
    const access = await classAccess(req.params.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    const filter = { classId: req.params.classId };
    if (req.query.type) filter.type = req.query.type;
    const data = await Material.find(filter).sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (error) {
    res.status(error.name === "CastError" ? 400 : 500).json({ success: false, message: error.message });
  }
};

// GET /api/materials/:id
exports.getMaterialById = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Material ID must be a valid MongoDB ObjectId." });
    const material = await Material.findById(req.params.id);
    if (!material) return res.status(404).json({ success: false, message: "Material not found" });
    const access = await classAccess(material.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    res.json({ success: true, data: material });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/materials/:id
exports.deleteMaterial = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Material ID must be a valid MongoDB ObjectId." });
    const material = await Material.findById(req.params.id);
    if (!material) return res.status(404).json({ success: false, message: "Material not found" });
    const access = await classAccess(material.classId, req.user);
    if (access.status) return res.status(access.status).json({ success: false, message: access.message });
    if (!access.teacher || String(material.uploadedBy) !== String(req.user._id)) return res.status(403).json({ success: false, message: "Only the uploader who teaches this class can delete the material." });
    await material.deleteOne();
    res.json({ success: true, message: "Material deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
