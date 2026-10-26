const { applicationDefault, getApps, initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const User = require("../models/User");

function firebaseAuth() {
  if (!process.env.FIREBASE_PROJECT_ID) throw new Error("FIREBASE_PROJECT_ID is required for protected API routes.");
  const app = getApps()[0] || initializeApp({ credential: applicationDefault(), projectId: process.env.FIREBASE_PROJECT_ID });
  return getAuth(app);
}

module.exports = async function authenticate(req, res, next) {
  const header = req.headers.authorization || "";
  if (!header.startsWith("Bearer ")) return res.status(401).json({ success: false, message: "A Firebase ID token is required." });
  try {
    const decoded = await firebaseAuth().verifyIdToken(header.slice(7));
    const user = await User.findOne({ uid: decoded.uid });
    if (!user) return res.status(403).json({ success: false, message: "User profile is not registered. Sync the account through the legacy Firebase auth service first." });
    req.auth = decoded;
    req.user = user;
    next();
  } catch (error) {
    if (error.code && String(error.code).startsWith("auth/")) return res.status(401).json({ success: false, message: "Firebase ID token is invalid or expired." });
    next(error);
  }
};
