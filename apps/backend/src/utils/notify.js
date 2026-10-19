const Notification = require("../models/Notification");

exports.notifyUser = async ({ userId, title, message, type, refId }) => {
  try {
    await Notification.create({ userId, title, message, type, refId });
  } catch (err) {
    console.error("Notification failed:", err.message);
  }
};

exports.notifyMany = async (userIds, data) => {
  try {
    const docs = userIds.map((userId) => ({ userId, ...data }));
    if (docs.length) await Notification.insertMany(docs);
  } catch (err) {
    console.error("Notifications failed:", err.message);
  }
};