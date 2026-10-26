const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");
const authenticate = require("../middleware/authenticate");
const {
  createMaterial,
  getMaterialsByClass,
  getMaterialById,
  deleteMaterial,
} = require("../controllers/materialController");

router.use(authenticate);
router.post("/", upload.single("file"), createMaterial);
router.get("/class/:classId", getMaterialsByClass);
router.get("/:id", getMaterialById);
router.delete("/:id", deleteMaterial);

module.exports = router;
