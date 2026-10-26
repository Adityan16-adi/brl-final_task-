import { getFirebaseIdToken } from "./firebaseClient.js";

const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://localhost:5000/api").replace(/\/$/, "");
const DATA_MODE = (import.meta.env.VITE_DATA_MODE || "mock").trim().toLowerCase();
let currentProfile;

export const isBackendMode = DATA_MODE === "api";
export const dataModeError = DATA_MODE === "mock" || DATA_MODE === "api"
  ? ""
  : `Invalid VITE_DATA_MODE '${DATA_MODE}'. Set it to 'mock' or 'api' in apps/web/.env.local, then restart the frontend.`;

function envId(name) {
  const value = import.meta.env[name];
  if (!value) throw new Error(`Backend testing setup missing ${name}. Add the MongoDB ID to apps/web/.env.local.`);
  if (!/^[a-f\d]{24}$/i.test(value)) throw new Error(`${name} must be a 24-character MongoDB ObjectId. Replace the placeholder in apps/web/.env.local.`);
  return value;
}

function classId() { return envId("VITE_DEMO_CLASS_ID"); }

async function request(path, options = {}) {
  let response;
  try {
    if (
  !/^https?:\/\//i.test(API_BASE) &&
  !API_BASE.startsWith('/')
) {
  throw new Error(
    "VITE_API_BASE_URL must be a relative path or an absolute HTTP(S) URL."
  );
}
    const token = await getFirebaseIdToken();
    const headers = new Headers(options.headers || {});
    headers.set("Authorization", `Bearer ${token}`);
    if (!(options.body instanceof FormData) && options.body != null && !headers.has("Content-Type")) {
      headers.set("Content-Type", "application/json");
    }
    const timeoutSignal = AbortSignal.timeout(15000);
    const signal = options.signal ? AbortSignal.any([options.signal, timeoutSignal]) : timeoutSignal;
    response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      signal,
    });
  } catch (error) {
    if (error?.name === "TimeoutError") {
      throw new Error(`The backend request timed out at ${API_BASE}. Check the backend service and try again.`, { cause: error });
    }
    if (error instanceof TypeError) {
      throw new Error(`Cannot reach the backend at ${API_BASE}. Check that the backend is running, VITE_API_BASE_URL is browser-accessible, and its CORS origin allows this frontend.`, { cause: error });
    }
    if (error?.name === "AbortError") throw new Error("The backend request was cancelled.", { cause: error });
    throw error;
  }
  const raw = await response.text();
  let payload = {};
  if (raw) {
    try { payload = JSON.parse(raw); }
    catch { throw new Error(`Backend returned an unreadable response (${response.status}).`); }
  }
  if (!response.ok || payload.success === false) {
    const fallbacks = {
      401: "The backend rejected the Firebase session. Sign in again and check the backend Firebase project configuration.",
      403: "The signed-in account is not allowed to access this record, or its backend profile is not provisioned.",
      404: "The requested record was not found or is not available to this account.",
      503: "The backend or one of its required services is unavailable.",
    };
    const error = new Error(payload.message || fallbacks[response.status] || `Backend request failed (${response.status}).`);
    error.status = response.status;
    throw error;
  }
  return Object.prototype.hasOwnProperty.call(payload, "data") ? payload.data : payload;
}

export async function apiGetCurrentProfile() {
  const profile = await request("/auth/me");
  currentProfile = profile;
  return profile;
}

const asArray = (data) => Array.isArray(data) ? data : [];
const idOf = (item) => item?._id || item?.id;

function mapAssignment(item, submission = null) {
  return {
    ...item,
    id: idOf(item),
    subject: item.subject || item.className || "Class assignment",
    dueDate: item.dueDate ? String(item.dueDate).slice(0, 10) : "",
    description: item.description || "",
    teacher: item.teacher || "Teacher",
    points: Number(item.maxMarks ?? item.points ?? 10),
    status: submission?.status === "graded" ? "graded" : submission ? "submitted" : "pending",
    fileName: submission?.fileUrl ? submission.fileUrl.split("/").pop() : undefined,
    marks: submission?.marks,
    feedback: submission?.feedback,
    preview: false,
  };
}

export async function apiListAssignments() {
  const assignments = asArray(await request(`/assignments/class/${encodeURIComponent(classId())}`));
  const profile = currentProfile || await apiGetCurrentProfile();
  if (profile.role !== "student") return assignments.map((item) => mapAssignment(item));
  return Promise.all(assignments.map(async (item) => {
    try {
      const submission = await request(`/submissions/assignment/${encodeURIComponent(idOf(item))}/me`);
      return mapAssignment(item, submission);
    } catch (error) {
      // A missing submission is a normal state; other failures must be visible.
      if (/not found|404/i.test(error.message)) return mapAssignment(item);
      throw error;
    }
  }));
}

