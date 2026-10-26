import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseKeys = [
  "VITE_FIREBASE_API_KEY",
  "VITE_FIREBASE_AUTH_DOMAIN",
  "VITE_FIREBASE_PROJECT_ID",
  "VITE_FIREBASE_APP_ID",
];

export function getFirebaseConfig() {
  const missing = firebaseKeys.filter((key) => !import.meta.env[key]?.trim());
  if (missing.length) {
    throw new Error(`API mode needs Firebase web configuration. Set ${missing.join(", ")} in apps/web/.env.local and restart Vite.`);
  }
  return {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY.trim(),
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN.trim(),
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID.trim(),
    appId: import.meta.env.VITE_FIREBASE_APP_ID.trim(),
  };
}

export function getFirebaseAuth() {
  const config = getFirebaseConfig();
  const app = getApps().length ? getApp() : initializeApp(config);
  return getAuth(app);
}

export async function getFirebaseIdToken() {
  const auth = getFirebaseAuth();
  await auth.authStateReady();
  if (!auth.currentUser) {
    throw new Error("Sign in with your provisioned account to use API mode.");
  }
  return auth.currentUser.getIdToken();
}

export function firebaseErrorMessage(error) {
  const messages = {
    "auth/invalid-credential": "The email or password is incorrect.",
    "auth/user-not-found": "No Firebase account was found for this email.",
    "auth/wrong-password": "The email or password is incorrect.",
    "auth/invalid-email": "Enter a valid email address.",
    "auth/too-many-requests": "Too many attempts. Wait a little and try again.",
    "auth/network-request-failed": "Firebase could not be reached. Check your connection and try again.",
    "auth/operation-not-allowed": "Email and password sign-in is not enabled for this Firebase project.",
    "auth/user-disabled": "This Firebase account is disabled. Contact your administrator.",
  };
  return messages[error?.code] || error?.message || "Firebase authentication could not be completed.";
}
