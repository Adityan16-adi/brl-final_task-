const {
    initializeApp,
    cert,
    getApps
} = require("firebase-admin/app");

const {
    getAuth
} = require("firebase-admin/auth");

const serviceAccount = require("./firebase-service-account.json");

const app = getApps().length
    ? getApps()[0]
    : initializeApp({
        credential: cert(serviceAccount)
    });

console.log("Firebase Admin connected successfully!");

module.exports = {
    app,
    auth: getAuth(app)
};