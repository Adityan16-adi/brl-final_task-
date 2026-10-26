const express = require("express");
const router = express.Router();
const {
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
} = require("../controllers/notificationController");

router.get("/", (req, res) => {
  const userId = req.user?.uid || req.query.userId;
  if (!userId) {
    return res.json({ success: true, data: [] });
  }
  req.params.userId = userId;
  return getMyNotifications(req, res);
});

router.get("/user/:userId", getMyNotifications);
router.get("/user/:userId/unread-count", getUnreadCount);
router.put("/user/:userId/read-all", markAllAsRead);
router.put("/read-all", (req, res) => {
  const userId = req.user?.uid || req.body.userId;
  if (!userId) return res.json({ success: true, message: "All marked as read" });
  req.params.userId = userId;
  return markAllAsRead(req, res);
});
router.put("/:id/read", markAsRead);

module.exports = router;
