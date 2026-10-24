const fs = require("fs");
const path = require("path");
const {
    initializeApp,
    cert,
    getApps
} = require("firebase-admin/app");

const {
    getAuth
} = require("firebase-admin/auth");

let app = null;
let auth = null;

const initFirebase = () => {
    // If already initialized in this process, reuse
    if (getApps().length > 0) {
        app = getApps()[0];
        try {
            auth = getAuth(app);
        } catch {
            auth = null;
        }
        return { app, auth };
    }

    let serviceAccountFile = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
        ? path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
        : path.join(__dirname, "firebase-service-account.json");

    if (!fs.existsSync(serviceAccountFile)) {
        // Fallback to config directory if relative path was given from another cwd
        const fallback = path.join(__dirname, "firebase-service-account.json");
        if (fs.existsSync(fallback)) {
            serviceAccountFile = fallback;
        }
    }

    try {
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            let creds;
            const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim().replace(/^\uFEFF/, "");
            try {
                creds = JSON.parse(raw);
            } catch {
                try {
                    creds = JSON.parse(Buffer.from(raw, "base64").toString("utf-8").replace(/^\uFEFF/, ""));
                } catch {
                    console.error("Firebase Admin initialization failed: Malformed JSON in FIREBASE_SERVICE_ACCOUNT.");
                    return { app: null, auth: null };
                }
            }

            if (!creds || typeof creds !== "object" || !creds.project_id || !creds.client_email || !creds.private_key) {
                console.error("Firebase Admin initialization failed: FIREBASE_SERVICE_ACCOUNT is missing required fields (project_id, client_email, private_key).");
                return { app: null, auth: null };
            }

            app = initializeApp({ credential: cert(creds) });
            auth = getAuth(app);
            console.log(`Firebase Admin initialized successfully from environment for project: ${creds.project_id}`);
            return { app, auth };
        }

        if (fs.existsSync(serviceAccountFile)) {
            let creds;
            try {
                const rawFile = fs.readFileSync(serviceAccountFile, "utf-8").replace(/^\uFEFF/, "");
                creds = JSON.parse(rawFile);
            } catch {
                console.error(`Firebase Admin initialization failed: Malformed JSON in ${serviceAccountFile}.`);
                return { app: null, auth: null };
            }

            if (!creds || typeof creds !== "object" || !creds.project_id || !creds.client_email || !creds.private_key) {
                console.error("Firebase Admin initialization failed: Credentials file is missing required fields (project_id, client_email, private_key).");
                return { app: null, auth: null };
            }

            app = initializeApp({ credential: cert(creds) });
            auth = getAuth(app);
            console.log(`Firebase Admin initialized successfully from file for project: ${creds.project_id}`);
            return { app, auth };
        }

        console.warn("Firebase credentials not found. Authentication features will fail closed with 503 Service Unavailable.");
    } catch (error) {
        console.error("Firebase Admin initialization error:", error.message || "Unknown error");
    }

    return { app: null, auth: null };
};

const result = initFirebase();
app = result.app;
auth = result.auth;

module.exports = {
    app,
    auth,
    initFirebase,
};