export async function apiGetAssignment(id) {
  const item = await request(`/assignments/${encodeURIComponent(id)}`);
  let submission = null;
  const profile = currentProfile || await apiGetCurrentProfile();
  if (profile.role === "student") {
    try { submission = await request(`/submissions/assignment/${encodeURIComponent(id)}/me`); }
    catch (error) { if (!/not found|404/i.test(error.message)) throw error; }
  }
  return mapAssignment(item, submission);
}

export async function apiCreateAssignment(input) {
  const created = await request("/assignments", { method: "POST", body: JSON.stringify({
    classId: classId(), title: input.title,
    description: input.description, dueDate: input.dueDate,
    maxMarks: Number(input.points) || 10,
  }) });
  return mapAssignment(created);
}

export async function apiSubmitAssignment(assignmentId, file, text = "") {
  if (!(file instanceof File) && !text.trim()) throw new Error("Choose a file or enter submission text.");
  const body = new FormData();
  if (text.trim()) body.append("text", text.trim());
  if (file instanceof File) body.append("file", file);
  return request(`/submissions/assignment/${encodeURIComponent(assignmentId)}`, { method: "POST", body });
}

export async function apiListMaterials() {
  return asArray(await request(`/materials/class/${encodeURIComponent(classId())}`)).map((item) => ({
    ...item, id: idOf(item), subject: item.subject || "Class resources",
    type: ({ note: "Notes", image: "Image", video: "Video", link: "Document" })[item.type] || "Notes",
    details: item.description || item.link || item.fileUrl || "Learning resource",
    color: "lavender", preview: false,
  }));
}

export async function apiAddMaterial(input) {
  if (!input.link?.trim()) throw new Error("Enter a resource URL. The current form does not upload material files yet.");
  const body = new FormData();
  body.append("classId", classId());
  body.append("title", input.title); body.append("description", input.subject || ""); body.append("link", input.link.trim());
  const item = await request("/materials", { method: "POST", body });
  return { ...item, id: idOf(item), subject: input.subject || "Class resources", type: "Document", details: input.link, color: "lavender", preview: false };
}

export async function apiListNotifications() {
  return asArray(await request(`/notifications/me`)).map((item) => ({
    ...item, id: idOf(item), body: item.message || "", category: item.type === "assignment" || item.type === "grade" ? "Assignments" : "Classes",
    unread: !item.isRead, href: item.type === "assignment" && item.refId ? `/app/assignments/${item.refId}` : "/app/notifications", preview: false,
  }));
}

export async function apiMarkNotificationRead(id) {
  await request(`/notifications/${encodeURIComponent(id)}/read`, { method: "PUT", body: JSON.stringify({}) });
  return apiListNotifications();
}

export async function apiMarkAllNotificationsRead() {
  await request(`/notifications/me/read-all`, { method: "PUT", body: JSON.stringify({}) });
  return apiListNotifications();
}

export async function apiListCalendarEvents() {
  const now = new Date();
  const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  return apiListCalendarMonth(month);
}

export async function apiListCalendarMonth(month) {
  return asArray(await request(`/calendar/class/${encodeURIComponent(classId())}?month=${month}`)).map((item) => ({
    ...item, id: idOf(item), date: item.date ? String(item.date).slice(0, 10) : "",
    time: "23:59", type: item.type === "assignment" ? "Deadline" : item.type,
    location: "Class deadline", preview: false,
  }));
}

export async function apiAskMentor(message) {
  const result = await request("/study/mentor", { method: "POST", body: JSON.stringify({ message }) });
  return { text: result.text };
}

export async function apiGenerateQuiz({ count = 3, difficulty = "medium", text = "" } = {}) {
  const result = await request("/study/quiz", { method: "POST", body: JSON.stringify({ text, count: Number(count), difficulty }) });
  return { questions: (result.questions || []).map((item) => ({ prompt: item.question, options: item.options, answer: item.answer_index, explanation: item.explanation })) };
}

export async function apiListAttendance() {
  const result = await request("/attendance/student/me");
  return asArray(result).map((item) => ({
    ...item,
    id: idOf(item),
    preview: false,
  }));
}

export async function apiGetClassRosterAttendance(classIdValue, date) {
  const targetId = classIdValue || classId();
  const query = date ? `?date=${encodeURIComponent(date)}` : "";
  const result = await request(`/attendance/class/${encodeURIComponent(targetId)}${query}`);
  return {
    className: result.className || "Class",
    students: asArray(result.students),
    records: asArray(result.records).map((item) => ({
      ...item,
      id: idOf(item),
      preview: false,
    })),
    preview: false,
  };
}

export async function apiSaveClassAttendance(classIdValue, date, records) {
  const targetId = classIdValue || classId();
  const result = await request(`/attendance/class/${encodeURIComponent(targetId)}`, {
    method: "POST",
    body: JSON.stringify({ date, records }),
  });
  return {
    records: asArray(result).map((item) => ({ ...item, id: idOf(item), preview: false })),
    savedAt: new Date().toISOString(),
    preview: false,
  };
}
