// FRONTEND PREVIEW ONLY. Messages and read states stay in this browser session.
let messages = [
  { id: "msg1", author: "Ms. Rivera", text: "Reminder: bring your cell model notes to class tomorrow.", time: "09:12", mine: false },
  { id: "msg2", author: "Alex Morgan", text: "Should we include the mitochondria in the diagram?", time: "09:18", mine: true },
  { id: "msg3", author: "Ms. Rivera", text: "Yes, and add a short note about its role.", time: "09:20", mine: false },
];
let notifications = [
  { id: "n1", title: "Assignment due soon", body: "Cell structures concept map is due Wednesday.", category: "Assignments", href: "/app/assignments/cell-notes", unread: true },
  { id: "n2", title: "Class announcement", body: "Room 204 is confirmed for Biology tomorrow.", category: "Classes", href: "/app/announcements", unread: true },
  { id: "n3", title: "Feedback is ready", body: "Your Algebra practice has been reviewed.", category: "Assignments", href: "/app/assignments/algebra-practice", unread: false },
];
const announcements = [
  { id: "an1", title: "Biology room confirmed", className: "Biology · Cell structures", author: "Ms. Rivera", date: "Today · 08:45", body: "Our class will meet in Room 204 this week. Please bring your notes from the cell structures lesson." },
  { id: "an2", title: "Study group on Friday", className: "Mathematics · Algebra", author: "Mr. Chen", date: "Yesterday · 15:10", body: "There will be an optional study group in the library on Friday at 13:00. Bring any questions from the practice set." },
];

export async function listMessages() { return messages.map((item) => ({ ...item, preview: true })); }
export async function sendLocalMessage(text) {
  const item = { id: `msg-${Date.now()}`, author: "You", text, time: new Intl.DateTimeFormat("en", { hour: "2-digit", minute: "2-digit" }).format(new Date()), mine: true };
  messages = [...messages, item];
  return { ...item, preview: true, localOnly: true };
}
export async function listAnnouncements() { return announcements.map((item) => ({ ...item, preview: true })); }
export async function listNotifications() { return notifications.map((item) => ({ ...item, preview: true })); }
export async function markNotificationRead(id) {
  notifications = notifications.map((item) => item.id === id ? { ...item, unread: false } : item);
  return listNotifications();
}
export async function markAllNotificationsRead() {
  notifications = notifications.map((item) => ({ ...item, unread: false }));
  return listNotifications();
}