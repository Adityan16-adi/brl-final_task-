// Frontend-only account fixtures. Access codes are never persisted or sent anywhere.
const accounts = {
  student: { id: "STU-1001", name: "Alex Morgan", email: "student@example.com", role: "student" },
  teacher: { id: "TCH-2001", name: "Jordan Rivera", email: "teacher@example.com", role: "teacher" },
};

const SESSION_KEY = "unified-learn-session";
const ACCESS_CODE = "learn2026";

function saveSession(user) {
  const session = { user: { ...user }, authenticated: true };
  window.localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return session;
}

export async function loginAccount({ role, accountId, accessCode }) {
  const expectedAccount = accounts[role];
  if (!expectedAccount) throw new Error("Use the separate student or teacher sign-in page.");

  const currentSession = await getSession();
  if (currentSession && currentSession.user.role !== role) {
    throw new Error("Sign out before using a different role account.");
  }

  const account = Object.values(accounts).find((user) => user.id === accountId?.trim().toUpperCase());
  if (!account) throw new Error("That account ID was not found. Check the ID shown on this page.");
  if (account.role !== role) {
    throw new Error(`That account belongs to the ${account.role} portal. Use ${account.role === "student" ? "Student" : "Teacher"} Login.`);
  }
  if (accessCode !== ACCESS_CODE) throw new Error("The access code is incorrect.");

  return saveSession(expectedAccount);
}

export async function registerAccount({ role, name }) {
  const baseUser = accounts[role];
  if (!baseUser) throw new Error("Use the separate student or teacher registration page.");
  const currentSession = await getSession();
  if (currentSession && currentSession.user.role !== role) {
    throw new Error("Sign out before using a different role account.");
  }
  return saveSession({ ...baseUser, name: name?.trim() || baseUser.name });
}

export async function getSession() {
  const saved = window.localStorage.getItem(SESSION_KEY);
  if (!saved) return null;
  try {
    const session = JSON.parse(saved);
    const account = Object.values(accounts).find((user) => user.id === session.user?.id);
    if (!session.authenticated || !account) {
      window.localStorage.removeItem(SESSION_KEY);
      return null;
    }
    return {
      user: { ...account, name: typeof session.user.name === "string" && session.user.name.trim() ? session.user.name : account.name },
    };
  } catch {
    window.localStorage.removeItem(SESSION_KEY);
    return null;
  }
}

export async function logoutAccount() {
  window.localStorage.removeItem(SESSION_KEY);
  return { success: true };
}