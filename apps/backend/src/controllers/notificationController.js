const Notification = require("../models/Notification");
const mongoose = require("mongoose");

const selfOnly = (req, res) => {
  if (!mongoose.isValidObjectId(req.params.userId)) {
    res.status(400).json({ success: false, message: "User ID must be a valid MongoDB ObjectId." });
    return false;
  }
  if (String(req.user._id) !== req.params.userId) {
    res.status(403).json({ success: false, message: "You can access only your own notifications." });
    return false;
  }
  return true;
};

// GET /api/notifications/user/:userId
exports.getMyNotifications = async (req, res) => {
  try {
    if (!selfOnly(req, res)) return;
    const data = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/notifications/user/:userId/unread-count
exports.getUnreadCount = async (req, res) => {
  try {
    if (!selfOnly(req, res)) return;
    const count = await Notification.countDocuments({ userId: req.user._id, isRead: false });
    res.json({ success: true, data: { count } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: "Notification ID must be a valid MongoDB ObjectId." });
    const n = await Notification.findOneAndUpdate({ _id: req.params.id, userId: req.user._id }, { isRead: true }, { new: true });
    if (!n) return res.status(404).json({ success: false, message: "Notification not found" });
    res.json({ success: true, data: n });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/notifications/user/:userId/read-all
exports.markAllAsRead = async (req, res) => {
  try {
    if (!selfOnly(req, res)) return;
    await Notification.updateMany({ userId: req.user._id, isRead: false }, { isRead: true });
    res.json({ success: true, message: "All marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
