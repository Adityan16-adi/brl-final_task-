const express = require("express");
const authenticate = require("../middleware/authenticate");
const router = express.Router();

router.get("/me", authenticate, (req, res) => {
  res.json({ success: true, data: {
    id: req.user._id,
    name: req.user.name,
    email: req.user.email,
    role: req.user.role,
  } });
});

module.exports = router;
