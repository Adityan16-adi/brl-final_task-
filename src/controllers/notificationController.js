const Notification = require("../models/Notification");

// GET /api/notifications/user/:userId
exports.getMyNotifications = async (req, res) => {
  try {
    const data = await Notification.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/notifications/user/:userId/unread-count
exports.getUnreadCount = async (req, res) => {
  try {
    const count = await Notification.countDocuments({ userId: req.params.userId, isRead: false });
    res.json({ success: true, data: { count } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
  try {
    const n = await Notification.findByIdAndUpdate(req.params.id, { isRead: true }, { new: true });
    if (!n) return res.status(404).json({ success: false, message: "Notification not found" });
    res.json({ success: true, data: n });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/notifications/user/:userId/read-all
exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ userId: req.params.userId, isRead: false }, { isRead: true });
    res.json({ success: true, message: "All marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};