import { GoogleAuthProvider, sendPasswordResetEmail, signInWithEmailAndPassword, signInWithPopup, signOut } from "firebase/auth";
import { dataModeError, isBackendMode, apiGetCurrentProfile } from "./api/backendAdapter.js";
import { firebaseErrorMessage, getFirebaseAuth } from "./api/firebaseClient.js";
import { getSession as getMockSession, loginAccount as mockLogin, logoutAccount as mockLogout, registerAccount as mockRegister } from "./mock/mockAuthService.js";

function mapProfile(profile) {
  if (!profile?.id || !["student", "teacher"].includes(profile.role)) {
    throw new Error("The backend returned an incomplete user profile. Ask your administrator to check your MongoDB user record.");
  }
  return {
    id: String(profile.id),
    name: profile.name || profile.email || "Unified Learn user",
    email: profile.email || "",
    role: profile.role,
  };
}

async function resolveApiSession() {
  const auth = getFirebaseAuth();
  await auth.authStateReady();
  if (!auth.currentUser) return null;
  try {
    const profile = await apiGetCurrentProfile();
    return { user: mapProfile(profile), authenticated: true };
  } catch (error) {
    await signOut(auth);
    throw error;
  }
}

let apiSessionPromise;
function requireValidMode() {
  if (dataModeError) throw new Error(dataModeError);
}

export function getSession() {
  requireValidMode();
  if (!isBackendMode) return getMockSession();
  if (!apiSessionPromise) {
    apiSessionPromise = resolveApiSession().finally(() => { apiSessionPromise = null; });
  }
  return apiSessionPromise;
}

export async function loginAccount(credentials) {
  requireValidMode();
  if (!isBackendMode) return mockLogin(credentials);
  const auth = getFirebaseAuth();
  try {
    const result = await signInWithEmailAndPassword(auth, credentials.email.trim(), credentials.password);
    await result.user.getIdToken();
    let profile;
    try {
      profile = mapProfile(await apiGetCurrentProfile());
    } catch (error) {
      await signOut(auth);
      throw error;
    }
    if (profile.role !== credentials.role) {
      await signOut(auth);
      throw new Error(`This account belongs to the ${profile.role} portal. Use ${profile.role === "student" ? "Student" : "Teacher"} Login.`);
    }
    const session = { user: profile, authenticated: true };
    apiSessionPromise = Promise.resolve(session);
    return session;
  } catch (error) {
    if (error?.message?.includes("belongs to the") || error?.message?.includes("backend returned an incomplete")) throw error;
    if (error?.status === 403) {
      await signOut(auth);
      throw new Error("Firebase sign-in succeeded, but this account has no linked Unified Learn profile. Ask an administrator to sync its Firebase UID and assign the correct role.", { cause: error });
    }
    if (error?.status === 401) {
      await signOut(auth);
      throw new Error("The backend rejected this Firebase session. Check that the backend uses the same Firebase project and is available.", { cause: error });
    }
    if (auth.currentUser) await signOut(auth);
    throw new Error(firebaseErrorMessage(error), { cause: error });
  }
}

function googleErrorMessage(error) {
  const messages = {
    "auth/popup-blocked": "Your browser blocked the Google sign-in window. Allow pop-ups for this site and try again.",
    "auth/popup-closed-by-user": "Google sign-in was cancelled before it finished.",
    "auth/cancelled-popup-request": "Another Google sign-in window is already open. Finish it or try again.",
    "auth/unauthorized-domain": "This site is not authorized for Google sign-in in the Firebase project. Contact your administrator.",
    "auth/operation-not-allowed": "Google sign-in is not enabled for this Firebase project. Contact your administrator.",
    "auth/account-exists-with-different-credential": "This email already uses another sign-in method. Sign in with that method or contact your administrator.",
  };
  return messages[error?.code] || firebaseErrorMessage(error);
}

export async function loginWithGoogle(role) {
  requireValidMode();
  if (!isBackendMode) {
    throw new Error("Google sign-in is available only when API mode and Firebase are configured. Mock mode does not use Firebase.");
  }
  const auth = getFirebaseAuth();
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: "select_account" });
  try {
    const result = await signInWithPopup(auth, provider);
    await result.user.getIdToken();
    let profile;
    try {
      profile = mapProfile(await apiGetCurrentProfile());
    } catch (error) {
      if (error?.status === 403 || error?.status === 404 || error?.message?.includes("incomplete user profile")) {
        await signOut(auth);
        throw new Error("Google sign-in succeeded, but this account has no linked Unified Learn profile. Ask your college administrator to provision and link your account.", { cause: error });
      }
      if (error?.status === 401) await signOut(auth);
      throw error;
    }
    if (profile.role !== role) {
      await signOut(auth);
      throw new Error(`This account belongs to the ${profile.role} portal. Use ${profile.role === "student" ? "Student" : "Teacher"} Login.`);
    }
    const session = { user: profile, authenticated: true };
    apiSessionPromise = Promise.resolve(session);
    return session;
  } catch (error) {
    if (error?.message?.includes("belongs to the") || error?.message?.includes("no linked Unified Learn profile")) throw error;
    throw new Error(googleErrorMessage(error), { cause: error });
  }
}

export async function registerAccount(input) {
  requireValidMode();
  if (!isBackendMode) return mockRegister(input);
  throw new Error("Online registration is not available in this frontend. Ask an administrator to create and link your Firebase and Unified Learn profile.");
}

export async function resetPassword(email) {
  requireValidMode();
  if (!isBackendMode) {
    throw new Error("Password recovery is not connected in mock mode. No email was sent.");
  }
  const auth = getFirebaseAuth();
  try {
    await sendPasswordResetEmail(auth, email.trim());
  } catch (error) {
    throw new Error(firebaseErrorMessage(error), { cause: error });
  }
}

export async function logoutAccount() {
  requireValidMode();
  if (!isBackendMode) return mockLogout();
  const auth = getFirebaseAuth();
  await signOut(auth);
  apiSessionPromise = null;
  return { success: true };
}
