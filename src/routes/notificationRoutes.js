const express = require("express");
const router = express.Router();
const {
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
} = require("../controllers/notificationController");

router.get("/user/:userId", getMyNotifications);
router.get("/user/:userId/unread-count", getUnreadCount);
router.put("/user/:userId/read-all", markAllAsRead);
router.put("/:id/read", markAsRead);

module.exports = router;
