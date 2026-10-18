const Material = require("../models/Material");

const detectType = (mimetype = "") => {
  if (mimetype.startsWith("image/")) return "image";
  if (mimetype.startsWith("video/")) return "video";
  return "note";
};

// POST /api/materials  (form-data: classId, uploadedBy, title, description, file, link)
exports.createMaterial = async (req, res) => {
  try {
    const { classId, uploadedBy, title, description, link, thumbnailUrl } = req.body || {};
    if (!classId || !title || !uploadedBy) {
      return res
        .status(400)
        .json({ success: false, message: "classId, uploadedBy and title are required" });
    }
    if (!req.file && !link) {
      return res.status(400).json({ success: false, message: "Attach a file or give a link" });
    }

    const type = req.file ? detectType(req.file.mimetype) : "link";
    const material = await Material.create({
      classId,
      uploadedBy,
      title,
      description,
      type,
      fileUrl: req.file ? `/uploads/${req.file.filename}` : "",
      thumbnailUrl: type === "image" && req.file ? `/uploads/${req.file.filename}` : thumbnailUrl || "",
      link,
    });

    res.status(201).json({ success: true, message: "Material added", data: material });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/materials/class/:classId   (optional ?type=video)
exports.getMaterialsByClass = async (req, res) => {
  try {
    const filter = { classId: req.params.classId };
    if (req.query.type) filter.type = req.query.type;
    const data = await Material.find(filter).sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/materials/:id
exports.getMaterialById = async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) return res.status(404).json({ success: false, message: "Material not found" });
    res.json({ success: true, data: material });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/materials/:id
exports.deleteMaterial = async (req, res) => {
  try {
    const material = await Material.findByIdAndDelete(req.params.id);
    if (!material) return res.status(404).json({ success: false, message: "Material not found" });
    res.json({ success: true, message: "Material deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};