const { initializeApp, applicationDefault, getApps } = require("firebase-admin/app");

const {
    getAuth
} = require("firebase-admin/auth");

if (!process.env.FIREBASE_PROJECT_ID) {
    throw new Error("FIREBASE_PROJECT_ID is required to initialize Firebase Admin.");
}

const app = getApps().length
    ? getApps()[0]
    : initializeApp({
        credential: applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID
    });

console.log("Firebase Admin initialized");

module.exports = {
    app,
    auth: getAuth(app)
};
