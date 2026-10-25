const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");
const {
  createMaterial,
  getAllMaterials,
  getMaterialsByClass,
  getMaterialById,
  deleteMaterial,
} = require("../controllers/materialController");

const handleUpload = (req, res, next) => {
  upload.single("file")(req, res, (err) => {
    if (err) {
      const isSizeLimit = err.code === "LIMIT_FILE_SIZE";
      return res.status(400).json({
        success: false,
        message: isSizeLimit
          ? "File size exceeds the 25MB limit. Please select a smaller file."
          : (err.message || "File upload error"),
      });
    }
    next();
  });
};

router.post("/", handleUpload, createMaterial);
router.post("/upload", handleUpload, createMaterial);
router.get("/", getAllMaterials);
router.get("/class/:classId", getMaterialsByClass);
router.get("/:id", getMaterialById);
router.delete("/:id", deleteMaterial);

module.exports = router;
