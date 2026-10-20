const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://localhost:5000/api").replace(/\/$/, "");
const DATA_MODE = import.meta.env.VITE_DATA_MODE || "mock";

export const isBackendMode = DATA_MODE === "api";
export const dataModeError = DATA_MODE === "mock" || DATA_MODE === "api"
  ? ""
  : `Invalid VITE_DATA_MODE '${DATA_MODE}'. Set it to 'mock' or 'api' in .env.local, then restart the frontend.`;

function envId(name) {
  const value = import.meta.env[name];
  if (!value) throw new Error(`Backend testing setup missing ${name}. Add the MongoDB ID to frontend/.env.local.`);
  if (!/^[a-f\d]{24}$/i.test(value)) throw new Error(`${name} must be a 24-character MongoDB ObjectId. Replace the placeholder in frontend/.env.local.`);
  return value;
}

function currentUser() {
  try {
    return JSON.parse(window.localStorage.getItem("unified-learn-session") || "null")?.user || null;
  } catch { return null; }
}

function currentRole() { return currentUser()?.role || "student"; }
function userId() {
  return currentRole() === "teacher"
    ? envId("VITE_DEMO_TEACHER_ID")
    : envId("VITE_DEMO_STUDENT_ID");
}
function classId() { return envId("VITE_DEMO_CLASS_ID"); }

async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers: options.body instanceof FormData
        ? { ...(options.headers || {}) }
        : { "Content-Type": "application/json", ...(options.headers || {}) },
    });
  } catch {
    throw new Error(`Cannot reach the backend at ${API_BASE}. Start the backend and check VITE_API_BASE_URL.`);
  }
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || payload.success === false) {
    throw new Error(payload.message || `Backend request failed (${response.status}).`);
  }
  return Object.prototype.hasOwnProperty.call(payload, "data") ? payload.data : payload;
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
  if (currentRole() !== "student") return assignments.map((item) => mapAssignment(item));
  const studentId = userId();
  return Promise.all(assignments.map(async (item) => {
    try {
      const submission = await request(`/submissions/assignment/${encodeURIComponent(idOf(item))}/student/${encodeURIComponent(studentId)}`);
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
  if (currentRole() === "student") {
    try { submission = await request(`/submissions/assignment/${encodeURIComponent(id)}/student/${encodeURIComponent(userId())}`); }
    catch (error) { if (!/not found|404/i.test(error.message)) throw error; }
  }
  return mapAssignment(item, submission);
}

export async function apiCreateAssignment(input) {
  if (currentRole() !== "teacher") throw new Error("Only the teacher portal can create assignments.");
  const created = await request("/assignments", { method: "POST", body: JSON.stringify({
    classId: classId(), createdBy: userId(), title: input.title,
    description: input.description, dueDate: input.dueDate,
    maxMarks: Number(input.points) || 10,
  }) });
  return mapAssignment(created);
}

export async function apiSubmitAssignment(assignmentId, file, text = "") {
  if (currentRole() !== "student") throw new Error("Only the student portal can submit assignments.");
  if (!(file instanceof File) && !text.trim()) throw new Error("Choose a file or enter submission text.");
  const body = new FormData();
  body.append("studentId", userId());
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
  if (currentRole() !== "teacher") throw new Error("Only the teacher portal can add learning materials.");
  if (!input.link?.trim()) throw new Error("Enter a resource URL. The current form does not upload material files yet.");
  const body = new FormData();
  body.append("classId", classId()); body.append("uploadedBy", userId());
  body.append("title", input.title); body.append("description", input.subject || ""); body.append("link", input.link.trim());
  const item = await request("/materials", { method: "POST", body });
  return { ...item, id: idOf(item), subject: input.subject || "Class resources", type: "Document", details: input.link, color: "lavender", preview: false };
}

export async function apiListNotifications() {
  return asArray(await request(`/notifications/user/${encodeURIComponent(userId())}`)).map((item) => ({
    ...item, id: idOf(item), body: item.message || "", category: item.type === "assignment" || item.type === "grade" ? "Assignments" : "Classes",
    unread: !item.isRead, href: item.type === "assignment" && item.refId ? `/app/assignments/${item.refId}` : "/app/notifications", preview: false,
  }));
}

export async function apiMarkNotificationRead(id) {
  await request(`/notifications/${encodeURIComponent(id)}/read`, { method: "PUT", body: JSON.stringify({}) });
  return apiListNotifications();
}

export async function apiMarkAllNotificationsRead() {
  await request(`/notifications/user/${encodeURIComponent(userId())}/read-all`, { method: "PUT", body: JSON.stringify({}) });
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
