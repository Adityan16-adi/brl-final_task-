const path = require("path");
const mongoose = require("mongoose");
const Material = require("../models/Material");
const User = mongoose.models.User || require(path.resolve(__dirname, "../../../../src/models/User"));
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const { deleteFromCloudinary } = uploadToCloudinary;

const detectType = (mimetype = "") => {
  if (mimetype.startsWith("image/")) return "image";
  if (mimetype.startsWith("video/")) return "video";
  return "note";
};

// POST /api/materials  (form-data: classId, uploadedBy, title, description, file, link)
exports.createMaterial = async (req, res) => {
  let newlyUploadedPublicId = null;
  let newlyUploadedResourceType = null;

  try {
    const { classId, title, description, link, thumbnailUrl } = req.body || {};
    let uploaderInput = req.body?.uploadedBy || req.user?._id || req.user?.uid;
    if (!uploaderInput && process.env.NODE_ENV !== "production") {
      uploaderInput = "mock-teacher-01";
    }

    if (!classId || !title || !uploaderInput) {
      return res
        .status(400)
        .json({ success: false, message: "classId, uploadedBy and title are required" });
    }
    if (!req.file && !link) {
      return res.status(400).json({ success: false, message: "Attach a file or give a link" });
    }

    // Resolve uploadedBy to a valid User ObjectId
    let uploadedBy = uploaderInput;
    if (!mongoose.Types.ObjectId.isValid(uploaderInput)) {
      let userDoc = await User.findOne({ uid: uploaderInput });
      if (!userDoc && process.env.NODE_ENV !== "production") {
        userDoc = await User.create({
          uid: uploaderInput,
          name: "Demo Teacher",
          email: `${uploaderInput}@demo.com`,
          role: "teacher",
        });
      }
      if (userDoc) {
        uploadedBy = userDoc._id;
      }
    }

    let type = "link";
    let fileUrl = "";
    let filePublicId = "";
    let fileResourceType = "";
    let generatedThumbnail = thumbnailUrl || "";

    if (req.file) {
      type = detectType(req.file.mimetype);
      const result = await uploadToCloudinary(
        req.file.buffer,
        "learning-materials"
      );
      fileUrl = result.secure_url;
      filePublicId = result.public_id;
      fileResourceType = result.resource_type;
      newlyUploadedPublicId = result.public_id;
      newlyUploadedResourceType = result.resource_type;
      if (type === "image") generatedThumbnail = result.secure_url;
    }

    const material = await Material.create({
      classId,
      uploadedBy,
      title,
      description,
      type,
      fileUrl,
      filePublicId,
      fileResourceType,
      thumbnailUrl: generatedThumbnail,
      link,
    });

    res.status(201).json({ success: true, message: "Material added", data: material });
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
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/materials/class/:classId
exports.getMaterialsByClass = async (req, res) => {
  try {
    const materials = await Material.find({ classId: req.params.classId }).sort({ createdAt: -1 });
    res.json({ success: true, data: materials });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/materials/:id
exports.getMaterialById = async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ success: false, message: "Material not found" });
    }
    res.json({ success: true, data: material });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/materials/:id
exports.deleteMaterial = async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ success: false, message: "Material not found" });
    }

    await Material.findByIdAndDelete(req.params.id);

    // Safe cleanup: Only delete from Cloudinary AFTER DB deletion succeeds
    if (material.filePublicId) {
      await deleteFromCloudinary(material.filePublicId, material.fileResourceType);
    }

    res.json({ success: true, message: "Material deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
