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

const enrolledStudentsByClass = {
  "biology-10": [
    { id: "STU-1001", name: "Alex Morgan", email: "student@example.com" },
    { id: "STU-1002", name: "Samira Khan", email: "samira@example.com" },
    { id: "STU-1003", name: "Liam Patel", email: "liam@example.com" },
    { id: "STU-1004", name: "Elena Rostova", email: "elena@example.com" },
    { id: "STU-1005", name: "Marcus Johnson", email: "marcus@example.com" },
    { id: "STU-1006", name: "Priya Sharma", email: "priya@example.com" },
  ],
  "math-10": [
    { id: "STU-1001", name: "Alex Morgan", email: "student@example.com" },
    { id: "STU-1002", name: "Samira Khan", email: "samira@example.com" },
    { id: "STU-1005", name: "Marcus Johnson", email: "marcus@example.com" },
    { id: "STU-1007", name: "Devon Reed", email: "devon@example.com" },
  ],
  "history-10": [
    { id: "STU-1001", name: "Alex Morgan", email: "student@example.com" },
    { id: "STU-1003", name: "Liam Patel", email: "liam@example.com" },
    { id: "STU-1004", name: "Elena Rostova", email: "elena@example.com" },
  ],
};

let attendanceRecords = [
  // Biology records (15 classes: 13 Present, 1 Absent, 1 Late -> 86.7%)
  { id: "att-b15", date: "2026-10-24", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b14", date: "2026-10-22", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b13", date: "2026-10-19", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b12", date: "2026-10-17", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b11", date: "2026-10-16", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b10", date: "2026-10-15", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Late" },
  { id: "att-b09", date: "2026-10-14", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-b08", date: "2026-10-12", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b07", date: "2026-10-10", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b06", date: "2026-10-08", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b05", date: "2026-10-05", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b04", date: "2026-10-03", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b03", date: "2026-10-01", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b02", date: "2026-09-28", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-b01", date: "2026-09-26", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },

  // Other students in Biology on 2026-10-24
  { id: "att-b15-2", date: "2026-10-24", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1002", studentName: "Samira Khan", status: "Present" },
  { id: "att-b15-3", date: "2026-10-24", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1003", studentName: "Liam Patel", status: "Absent" },
  { id: "att-b15-4", date: "2026-10-24", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1004", studentName: "Elena Rostova", status: "Present" },
  { id: "att-b15-5", date: "2026-10-24", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1005", studentName: "Marcus Johnson", status: "Present" },
  { id: "att-b15-6", date: "2026-10-24", classId: "biology-10", className: "Biology · Cell structures", studentId: "STU-1006", studentName: "Priya Sharma", status: "Present" },

  // Mathematics records for STU-1001 (16 classes: 10 Present, 5 Absent, 1 Late -> 62.5% deficit case)
  { id: "att-m16", date: "2026-10-23", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m15", date: "2026-10-20", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-m14", date: "2026-10-18", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m13", date: "2026-10-15", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m12", date: "2026-10-13", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-m11", date: "2026-10-11", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m10", date: "2026-10-09", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Late" },
  { id: "att-m09", date: "2026-10-06", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-m08", date: "2026-10-04", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m07", date: "2026-10-02", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m06", date: "2026-09-29", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-m05", date: "2026-09-27", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m04", date: "2026-09-25", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m03", date: "2026-09-22", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-m02", date: "2026-09-20", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-m01", date: "2026-09-18", classId: "math-10", className: "Mathematics · Algebra", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },

  // History records for STU-1001 (12 classes: 9 Present, 2 Absent, 1 Late -> 75.0% exact boundary)
  { id: "att-h12", date: "2026-10-24", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h11", date: "2026-10-21", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h10", date: "2026-10-18", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-h09", date: "2026-10-14", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h08", date: "2026-10-13", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h07", date: "2026-10-09", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h06", date: "2026-10-07", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Late" },
  { id: "att-h05", date: "2026-10-04", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h04", date: "2026-10-02", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h03", date: "2026-09-30", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Absent" },
  { id: "att-h02", date: "2026-09-28", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
  { id: "att-h01", date: "2026-09-25", classId: "history-10", className: "World History · 1900s", studentId: "STU-1001", studentName: "Alex Morgan", status: "Present" },
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
export async function getClassRosterAttendance(classId, date) {
  const targetClass = classes.find((c) => c.id === classId || c.name === classId) || classes[0];
  const actualClassId = targetClass ? targetClass.id : classId;
  const enrolled = enrolledStudentsByClass[actualClassId] || [];
  const records = attendanceRecords.filter((r) => (r.classId === actualClassId || r.className === targetClass?.name) && (!date || r.date === date));
  return {
    className: targetClass ? targetClass.name : classId,
    students: copy(enrolled),
    records: copy(records),
    preview: true,
  };
}
export async function saveClassAttendance(classId, date, records) {
  const targetClass = classes.find((c) => c.id === classId || c.name === classId);
  const actualClassId = targetClass ? targetClass.id : classId;
  const className = targetClass ? targetClass.name : classId;

  for (const item of records) {
    const existingIndex = attendanceRecords.findIndex(
      (r) => (r.classId === actualClassId || r.className === className) && r.studentId === item.studentId && r.date === date
    );
    if (existingIndex >= 0) {
      attendanceRecords[existingIndex] = {
        ...attendanceRecords[existingIndex],
        status: item.status,
        studentName: item.studentName || attendanceRecords[existingIndex].studentName,
      };
    } else {
      attendanceRecords.unshift({
        id: `att-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        classId: actualClassId,
        className,
        date,
        studentId: item.studentId,
        studentName: item.studentName || item.studentId,
        status: item.status,
      });
    }
  }

  const updatedRecords = attendanceRecords.filter(
    (r) => (r.classId === actualClassId || r.className === className) && r.date === date
  );
  return {
    records: copy(updatedRecords),
    savedAt: new Date().toISOString(),
    preview: true,
    localOnly: true,
  };
}
export async function listCalendarEvents() { return copy(events); }