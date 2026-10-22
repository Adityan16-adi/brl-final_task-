const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");
const {
  createMaterial,
  getMaterialsByClass,
  getMaterialById,
  deleteMaterial,
} = require("../controllers/materialController");

router.post("/", upload.single("file"), createMaterial);
router.get("/class/:classId", getMaterialsByClass);
router.get("/:id", getMaterialById);
router.delete("/:id", deleteMaterial);

module.exports = router;