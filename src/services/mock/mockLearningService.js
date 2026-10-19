// FRONTEND PREVIEW ONLY. All learning records are in-memory sample data.
const classes = [
  { id: "biology-10", name: "Biology · Cell structures", subject: "Biology", teacher: "Ms. Rivera", room: "Room 204", schedule: "Mon, Wed · 09:30", students: 24, color: "mint", code: "CELL24" },
  { id: "math-10", name: "Mathematics · Algebra", subject: "Mathematics", teacher: "Mr. Chen", room: "Room 108", schedule: "Mon, Thu · 10:15", students: 28, color: "lavender", code: "MATH28" },
  { id: "history-10", name: "World History · 1900s", subject: "History", teacher: "Ms. Patel", room: "Room 312", schedule: "Tue, Fri · 13:00", students: 21, color: "blue", code: "PAST21" },
];

const assignments = [
  { id: "cell-notes", title: "Cell structures concept map", subject: "Biology", dueDate: "2026-10-21", status: "pending", description: "Create a concept map showing the role of key cell structures. Include at least six labeled parts and a short note about how two of them work together.", teacher: "Ms. Rivera", points: 20 },
  { id: "algebra-practice", title: "Linear equations practice", subject: "Mathematics", dueDate: "2026-10-24", status: "submitted", description: "Complete the practice set and show your working for each problem.", teacher: "Mr. Chen", points: 15 },
  { id: "history-source", title: "Primary source reflection", subject: "History", dueDate: "2026-10-18", status: "late", description: "Choose one source from class and write a short reflection on its perspective and context.", teacher: "Ms. Patel", points: 10 },
];

const materials = [
  { id: "m1", title: "Cell structures · lesson notes", type: "Notes", subject: "Biology", details: "Class notes · 8 pages", color: "mint" },
  { id: "m2", title: "Algebra formula sheet", type: "Document", subject: "Mathematics", details: "Reference · PDF preview", color: "lavender" },
  { id: "m3", title: "A visual guide to the cell", type: "Image", subject: "Biology", details: "Study visual · 4 min", color: "blue" },
  { id: "m4", title: "Reading historical sources", type: "Video", subject: "History", details: "Lesson replay · 12 min", color: "lime" },
];

let attendanceRecords = [
  { id: "a1", date: "2026-10-16", className: "Biology · Cell structures", status: "Present" },
  { id: "a2", date: "2026-10-15", className: "Mathematics · Algebra", status: "Present" },
  { id: "a3", date: "2026-10-14", className: "Biology · Cell structures", status: "Absent" },
  { id: "a4", date: "2026-10-13", className: "World History · 1900s", status: "Present" },
];

const events = [
  { id: "e1", date: "2026-10-19", time: "09:30", title: "Biology · Cell structures", type: "Class", location: "Room 204" },
  { id: "e2", date: "2026-10-19", time: "10:15", title: "Mathematics · Algebra", type: "Class", location: "Room 108" },
  { id: "e3", date: "2026-10-21", time: "23:59", title: "Cell structures concept map due", type: "Deadline", location: "Biology" },
  { id: "e4", date: "2026-10-23", time: "13:00", title: "Study group · Library", type: "Event", location: "Library" },
];

const copy = (items) => items.map((item) => ({ ...item, preview: true }));

export async function listClasses() { return copy(classes); }
export async function getClass(id) {
  const item = classes.find((entry) => entry.id === id);
  if (!item) throw new Error("Preview class not found.");
  return { ...item, preview: true };
}
export async function createClass(input) {
  const item = { ...input, id: `class-${Date.now()}`, students: 0, code: "PREVIEW42", color: "lavender" };
  classes.unshift(item);
  return { ...item, preview: true };
}
export async function joinClass(code) {
  const item = classes.find((entry) => entry.code.toLowerCase() === code.trim().toLowerCase());
  if (!item) throw new Error("That preview code was not found. Try CELL24, MATH28, or PAST21.");
  return { ...item, preview: true };
}
export async function listAssignments() { return copy(assignments); }
export async function getAssignment(id) {
  const item = assignments.find((entry) => entry.id === id);
  if (!item) throw new Error("Preview assignment not found.");
  return { ...item, preview: true };
}
export async function createAssignment(input) {
  const item = { ...input, id: `assignment-${Date.now()}`, status: "pending", points: Number(input.points) || 10 };
  assignments.unshift(item);
  return { ...item, preview: true };
}
export async function submitAssignment(id, fileName) {
  const item = assignments.find((entry) => entry.id === id);
  if (!item) throw new Error("Preview assignment not found.");
  item.status = "submitted";
  item.fileName = fileName;
  return { ...item, preview: true, localOnly: true };
}
export async function listMaterials() { return copy(materials); }
export async function addMaterial(input) {
  const item = { ...input, id: `material-${Date.now()}`, details: "Selected for local preview", color: "lavender" };
  materials.unshift(item);
  return { ...item, preview: true, localOnly: true };
}
export async function listAttendance() { return copy(attendanceRecords); }
export async function saveAttendance(records) {
  attendanceRecords = records.map((item) => ({ ...item }));
  return { records: copy(attendanceRecords), preview: true, localOnly: true };
}
export async function listCalendarEvents() { return copy(events); }