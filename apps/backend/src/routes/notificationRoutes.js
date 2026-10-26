const express = require("express");
const router = express.Router();
const authenticate = require("../middleware/authenticate");
const {
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
} = require("../controllers/notificationController");

router.use(authenticate);
router.get("/user/:userId", getMyNotifications);
router.get("/me", (req, res, next) => { req.params.userId = String(req.user._id); next(); }, getMyNotifications);
router.get("/user/:userId/unread-count", getUnreadCount);
router.put("/user/:userId/read-all", markAllAsRead);
router.put("/me/read-all", (req, res, next) => { req.params.userId = String(req.user._id); next(); }, markAllAsRead);
router.put("/:id/read", markAsRead);

module.exports = router;
