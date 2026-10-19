import { useEffect, useMemo, useState } from "react";
import { Link, Navigate, NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  ArrowRight, ArrowUpRight, Bell, BookMarked, BookOpen, Bot,
  CalendarDays, Check, ChevronLeft, ChevronRight, CircleHelp,
  ClipboardCheck, FileText, GraduationCap, LayoutDashboard, LogOut, Menu,
  MessageCircle, Plus, Search, Settings, ShieldAlert, Sparkles, Users, Video,
  X,
} from "lucide-react";
import {
  addMaterial, askMentor, checkMessage, createAssignment, createClass,
  generateQuiz, getAssignment, getSession, joinClass,
  listAnnouncements, listAssignments, listAttendance, listCalendarEvents,
  listClasses, listMaterials, listMessages, listNotifications, loginAccount,
  logoutAccount, markAllNotificationsRead, markNotificationRead, registerAccount,
  saveAttendance, sendLocalMessage, submitAssignment,
} from "../services/index.js";
import ThemeToggle from "./ThemeToggle.jsx";
import LanguageSelector from "../i18n/LanguageSelector.jsx";
import { useLanguage, useLocalizedDate, useLocalizedNumber } from "../i18n/useLanguage.js";
import "./Workspace.css";
import LocalizedText from "../i18n/LocalizedText.jsx";

const studentNavigation = [
  { label: "Overview", path: "/dashboard", icon: LayoutDashboard },
  { label: "My classes", path: "/classes", icon: GraduationCap },
  { label: "My assignments", path: "/assignments", icon: ClipboardCheck },
  { label: "Learning materials", path: "/materials", icon: BookOpen },
  { label: "My attendance", path: "/attendance", icon: Check },
  { label: "Timetable", path: "/timetable", icon: CalendarDays },
  { label: "Calendar", path: "/calendar", icon: CalendarDays },
  { label: "Chat", path: "/chat", icon: MessageCircle },
  { label: "Announcements", path: "/announcements", icon: BookMarked },
  { label: "Notifications", path: "/notifications", icon: Bell },
  { label: "AI Mentor", path: "/mentor", icon: Bot },
  { label: "Practice quizzes", path: "/quizzes", icon: FileText },
];

const teacherNavigation = [
  { label: "Overview", path: "/dashboard", icon: LayoutDashboard },
  { label: "Manage classes", path: "/classes", icon: GraduationCap },
  { label: "Assignments & reviews", path: "/assignments", icon: ClipboardCheck },
  { label: "Learning materials", path: "/materials", icon: BookOpen },
  { label: "Take attendance", path: "/attendance", icon: Check },
  { label: "Teaching timetable", path: "/timetable", icon: CalendarDays },
  { label: "Academic calendar", path: "/calendar", icon: CalendarDays },
  { label: "Chat", path: "/chat", icon: MessageCircle },
  { label: "Announcements", path: "/announcements", icon: BookMarked },
  { label: "Notifications", path: "/notifications", icon: Bell },
  { label: "Quiz Generator", path: "/quizzes", icon: FileText },
];

const fixedContentIds = new Set([
  "biology-10", "math-10", "history-10", "cell-notes", "algebra-practice", "history-source",
  "m1", "m2", "m3", "m4", "a1", "a2", "a3", "a4", "e1", "e2", "e3", "e4",
  "n1", "n2", "n3", "an1", "an2", "msg1", "msg2", "msg3",
]);

function localizedRecord(t, id, value) {
  return fixedContentIds.has(id) ? t(value) : value;
}

function localizedStatus(t, status) {
  const labels = {
    pending: "Pending",
    submitted: "Submitted",
    late: "Late",
    reviewed: "Reviewed",
    present: "Present",
    absent: "Absent",
    graded: "Graded",
  };
  return t(labels[String(status || "").toLowerCase()] || String(status || ""));
}

const titleForPath = (path) => {
  if (path.includes("classroom")) return "Virtual classroom";
  if (path.includes("classes/create")) return "Create a class";
  if (path.includes("classes/join")) return "Join a class";
  if (path.includes("classes/")) return "Class details";
  if (path.includes("assignments/create")) return "Create assignment";
  if (path.includes("assignments/")) return "Assignment details";
  const routeTitles = {
    dashboard: "Overview", classes: "Classes", assignments: "Assignments",
    materials: "Learning materials", attendance: "Attendance", timetable: "Timetable",
    calendar: "Academic calendar", chat: "Class chat", announcements: "Announcements",
    notifications: "Notifications", mentor: "AI Mentor", quizzes: "Quiz Generator",
    profile: "Your profile", settings: "Settings",
  };
  return routeTitles[path.split("/").filter(Boolean).at(-1)] || "Overview";
};

function LocalNotice({ children = "Changes are stored only in this browser." }) {
  const { t } = useLanguage();
  return <div className="local-notice"><Sparkles size={15} /><span>{typeof children === "string" ? t(children) : children}</span></div>;
}

function PreviewNotice({ children }) {
  return <LocalNotice>{children}</LocalNotice>;
}

function AuthHeader() {
  const { t } = useLanguage();
  return <div className="auth-topline"><Link className="auth-brand" to="/" aria-label={t("Unified Learn home")}><span className="brand-mark"><GraduationCap size={23} /></span><span>{<LocalizedText text={"Unified"} />}<strong>{<LocalizedText text={"Learn"} />}</strong></span></Link><div className="auth-header-controls"><LanguageSelector /><ThemeToggle /></div></div>;
}

function PageHeading({ eyebrow = "UNIFIED LEARN", title, subtitle, action }) {
  const { t } = useLanguage();
  const location = useLocation();
  const routeParts = location.pathname.split("/").filter(Boolean);
  const recordId = routeParts.at(-1);
  const detailPage = ["classes", "assignments"].includes(routeParts.at(-2));
  const preserveUserContent = detailPage && !fixedContentIds.has(recordId);
  const translateHeading = (value) => preserveUserContent ? value : t(value);
  return <div className="page-heading"><div><span className="page-eyebrow">{translateHeading(eyebrow)}</span><h1>{translateHeading(title)}</h1>{subtitle && <p>{translateHeading(subtitle)}</p>}</div>{action}</div>;
}

function EmptyState({ icon: Icon = CircleHelp, title, description, action }) {
  const { t } = useLanguage();
  return <div className="empty-state"><span><Icon size={22} /></span><strong>{t(title)}</strong><p>{t(description)}</p>{action}</div>;
}

export function AuthPage({ mode }) {
  const { t } = useLanguage();
  const location = useLocation();
  const navigate = useNavigate();
  const role = location.pathname.startsWith("/teacher/") ? "teacher" : "student";
  const [name, setName] = useState("");
  const [accountId, setAccountId] = useState("");
  const [accessCode, setAccessCode] = useState("");
  const [recoveryEmail, setRecoveryEmail] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const heading = mode === "register" ? t("Make learning yours.") : mode === "forgot" ? t("A fresh start.") : t(role === "student" ? "Welcome to the student portal." : "Welcome to the teacher portal.");

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setMessage("");
    if (mode === "forgot") {
      setMessage(t("Password recovery is not connected yet. No email was sent."));
      return;
    }
    if (mode === "register" && !name.trim()) {
      setError(t("Add a display name to continue."));
      return;
    }
    setLoading(true);
    try {
      const session = mode === "register"
        ? await registerAccount({ role, name })
        : await loginAccount({ role, accountId, accessCode });
      navigate(`/app/${session.user.role}/dashboard`);
    } catch (cause) {
      setError(t(cause.message));
    } finally {
      setLoading(false);
    }
  }

  return <main className="auth-page">
    <AuthHeader />
    <div className="auth-layout">
      <section className="auth-story"><span className="section-kicker">{t(mode === "forgot" ? "UNIFIED LEARN" : role === "student" ? "STUDENT PORTAL" : "TEACHER PORTAL")}</span><h1>{heading}</h1><p>{t("Classes, learning resources, and helpful next steps, all in one connected space.")}</p><div className="auth-story-art"><div><BookOpen size={23} /><span>{t("Everything you need")}<br />{t("for your next step")}</span></div><span className="auth-art-star">{<LocalizedText text={"✳"} />}</span><span className="auth-art-line" /></div></section>
      <section className="auth-form-wrap"><div className="auth-form-heading"><span className="page-eyebrow">{t("ACCOUNT ACCESS")}</span><h2>{mode === "forgot" ? t("Reset your password") : mode === "register" ? t(role === "student" ? "Create a student profile" : "Create a teacher profile") : t(role === "student" ? "Student sign in" : "Teacher sign in")}</h2><p>{mode === "forgot" ? t("Try the recovery form; no email will be sent.") : mode === "register" ? t("Profile setup is stored locally and does not create an online account.") : t(role === "student" ? "Sign in to the student portal with the account ID assigned to you." : "Sign in to the teacher portal with the account ID assigned to you.")}</p></div>
        {mode !== "forgot" ? <form onSubmit={handleSubmit} className="form-stack">
          {mode === "register" ? <label>{t("Display name")}<input required value={name} onChange={(event) => setName(event.target.value)} placeholder={t("How should we address you?")} /></label> : <>
            <label>{t(role === "student" ? "Student ID" : "Teacher ID")}<input required value={accountId} onChange={(event) => setAccountId(event.target.value)} placeholder={role === "student" ? t("STU-1001") : t("TCH-2001")} autoComplete="username" /></label>
            <label>{t("Access code")}<input required type="password" value={accessCode} onChange={(event) => setAccessCode(event.target.value)} placeholder={t("Enter your access code")} autoComplete="current-password" /></label>
          </>}
          {error && <p className="form-error" role="alert">{error}</p>}
          <LocalNotice>{mode === "register" ? t("Profile setup is local to this browser; no online account is created.") : t("Account ID: {{id}} · Access code: {{code}}", { id: role === "student" ? "STU-1001" : "TCH-2001", code: "learn2026" })}</LocalNotice>
          <button className="workspace-button primary-action" type="submit" disabled={loading}>{loading ? t("Opening your space…") : mode === "register" ? t("Create profile") : t(role === "student" ? "Sign in as student" : "Sign in as teacher")}<ArrowRight size={16} /></button>
        </form> : <form onSubmit={handleSubmit} className="form-stack"><label>{t("Email")}<input required type="email" value={recoveryEmail} onChange={(event) => setRecoveryEmail(event.target.value)} placeholder={t("you@example.com")} /></label><button className="workspace-button primary-action" type="submit">{t("Request reset link")} <ArrowRight size={16} /></button>{message && <p className="form-success" role="status">{message}</p>}</form>}
        {mode !== "forgot" && message && <p className="form-success" role="status">{message}</p>}
        {mode !== "forgot" && <div className="auth-links">{mode === "login" && <Link to="/forgot-password">{t("Forgot password?")}</Link>}<span>{t(mode === "register" ? "Already have a profile?" : "Need a profile?")} <Link to={`/${role}/${mode === "register" ? "login" : "register"}`}>{t(mode === "register" ? role === "student" ? "Student sign in" : "Teacher sign in" : role === "student" ? "Register as student" : "Register as teacher")}</Link></span></div>}
        {mode === "forgot" && <div className="auth-links"><Link to="/student/login">{t("Student sign in")}</Link><Link to="/teacher/login">{t("Teacher sign in")}</Link></div>}
      </section>
    </div>
    <span className="auth-footnote">{t("A frontend prototype · Authentication is simulated")}</span>
  </main>;
}

export function PortalPage({ mode }) {
  const { t } = useLanguage();
  const location = useLocation();
  const isRegister = mode === "register";
  return <main className="auth-page">
    <AuthHeader />
    <div className="auth-layout">
      <section className="auth-story"><span className="section-kicker">{t("LEARN. GROW. ACHIEVE.")}</span><h1>{t(isRegister ? "Choose your learning space." : "Welcome back.")}</h1><p>{t(isRegister ? "Start with the portal that matches your role." : "Choose your portal to sign in with your account ID.")}</p><div className="auth-story-art"><div><BookOpen size={23} /><span>{t("One connected space")}<br />{t("for learning and teaching")}</span></div><span className="auth-art-star">{<LocalizedText text={"✳"} />}</span><span className="auth-art-line" /></div></section>
      <section className="auth-form-wrap"><div className="auth-form-heading"><span className="page-eyebrow">{t("ACCOUNT ACCESS")}</span><h2>{t(isRegister ? "Choose a profile type" : "Choose your portal")}</h2><p>{t(isRegister ? "Choose the account type for your local profile." : "Student and teacher accounts sign in separately.")}</p></div>
        {location.state?.accessMessageKey && <p className="form-error" role="alert">{t(location.state.accessMessageKey, location.state.values)}</p>}
        <div className="portal-options">
          <Link className="portal-option student-option" to={isRegister ? "/student/register" : "/student/login"}><span className="role-icon"><BookOpen size={18} /></span><span><strong>{t(isRegister ? "Student registration" : "Student sign in")}</strong><small>{t(isRegister ? "Create a student profile" : "Sign in with a student ID")}</small></span><ArrowRight size={16} /></Link>
          <Link className="portal-option teacher-option" to={isRegister ? "/teacher/register" : "/teacher/login"}><span className="role-icon"><GraduationCap size={18} /></span><span><strong>{t(isRegister ? "Teacher registration" : "Teacher sign in")}</strong><small>{t(isRegister ? "Create a teacher profile" : "Sign in with a teacher ID")}</small></span><ArrowRight size={16} /></Link>
        </div>
        <div className="auth-links"><Link to={isRegister ? "/login" : "/register"}>{t(isRegister ? "Already exploring? Choose a login portal" : "New to Unified Learn? Choose a registration portal")}</Link></div>
      </section>
    </div>
    <span className="auth-footnote">{t("A frontend prototype · Authentication is simulated")}</span>
  </main>;
}

export function LogoutPage() {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const [done, setDone] = useState(false);
  async function handleLogout() { await logoutAccount(); setDone(true); }
  return <main className="logout-page"><AuthHeader /><section><span className="logout-icon"><LogOut size={23} /></span><h1>{done ? t("You have signed out") : t("Sign out?")}</h1><p>{done ? t("Your local account session has been cleared.") : t("This clears the account session stored in this browser.")}</p>{done ? <Link className="workspace-button primary-action" to="/login">{<LocalizedText text={"Return to portal selection"} />}<ArrowRight size={16} /></Link> : <div className="logout-actions"><button className="workspace-button primary-action" onClick={handleLogout}>{<LocalizedText text={"Sign out"} />}<LogOut size={16} /></button><button className="workspace-button" onClick={() => navigate(-1)}>{<LocalizedText text={"Stay here"} />}</button></div>}</section></main>;
}

export function Workspace() {
  const { t } = useLanguage();
  const location = useLocation();
  const navigate = useNavigate();
  const [session, setSession] = useState(undefined);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [dataLoaded, setDataLoaded] = useState(false);
  const [data, setData] = useState({ classes: [], assignments: [], materials: [], attendance: [], events: [], announcements: [], messages: [], notifications: [] });
  const [notice, setNotice] = useState("");

  useEffect(() => {
    let active = true;
    getSession().then(async (value) => {
      if (!active) return;
      setSession(value);
      if (!value) return;
      const [classes, assignments, materials, attendance, events, announcements, messages, notifications] = await Promise.all([
        listClasses(), listAssignments(), listMaterials(), listAttendance(), listCalendarEvents(), listAnnouncements(), listMessages(), listNotifications(),
      ]);
      if (active) {
        setData({ classes, assignments, materials, attendance, events, announcements, messages, notifications });
        setDataLoaded(true);
      }
    });
    return () => { active = false; };
  }, []);

  const user = session?.user;
  const rolePath = user ? `/app/${user.role}` : "";
  const portalMatch = location.pathname.match(/^\/app\/(student|teacher)(?=\/|$)/);
  const title = t(titleForPath(location.pathname));
  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return data;
    return Object.fromEntries(Object.entries(data).map(([key, items]) => [key, items.filter((item) => Object.values(item).some((value) => String(value).toLowerCase().includes(needle)))]));
  }, [data, query]);

  const visibleNotice = location.state?.accessMessageKey ? t(location.state.accessMessageKey, location.state.values) : notice;

  function dismissNotice() {
    setNotice("");
    if (location.state?.accessMessage) navigate(location.pathname, { replace: true, state: null });
  }

  if (session === undefined) return <div className="workspace-loading"><span className="loading-mark"><GraduationCap size={21} /></span><p>{<LocalizedText text={"Opening your learning space…"} />}</p></div>;
  if (!session) return <Navigate to="/login" replace state={{ accessMessageKey: "Sign in with a student or teacher account to continue." }} />;
  if (portalMatch && portalMatch[1] !== user.role) {
    return <Navigate to={`${rolePath}/dashboard`} replace state={{ accessMessageKey: "This {{role}} space is unavailable to your {{userRole}} account. Sign out and use a separate {{role}} account to access it.", values: { role: t(portalMatch[1] === "student" ? "Student" : "Teacher").toLowerCase(), userRole: t(user.role === "student" ? "Student" : "Teacher").toLowerCase() } }} />;
  }
  if (!portalMatch) {
    const requestedPath = location.pathname.slice("/app".length) || "/dashboard";
    return <Navigate to={`${rolePath}${requestedPath}`} replace />;
  }

  const workspacePath = `/app${location.pathname.slice(rolePath.length)}`;

  return <div className="workspace-shell">
    {mobileOpen && <button className="workspace-scrim" aria-label={t("Close navigation menu")} onClick={() => setMobileOpen(false)} />}
    <aside className={`workspace-sidebar ${mobileOpen ? "sidebar-open" : ""}`}>
      <Link className="workspace-brand" to={`${rolePath}/dashboard`}><span className="brand-mark"><GraduationCap size={21} /></span><span>{<LocalizedText text={"Unified"} />}<strong>{<LocalizedText text={"Learn"} />}</strong></span></Link>
      <div className="sidebar-role" aria-label={t("{{role}} account", { role: t(user.role === "student" ? "Student" : "Teacher").toLowerCase() })}><span className={`role-avatar ${user.role}`}>{user.role === "teacher" ? t("J") : t("A")}</span><span><strong>{user.name}</strong><small>{t("{{role}} account · {{id}}", { role: t(user.role === "student" ? "Student" : "Teacher"), id: user.id })}</small></span></div>
<span className="sidebar-label">
  {t(user.role === "student" ? "STUDENT TOOLS" : "TEACHER TOOLS")}
</span>

<nav
  className="workspace-nav"
  aria-label={t(
    user.role === "student"
      ? "Student navigation"
      : "Teacher navigation"
  )}
>
  {(user.role === "teacher"
    ? teacherNavigation
    : studentNavigation
  ).map(({ label, path, icon: Icon }) => (
    <NavLink
      key={path}
      to={`${rolePath}${path}`}
      onClick={() => setMobileOpen(false)}
      className={({ isActive }) =>
        `workspace-nav-link${isActive ? " active" : ""}`
      }
    >
      <Icon size={17} />
      <span>{t(label)}</span>

      {label === "Notifications" &&
        data.notifications.some((item) => item.unread) && <i />}
    </NavLink>
  ))}
</nav>
      <div className="sidebar-bottom"><Link to="/app/profile"><Users size={17} /> {t("Profile")}</Link><Link to="/app/settings"><Settings size={17} /> {t("Settings")}</Link><Link to="/logout"><LogOut size={17} /> {t("Sign out")}</Link></div>
    </aside>
    <div className="workspace-main">
      <header className="workspace-topbar">
        <button className="workspace-menu-button" aria-label={t("Open navigation")} onClick={() => setMobileOpen(true)}><Menu size={20} /></button>
        <div className="workspace-breadcrumb"><Link to={`${rolePath}/dashboard`}>{t("Workspace")}</Link><ChevronRight size={14} /><span>{title}</span></div>
        <label className="workspace-search"><Search size={16} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder={t("Search your learning space")} aria-label={t("Search learning content")} />{query && <button type="button" aria-label={t("Clear search")} onClick={() => setQuery("")}><X size={14} /></button>}</label>
        <LanguageSelector />
        <ThemeToggle compact />
        <Link to="/app/notifications" className="topbar-icon" aria-label={t("Notifications")}><Bell size={18} />{data.notifications.some((item) => item.unread) && <i />}</Link>
        <Link className="topbar-profile" to="/app/profile"><span className={`role-avatar ${user.role}`}>{user.role === "teacher" ? t("J") : t("A")}</span><span>{user.name.split(" ")[0]}</span></Link>
      </header>
      <main className="workspace-content">
        <LocalNotice />
        {visibleNotice && <div className="workspace-toast" role="status"><Check size={16} />{visibleNotice}<button aria-label={t("Dismiss")} onClick={dismissNotice}><X size={14} /></button></div>}
        {dataLoaded ? <WorkspacePage path={workspacePath} user={user} data={filtered} allData={data} setData={setData} setNotice={setNotice} query={query} /> : <div className="page-loading" role="status">{<LocalizedText text={"Loading learning records…"} />}</div>}
      </main>
      <footer className="workspace-footer"><span>{<LocalizedText text={"Unified Learn"} />}</span><span>{t("Changes are stored only in this browser.")}</span></footer>
    </div>
  </div>;
}

function WorkspacePage({ path, user, data, allData, setData, setNotice, query }) {
  if (path.endsWith("/dashboard")) return <Dashboard user={user} data={data} />;
  if (path.endsWith("/classes/create")) return <ClassForm />;
  if (path.endsWith("/classes/join")) return <JoinClass />;
  if (path.includes("/classroom/")) return <Classroom />;
  if (path.includes("/classes/")) return <ClassDetail path={path} classes={data.classes} />;
  if (path.endsWith("/classes")) return <ClassesPage classes={data.classes} query={query} />;
  if (path.endsWith("/assignments/create")) return <AssignmentForm />;
  if (path.includes("/assignments/")) return <AssignmentDetail path={path} assignments={data.assignments} />;
  if (path.endsWith("/assignments")) return <AssignmentsPage assignments={data.assignments} user={user} />;
  if (path.endsWith("/materials")) return <MaterialsPage materials={data.materials} />;
  if (path.endsWith("/attendance")) return <AttendancePage records={data.attendance} role={user.role} setNotice={setNotice} />;
  if (path.endsWith("/timetable")) return <SchedulePage events={data.events} mode="week" />;
  if (path.endsWith("/calendar")) return <SchedulePage events={data.events} mode="month" />;
  if (path.endsWith("/chat")) return <ChatPage initialMessages={data.messages} setNotice={setNotice} />;
  if (path.endsWith("/announcements")) return <AnnouncementsPage announcements={data.announcements} />;
  if (path.endsWith("/notifications")) return <NotificationsPage items={data.notifications} setData={setData} allData={allData} />;
  if (path.endsWith("/mentor")) return <MentorPage />;
  if (path.endsWith("/quizzes")) return <QuizPage />;
  if (path.endsWith("/profile")) return <ProfilePage user={user} />;
  if (path.endsWith("/settings")) return <SettingsPage />;
  return <Navigate to="/app/dashboard" replace />;
}

function Dashboard({ user, data }) {
  return user.role === "teacher"
    ? <TeacherDashboard user={user} data={data} />
    : <StudentDashboard user={user} data={data} />;
}

function StudentDashboard({ user, data }) {
  const { t } = useLanguage();
  const formatDate = useLocalizedDate();
  const base = "/app/student";
  const firstName = user.name.split(" ")[0];

  const upcomingClasses = data.events
    .filter((item) => item.type === "Class")
    .slice(0, 3);

  const pendingAssignments = data.assignments.filter(
    (item) => ["pending", "late"].includes(item.status)
  );

  const presentCount = data.attendance.filter(
    (item) => (item.status || "").toLowerCase() === "present"
  ).length;

  const attendanceRate = data.attendance.length
    ? `${Math.round((presentCount / data.attendance.length) * 100)}%`
    : "—";

  return (
    <div className="role-dashboard student-dashboard">
      <PageHeading
        eyebrow="YOUR LEARNING SPACE"
        title={t("Good morning, {{name}}.", { name: firstName })}
        subtitle={t("Here’s your day, at a glance.")}
        action={
          <Link to={`${base}/timetable`} className="workspace-button">
            <CalendarDays size={16} />
            {t("View calendar")}
          </Link>
        }
      />

      <section className="workspace-panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">
              {t("YOUR LEARNING JOURNEY")}
            </span>
            <h2>{t("Make learning your own")}</h2>
          </div>
          <BookOpen size={21} />
        </div>

        <p className="panel-body-copy">
          {t("Keep your classes, assignments, study resources, and learning support close at hand.")}
        </p>

        <div className="heading-actions">
          <Link
            to={`${base}/classes/join`}
            className="workspace-button primary-action"
          >
            <Plus size={16} />
            {t("Join a class")}
          </Link>

          <Link
            to={`${base}/mentor`}
            className="workspace-button"
          >
            <Bot size={16} />
            {t("AI Mentor")}
          </Link>
        </div>
      </section>

      <div className="overview-strip">
        <div>
          <span>{t("My classes")}</span>
          <strong>{data.classes.length}</strong>
          <small>{t("Ready for your week")}</small>
        </div>

        <div>
          <span>{t("Upcoming assignments")}</span>
          <strong>{pendingAssignments.length}</strong>
          <small>{t("To do")}</small>
        </div>

        <div>
          <span>{t("Attendance")}</span>
          <strong>{attendanceRate}</strong>
          <small>{t("This term")}</small>
        </div>
      </div>

      <div className="dashboard-grid">
        <section className="dashboard-main">
          <section className="workspace-panel">
            <div className="panel-heading">
              <div>
                <span className="panel-kicker">{t("UP NEXT")}</span>
                <h2>{t("Classes this week")}</h2>
              </div>
              <Link to={`${base}/timetable`}>
                {t("View calendar")} <ArrowRight size={15} />
              </Link>
            </div>

            {upcomingClasses.length ? (
              <div className="event-list">
                {upcomingClasses.map((event) => {
                  const matchingClass = data.classes.find(
                    (item) => item.name === event.title
                  );

                  return (
                    <div className="event-row" key={event.id}>
                      <span className="event-time">{event.time}</span>
                      <span className="event-mark" />

                      <span className="event-copy">
                        <strong>
                          {localizedRecord(t, event.id, event.title)}
                        </strong>
                        <small>
                          {localizedRecord(t, event.id, event.location)}
                          {" · "}
                          {formatDate(event.date, {
                            day: "numeric",
                            month: "short",
                          })}
                        </small>
                      </span>

                      <Link
                        to={
                          matchingClass
                            ? `${base}/classes/${matchingClass.id}`
                            : `${base}/timetable`
                        }
                        aria-label={t("Open {{title}}", {
                          title: event.title,
                        })}
                      >
                        <ArrowUpRight size={16} />
                      </Link>
                    </div>
                  );
                })}
              </div>
            ) : (
              <EmptyState
                title="No upcoming classes"
                description="Your next class will appear here."
              />
            )}
          </section>

          <section className="workspace-panel">
            <div className="panel-heading">
              <div>
                <span className="panel-kicker">{t("KEEP MOVING")}</span>
                <h2>{t("Assignments")}</h2>
              </div>
              <Link to={`${base}/assignments`}>
                {t("See all")} <ArrowRight size={15} />
              </Link>
            </div>

            {pendingAssignments.length ? (
              <div className="simple-list">
                {pendingAssignments.slice(0, 4).map((item) => (
                  <Link
                    to={`${base}/assignments/${item.id}`}
                    className="simple-row"
                    key={item.id}
                  >
                    <span className={`list-icon ${item.status}`}>
                      <ClipboardCheck size={17} />
                    </span>

                    <span>
                      <strong>
                        {localizedRecord(t, item.id, item.title)}
                      </strong>
                      <small>
                        {localizedRecord(t, item.id, item.subject)}
                        {" · "}
                        {t("Due {{date}}", {
                          date: formatDate(item.dueDate, {
                            day: "numeric",
                            month: "short",
                          }),
                        })}
                      </small>
                    </span>

                    <span className={`status-pill ${item.status}`}>
                      {t(item.status)}
                    </span>
                  </Link>
                ))}
              </div>
            ) : (
              <EmptyState
                title="All caught up"
                description="You have no pending assignments."
              />
            )}
          </section>
        </section>

        <aside className="dashboard-aside">
          <section className="progress-panel">
            <span className="panel-kicker">{t("YOUR PROGRESS")}</span>

            <div className="progress-ring">
              <strong>
                {attendanceRate.replace("%", "")}
                <small>%</small>
              </strong>
            </div>

            <h3>{t("Steady progress")}</h3>
            <p>{t("You’re building a strong weekly rhythm. Keep it up.")}</p>

            <Link to={`${base}/attendance`}>
              {t("View attendance")} <ArrowRight size={15} />
            </Link>
          </section>

          <section className="announcement-mini">
            <div className="panel-heading">
              <h2>{t("Class updates")}</h2>
              <Link to={`${base}/announcements`}>
                <ArrowUpRight size={16} />
              </Link>
            </div>

            {data.announcements.slice(0, 3).map((item) => (
              <Link
                className="announcement-mini-row"
                to={`${base}/announcements`}
                key={item.id}
              >
                <strong>
                  {localizedRecord(t, item.id, item.title)}
                </strong>
                <small>
                  {localizedRecord(t, item.id, item.className)}
                </small>
              </Link>
            ))}
          </section>

          <Link to={`${base}/quizzes`} className="mentor-shortcut">
            <span><FileText size={19} /></span>
            <strong>{t("Practice quizzes")}</strong>
            <small>{t("Check your understanding")}</small>
            <ArrowRight size={16} />
          </Link>
        </aside>
      </div>
    </div>
  );
}

function TeacherDashboard({ user, data }) {
  const { t } = useLanguage();
  const formatDate = useLocalizedDate();
  const base = "/app/teacher";
  const firstName = user.name.split(" ")[0];

  const upcomingClasses = data.events
    .filter((item) => item.type === "Class")
    .slice(0, 3);

  const reviewQueue = data.assignments.filter(
    (item) => ["submitted", "late"].includes(item.status)
  );

  const learnerCount = data.classes.reduce(
    (total, item) => total + (Number(item.students) || 0),
    0
  );

  return (
    <div className="role-dashboard teacher-dashboard">
      <PageHeading
        eyebrow="TEACHER SPACE"
        title={t("Good morning, {{name}}.", { name: firstName })}
        subtitle={t("Your classes and follow-ups are ready.")}
        action={
          <Link
            to={`${base}/assignments`}
            className="workspace-button primary-action"
          >
            <ClipboardCheck size={16} />
            {t("Recent submissions")}
          </Link>
        }
      />

      <section className="workspace-panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">{t("TEACHER SPACE")}</span>
            <h2>{t("Your teaching desk")}</h2>
          </div>
          <GraduationCap size={21} />
        </div>

        <p className="panel-body-copy">
          {t("Prepare lessons, organize classes, review work, and keep students informed.")}
        </p>

        <div className="heading-actions">
          <Link
            to={`${base}/classes/create`}
            className="workspace-button primary-action"
          >
            <Plus size={16} />
            {t("Create a class")}
          </Link>

          <Link
            to={`${base}/assignments/create`}
            className="workspace-button"
          >
            <ClipboardCheck size={16} />
            {t("Create assignment")}
          </Link>
        </div>
      </section>

      <div className="overview-strip">
        <div>
          <span>{t("Active classes")}</span>
          <strong>{data.classes.length}</strong>
          <small>{t("Ready for your week")}</small>
        </div>

        <div>
          <span>{t("Learners")}</span>
          <strong>{learnerCount}</strong>
          <small>{t("Across your classes")}</small>
        </div>

        <div>
          <span>{t("To review")}</span>
          <strong>{reviewQueue.length}</strong>
          <small>{t("Submissions waiting")}</small>
        </div>
      </div>

      <div className="dashboard-grid">
        <section className="dashboard-main">
          <section className="workspace-panel">
            <div className="panel-heading">
              <div>
                <span className="panel-kicker">{t("UP NEXT")}</span>
                <h2>{t("Classes this week")}</h2>
              </div>

              <Link to={`${base}/timetable`}>
                {t("View calendar")} <ArrowRight size={15} />
              </Link>
            </div>

            {upcomingClasses.length ? (
              <div className="event-list">
                {upcomingClasses.map((event) => {
                  const matchingClass = data.classes.find(
                    (item) => item.name === event.title
                  );

                  return (
                    <div className="event-row" key={event.id}>
                      <span className="event-time">{event.time}</span>
                      <span className="event-mark" />

                      <span className="event-copy">
                        <strong>
                          {localizedRecord(t, event.id, event.title)}
                        </strong>
                        <small>
                          {localizedRecord(t, event.id, event.location)}
                          {" · "}
                          {formatDate(event.date, {
                            day: "numeric",
                            month: "short",
                          })}
                        </small>
                      </span>

                      <Link
                        to={
                          matchingClass
                            ? `${base}/classes/${matchingClass.id}`
                            : `${base}/timetable`
                        }
                        aria-label={t("Open {{title}}", {
                          title: event.title,
                        })}
                      >
                        <ArrowUpRight size={16} />
                      </Link>
                    </div>
                  );
                })}
              </div>
            ) : (
              <EmptyState
                title="No upcoming classes"
                description="Your next class will appear here."
              />
            )}
          </section>

          <section className="workspace-panel">
            <div className="panel-heading">
              <div>
                <span className="panel-kicker">{t("KEEP MOVING")}</span>
                <h2>{t("Recent submissions")}</h2>
              </div>

              <Link to={`${base}/assignments`}>
                {t("See all")} <ArrowRight size={15} />
              </Link>
            </div>

            {reviewQueue.length ? (
              <div className="simple-list">
                {reviewQueue.slice(0, 4).map((item) => (
                  <Link
                    to={`${base}/assignments/${item.id}`}
                    className="simple-row"
                    key={item.id}
                  >
                    <span className={`list-icon ${item.status}`}>
                      <ClipboardCheck size={17} />
                    </span>

                    <span>
                      <strong>
                        {localizedRecord(t, item.id, item.title)}
                      </strong>
                      <small>
                        {localizedRecord(t, item.id, item.subject)}
                        {" · "}
                        {t(item.status)}
                      </small>
                    </span>

                    <ArrowUpRight size={16} />
                  </Link>
                ))}
              </div>
            ) : (
              <EmptyState
                title="Nothing to review"
                description="New submissions will appear here."
              />
            )}
          </section>
        </section>

        <aside className="dashboard-aside">
          <section className="announcement-mini">
            <div className="panel-heading">
              <h2>{t("Teaching actions")}</h2>
            </div>

            <div className="portal-options">
              <Link className="portal-option" to={`${base}/attendance`}>
                <span className="role-icon"><Check size={17} /></span>
                <span>
                  <strong>{t("Take attendance")}</strong>
                  <small>{t("Record class participation")}</small>
                </span>
                <ArrowUpRight size={15} />
              </Link>

              <Link className="portal-option" to={`${base}/materials`}>
                <span className="role-icon"><BookOpen size={17} /></span>
                <span>
                  <strong>{t("Learning materials")}</strong>
                  <small>{t("Share resources with students")}</small>
                </span>
                <ArrowUpRight size={15} />
              </Link>

              <Link className="portal-option" to={`${base}/announcements`}>
                <span className="role-icon"><MessageCircle size={17} /></span>
                <span>
                  <strong>{t("Announcements")}</strong>
                  <small>{t("Keep your class informed")}</small>
                </span>
                <ArrowUpRight size={15} />
              </Link>

              <Link className="portal-option" to={`${base}/quizzes`}>
                <span className="role-icon"><FileText size={17} /></span>
                <span>
                  <strong>{t("Quiz Generator")}</strong>
                  <small>{t("Prepare a quiz")}</small>
                </span>
                <ArrowUpRight size={15} />
              </Link>
            </div>
          </section>

          <section className="progress-panel">
            <span className="panel-kicker">{t("YOUR PROGRESS")}</span>
            <h3>{t("Teaching overview")}</h3>
            <p>{t("Your classes and follow-ups are ready.")}</p>
            <Link to={`${base}/classes`}>
              {t("Manage classes")} <ArrowRight size={15} />
            </Link>
          </section>
        </aside>
      </div>
    </div>
  );
}

function ClassesPage({ classes, query }) {
  const { t } = useLanguage();
  const [subject, setSubject] = useState("All classes");
  const subjects = ["All classes", ...new Set(classes.map((item) => item.subject))];
  const shown = classes.filter((item) => subject === "All classes" || item.subject === subject);
  return <><PageHeading title={t("Classes")} subtitle="Your learning spaces, in one place." action={<div className="heading-actions"><Link className="workspace-button" to="/app/classes/join"><Users size={16} /> {t("Join class")}</Link><Link className="workspace-button primary-action" to="/app/classes/create"><Plus size={16} /> {t("Create class")}</Link></div>} /><div className="filter-bar"><div className="filter-tabs">{subjects.map((item) => <button className={subject === item ? "active" : ""} key={item} onClick={() => setSubject(item)}>{t(item)}</button>)}</div><span>{t("{{count}} classes", { count: shown.length })}</span></div>{shown.length ? <div className="class-grid">{shown.map((item) => <article className="class-card" key={item.id}><div className={`class-card-cover ${item.color}`}><span>{item.subject.slice(0, 2).toUpperCase()}</span><small>{t("{{count}} learners", { count: item.students })}</small></div><div className="class-card-body"><span className="class-subject">{localizedRecord(t, item.id, item.subject)}</span><h2>{localizedRecord(t, item.id, item.name)}</h2><p>{item.teacher}{<LocalizedText text={"·"} />}{localizedRecord(t, item.id, item.room)}</p><div className="class-card-bottom"><span><CalendarDays size={14} />{localizedRecord(t, item.id, item.schedule)}</span><Link to={`/app/classes/${item.id}`} aria-label={t("Open {{title}}", { title: localizedRecord(t, item.id, item.name) })}><ArrowUpRight size={17} /></Link></div></div></article>)}</div> : <EmptyState icon={Search} title={t("No classes match")} description={query ? "Try another search." : "Create a class or join with a preview code."} action={<Link className="workspace-button" to="/app/classes/join">{t("Join a class")}</Link>} />}</>;
}

function ClassForm() {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const [error, setError] = useState("");
  async function submit(event) { event.preventDefault(); const form = new FormData(event.currentTarget); try { const item = await createClass({ name: form.get("name"), subject: form.get("subject"), teacher: "Jordan Rivera", room: form.get("room") || "Preview room", schedule: form.get("schedule") || "Schedule to be announced" }); navigate(`/app/classes/${item.id}`); } catch (cause) { setError(t(cause.message)); } }
  return <><PageHeading title={t("Create a class")} subtitle="Set up a learning space in this local preview." /><form className="workspace-form" onSubmit={submit}><label>{t("Class name")}<input name="name" required placeholder={t("e.g. Environmental Science")} /></label><label>{t("Subject")}<input name="subject" required placeholder={t("e.g. Science")} /></label><div className="form-row"><label>{t("Room or meeting location")}<input name="room" placeholder={t("Optional")} /></label><label>{t("Schedule")}<input name="schedule" placeholder={t("e.g. Tue · 10:30")} /></label></div><div className="meeting-preview"><Video size={19} /><span><strong>{t("Meeting link preview")}</strong><small>{t("A preview link will be shown in class details. No meeting service is connected.")}</small></span></div>{error && <p className="form-error">{error}</p>}<div className="form-actions"><Link className="workspace-button" to="/app/classes">{t("Cancel")}</Link><button className="workspace-button primary-action" type="submit">{t("Create preview class")} <ArrowRight size={16} /></button></div></form></>;
}

function JoinClass() {
  const { t } = useLanguage();
  const navigate = useNavigate(); const [code, setCode] = useState(""); const [error, setError] = useState("");
  async function submit(event) { event.preventDefault(); try { const item = await joinClass(code); navigate(`/app/classes/${item.id}`); } catch (cause) { setError(t(cause.message)); } }
  return <><PageHeading title={t("Join a class")} subtitle="Enter a sample code to preview a class space." /><form className="workspace-form narrow-form" onSubmit={submit}><label>{t("Class code")}<input required value={code} onChange={(event) => setCode(event.target.value)} placeholder={t("Try CELL24")} autoCapitalize="characters" /></label><p className="field-hint">{t("Preview codes: CELL24 · MATH28 · PAST21")}</p>{error && <p className="form-error" role="alert">{error}</p>}<div className="form-actions"><Link className="workspace-button" to="/app/classes">{t("Cancel")}</Link><button className="workspace-button primary-action" type="submit">{t("Preview class")} <ArrowRight size={16} /></button></div></form></>;
}

function ClassDetail({ path, classes }) {
  const { t } = useLanguage();
  const id = path.split("/").at(-1); const item = classes.find((entry) => entry.id === id);
  if (!item) return <EmptyState icon={GraduationCap} title={t("Class not found")} description="This class is not in the current preview set." action={<Link className="workspace-button" to="/app/classes">{<LocalizedText text={"Back to classes"} />}</Link>} />;
  return <><PageHeading eyebrow={localizedRecord(t, item.id, item.subject)} title={localizedRecord(t, item.id, item.name)} subtitle={`${item.teacher} · ${localizedRecord(t, item.id, item.room)} · ${localizedRecord(t, item.id, item.schedule)}`} action={<Link to={`/app/classroom/${item.id}`} className="workspace-button primary-action"><Video size={16} />{<LocalizedText text={"Open classroom"} />}</Link>} /><div className="detail-grid"><section className="workspace-panel"><div className="panel-heading"><div><span className="panel-kicker">{<LocalizedText text={"CLASS SPACE"} />}</span><h2>{<LocalizedText text={"Welcome to"} />}{localizedRecord(t, item.id, item.subject)}</h2></div><span className="preview-tag">{<LocalizedText text={"PREVIEW"} />}</span></div><p className="panel-body-copy">{<LocalizedText text={"Your class space brings sessions, resources, assignments, and updates together. These records are sample content for a frontend preview."} />}</p><div className="meeting-preview"><Video size={19} /><span><strong>{<LocalizedText text={"Meeting link preview"} />}</strong><small>{<LocalizedText text={"unified-learn.preview/class/"} />}{item.id}{<LocalizedText text={"· not a real meeting"} />}</small></span><button className="icon-button" aria-label={t("Copy preview meeting link")} onClick={() => navigator.clipboard?.writeText(`https://unified-learn.preview/class/${item.id}`)}> <ArrowUpRight size={16} /></button></div></section><section className="workspace-panel"><div className="panel-heading"><div><span className="panel-kicker">{<LocalizedText text={"CLASS MEMBERS"} />}</span><h2>{item.students}{<LocalizedText text={"learners"} />}</h2></div><Users size={17} /></div><div className="member-list">{["Alex Morgan", "Sam Rivera", "Taylor Kim", "Jamie Park"].map((name, index) => <div key={name}><span className={`member-avatar tone-${index}`}>{name.split(" ").map((part) => part[0]).join("")}</span><span><strong>{name}</strong><small>{index === 0 ? t("You") : t("Student")}</small></span></div>)}</div></section><section className="workspace-panel detail-wide"><div className="panel-heading"><div><span className="panel-kicker">{<LocalizedText text={"RECENT WORK"} />}</span><h2>{<LocalizedText text={"Assignments"} />}</h2></div><Link to="/app/assignments">{<LocalizedText text={"All work"} />}<ArrowRight size={15} /></Link></div><Link className="simple-row" to="/app/assignments/cell-notes"><span className="list-icon pending"><ClipboardCheck size={17} /></span><span><strong>{<LocalizedText text={"Cell structures concept map"} />}</strong><small>{<LocalizedText text={"Due Wednesday · 20 points"} />}</small></span><ArrowUpRight size={16} /></Link></section></div></>;
}

function AssignmentsPage({ assignments, user }) {
  const { t } = useLanguage();
  const formatDate = useLocalizedDate();
  const [status, setStatus] = useState("All"); const teacher = user.role === "teacher";
  const shown = assignments.filter((item) => status === "All" || item.status.toLowerCase() === status.toLowerCase());
  return <><PageHeading title={t("Assignments")} subtitle={teacher ? "Create learning tasks and follow up on submissions." : "A clear view of what’s due and what you’ve finished."} action={teacher && <Link className="workspace-button primary-action" to="/app/assignments/create"><Plus size={16} />{<LocalizedText text={"Create assignment"} />}</Link>} /><div className="filter-bar"><div className="filter-tabs">{["All", "Pending", "Submitted", "Late"].map((item) => <button key={item} className={status === item ? "active" : ""} onClick={() => setStatus(item)}>{t(item)}</button>)}</div><span>{shown.length}{<LocalizedText text={"tasks"} />}</span></div><div className="workspace-panel assignment-table">{shown.map((item) => <Link className="assignment-row" to={`/app/assignments/${item.id}`} key={item.id}><span className={`assignment-mark ${item.status}`}><ClipboardCheck size={18} /></span><span className="assignment-copy"><strong>{localizedRecord(t, item.id, item.title)}</strong><small>{localizedRecord(t, item.id, item.subject)}{<LocalizedText text={"· Due"} />}{formatDate(item.dueDate, { day: "numeric", month: "short", year: "numeric" })}</small></span><span className={`status-pill ${item.status}`}>{localizedStatus(t, item.status)}</span><ArrowUpRight size={16} /></Link>)}</div></>;
}

function AssignmentForm() {
  const { t } = useLanguage();
  const navigate = useNavigate(); const [error, setError] = useState("");
  async function submit(event) { event.preventDefault(); const form = new FormData(event.currentTarget); try { const item = await createAssignment({ title: form.get("title"), subject: form.get("subject"), dueDate: form.get("dueDate"), description: form.get("description"), teacher: "Jordan Rivera", points: form.get("points") }); navigate(`/app/assignments/${item.id}`); } catch (cause) { setError(t(cause.message)); } }
  return <><PageHeading title={t("Create assignment")} subtitle="Draft a task in this browser-only preview." /><form className="workspace-form" onSubmit={submit}><label>{<LocalizedText text={"Assignment title"} />}<input name="title" required placeholder={t("e.g. Ecosystems reflection")} /></label><div className="form-row"><label>{<LocalizedText text={"Subject"} />}<input name="subject" required placeholder={t("e.g. Biology")} /></label><label>{<LocalizedText text={"Due date"} />}<input name="dueDate" required type="date" /></label></div><div className="form-row"><label>{<LocalizedText text={"Points"} />}<input name="points" type="number" min="1" defaultValue="10" /></label><span /></div><label>{<LocalizedText text={"Instructions"} />}<textarea name="description" rows="5" required placeholder={t("Describe the learning goal and what to submit.")} /></label><PreviewNotice>{<LocalizedText text={"Creating this assignment only updates sample data held in this page session."} />}</PreviewNotice>{error && <p className="form-error">{error}</p>}<div className="form-actions"><Link className="workspace-button" to="/app/assignments">{<LocalizedText text={"Cancel"} />}</Link><button className="workspace-button primary-action" type="submit">{<LocalizedText text={"Create preview assignment"} />}<ArrowRight size={16} /></button></div></form></>;
}

function AssignmentDetail({ path, assignments }) {
  const { t } = useLanguage();
  const formatDate = useLocalizedDate();
  const formatNumber = useLocalizedNumber();
  const id = path.split("/").at(-1); const [item, setItem] = useState(assignments.find((entry) => entry.id === id)); const [file, setFile] = useState(""); const [message, setMessage] = useState("");
  useEffect(() => { let active = true; getAssignment(id).then((entry) => { if (active) setItem(entry); }).catch(() => { if (active) setItem(null); }); return () => { active = false; }; }, [id]);
  if (!item) return <EmptyState icon={ClipboardCheck} title={t("Assignment not found")} description="Try one of the sample assignments instead." action={<Link className="workspace-button" to="/app/assignments">{<LocalizedText text={"View assignments"} />}</Link>} />;
  async function submit(event) { event.preventDefault(); if (!file) return; await submitAssignment(item.id, file); setItem({ ...item, status: "submitted", fileName: file }); setMessage(t("Submission preview saved locally. No file was uploaded.")); }
  const subject = localizedRecord(t, item.id, item.subject);
  const title = localizedRecord(t, item.id, item.title);
  const description = localizedRecord(t, item.id, item.description);
  const dueDate = formatDate(item.dueDate, { day: "numeric", month: "short", year: "numeric" });
  return <><PageHeading eyebrow={`${subject} · ${formatNumber(item.points)} ${t("POINTS")}`} title={title} subtitle={`${t("Due")} ${dueDate} · ${t("Set by")} ${item.teacher}`} /><div className="detail-grid"><section className="workspace-panel detail-wide"><span className="panel-kicker">{<LocalizedText text={"INSTRUCTIONS"} />}</span><p className="assignment-instructions">{description}</p><div className="assignment-meta"><span className={`status-pill ${item.status}`}>{localizedStatus(t, item.status)}</span><span><CalendarDays size={14} />{t("Due")} {dueDate}</span></div></section><section className="workspace-panel submit-panel"><span className="panel-kicker">{<LocalizedText text={"YOUR SUBMISSION"} />}</span><h2>{item.status === "submitted" ? t("Work submitted") : t("Ready when you are")}</h2>{item.fileName && <p className="file-selected"><FileText size={16} />{item.fileName}</p>}<form onSubmit={submit} className="upload-form"><label className="file-picker"><Plus size={16} /><span>{file || t("Choose a file")}</span><input type="file" onChange={(event) => setFile(event.target.files?.[0]?.name || "")} /></label><small>{<LocalizedText text={"File selection is only previewed in this browser."} />}</small><button className="workspace-button primary-action" disabled={!file} type="submit">{<LocalizedText text={"Save submission preview"} />}<ArrowRight size={15} /></button></form>{message && <p className="form-success" role="status">{message}</p>}</section></div></>;
}

function MaterialsPage({ materials }) {
  const { t } = useLanguage();
  const [type, setType] = useState("All"); const [formOpen, setFormOpen] = useState(false); const [added, setAdded] = useState(""); const [localMaterials, setLocalMaterials] = useState(materials);
  const shown = localMaterials.filter((item) => type === "All" || item.type === type);
  async function add(event) { event.preventDefault(); const form = new FormData(event.currentTarget); const item = await addMaterial({ title: form.get("title"), subject: form.get("subject"), type: form.get("type") }); setLocalMaterials((items) => [item, ...items]); setAdded(t("{{title}} is available as a local preview.", { title: item.title })); setFormOpen(false); }
  return <><PageHeading title={t("Learning materials")} subtitle="Notes, references, and lesson resources." action={<button className="workspace-button primary-action" onClick={() => setFormOpen((open) => !open)}><Plus size={16} />{<LocalizedText text={"Add material"} />}</button>} />{formOpen && <form className="inline-create" onSubmit={add}><label>{<LocalizedText text={"Title"} />}<input required name="title" placeholder={t("Resource title")} /></label><label>{<LocalizedText text={"Subject"} />}<input required name="subject" placeholder={t("Subject")} /></label><label>{<LocalizedText text={"Type"} />}<select name="type"><option value={"Notes"}>{<LocalizedText text={"Notes"} />}</option><option value={"Document"}>{<LocalizedText text={"Document"} />}</option><option value={"Video"}>{<LocalizedText text={"Video"} />}</option><option value={"Image"}>{<LocalizedText text={"Image"} />}</option></select></label><button className="workspace-button primary-action" type="submit">{<LocalizedText text={"Add local preview"} />}</button></form>}{added && <p className="form-success">{added}</p>}<div className="filter-bar"><div className="filter-tabs">{["All", "Notes", "Document", "Video", "Image"].map((item) => <button className={type === item ? "active" : ""} key={item} onClick={() => setType(item)}>{t(item)}</button>)}</div><span>{shown.length}{<LocalizedText text={"resources"} />}</span></div><div className="material-grid">{shown.map((item) => <article className="material-card" key={item.id}><div className={`material-preview ${item.color}`}><span>{item.type === "Video" ? <Video size={26} /> : item.type === "Image" ? <Sparkles size={26} /> : item.type === "Notes" ? <BookOpen size={26} /> : <FileText size={26} />}</span><small>{t(item.type)}</small></div><div><span className="class-subject">{localizedRecord(t, item.id, item.subject)}</span><h2>{localizedRecord(t, item.id, item.title)}</h2><p>{localizedRecord(t, item.id, item.details)}</p><button className="text-action" onClick={() => setAdded(t("{{title}} opened in the preview.", { title: item.title }))}>{<LocalizedText text={"Preview resource"} />}<ArrowUpRight size={15} /></button></div></article>)}</div></>;
}

function AttendancePage({ records, role, setNotice }) {
  const formatDate = useLocalizedDate();
  const { t } = useLanguage();
  const [local, setLocal] = useState(records); const teacher = role === "teacher";
  function update(id, status) { setLocal((items) => items.map((item) => item.id === id ? { ...item, status } : item)); }
  async function save() { await saveAttendance(local); setNotice(t("Attendance updates saved in this local preview only.")); }
  return <><PageHeading title={t("Attendance")} subtitle={teacher ? "Review and update class attendance in the preview." : "Your attendance history and weekly overview."} action={teacher && <button className="workspace-button primary-action" onClick={save}><Check size={16} />{<LocalizedText text={"Save preview changes"} />}</button>} /><div className="overview-strip attendance-overview"><div><span>{<LocalizedText text={"Attendance rate"} />}</span><strong>{<LocalizedText text={"94%"} />}</strong><small>{<LocalizedText text={"This term"} />}</small></div><div><span>{<LocalizedText text={"Present"} />}</span><strong>{local.filter((item) => item.status === "Present").length}</strong><small>{<LocalizedText text={"Recorded sessions"} />}</small></div><div><span>{<LocalizedText text={"Absent"} />}</span><strong>{local.filter((item) => item.status === "Absent").length}</strong><small>{<LocalizedText text={"Recorded sessions"} />}</small></div></div><section className="workspace-panel attendance-table"><div className="panel-heading"><div><span className="panel-kicker">{<LocalizedText text={"RECENT RECORDS"} />}</span><h2>{teacher ? t("Class attendance") : t("Attendance history")}</h2></div><select aria-label={t("Filter attendance")}><option value={"All classes"}>{<LocalizedText text={"All classes"} />}</option><option value={"Biology"}>{<LocalizedText text={"Biology"} />}</option><option value={"Mathematics"}>{<LocalizedText text={"Mathematics"} />}</option></select></div>{local.map((item) => <div className="attendance-row" key={item.id}><span className="attendance-date">{formatDate(item.date, { day: "numeric", month: "short", year: "numeric" })}</span><strong>{localizedRecord(t, item.id, item.className)}</strong>{teacher ? <select value={item.status} onChange={(event) => update(item.id, event.target.value)} aria-label={`Attendance for ${item.className}`}><option value={"Present"}>{<LocalizedText text={"Present"} />}</option><option value={"Absent"}>{<LocalizedText text={"Absent"} />}</option><option value={"Late"}>{<LocalizedText text={"Late"} />}</option></select> : <span className={`status-pill ${item.status.toLowerCase()}`}>{t(item.status)}</span>}</div>)}</section></>;
}

function dateKey(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function parseDateKey(value) {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day, 12);
}

function addDays(date, amount) {
  const next = new Date(date);
  next.setDate(next.getDate() + amount);
  return next;
}

function startOfMondayWeek(date) {
  const start = new Date(date);
  const mondayOffset = (start.getDay() + 6) % 7;
  start.setDate(start.getDate() - mondayOffset);
  start.setHours(12, 0, 0, 0);
  return start;
}

function SchedulePage({ events, mode }) {
  const { t, language } = useLanguage();
  const formatDate = useLocalizedDate();
  const formatNumber = useLocalizedNumber();
  const [selected, setSelected] = useState("2026-10-19");
  const selectedDate = parseDateKey(selected);
  const locale = language === "hi" ? "hi-IN" : "en-IN";
  const weekdayKeys = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const weekStart = startOfMondayWeek(selectedDate);
  const weekDates = Array.from({ length: 7 }, (_, index) => addDays(weekStart, index));
  const monthStart = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1, 12);
  const monthFirstDayOffset = (monthStart.getDay() + 6) % 7;
  const monthCells = Array.from({ length: 42 }, (_, index) => addDays(monthStart, index - monthFirstDayOffset));
  const monthLabel = new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }).format(selectedDate);
  const visible = events.filter((item) => item.date === selected);

  function shiftPeriod(direction) {
    if (mode === "week") {
      setSelected(dateKey(addDays(selectedDate, direction * 7)));
      return;
    }

    const targetMonth = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + direction, 1, 12);
    const lastDay = new Date(targetMonth.getFullYear(), targetMonth.getMonth() + 1, 0).getDate();
    targetMonth.setDate(Math.min(selectedDate.getDate(), lastDay));
    setSelected(dateKey(targetMonth));
  }

  const periodLabel = mode === "week"
    ? t("Week of {{date}}", { date: formatDate(dateKey(weekStart), { day: "numeric", month: "short" }) })
    : monthLabel;

  return <>
    <PageHeading
      title={mode === "week" ? t("Your timetable") : t("Academic calendar")}
      subtitle={mode === "week" ? "A weekly view of classes and learning time." : "Classes, events, and deadlines in one place."}
      action={<div className="calendar-controls">
        <button className="icon-button" type="button" aria-label={t("Previous period")} onClick={() => shiftPeriod(-1)}><ChevronLeft size={17} /></button>
        <span>{periodLabel}</span>
        <button className="icon-button" type="button" aria-label={t("Next period")} onClick={() => shiftPeriod(1)}><ChevronRight size={17} /></button>
      </div>}
    />
    <div className="calendar-layout">
      <section className="workspace-panel calendar-panel">
        {mode === "week" ? <div className="calendar-weekdays">
          {weekDates.map((dayDate, index) => {
            const key = dateKey(dayDate);
            return <button type="button" key={key} onClick={() => setSelected(key)} className={selected === key ? "selected" : ""} aria-pressed={selected === key} aria-label={formatDate(key, { weekday: "long", day: "numeric", month: "long", year: "numeric" })}>
              <small>{t(weekdayKeys[index])}</small>
              <strong>{formatNumber(dayDate.getDate())}</strong>
            </button>;
          })}
        </div> : <>
          <div className="calendar-month-weekdays" aria-hidden="true">
            {weekdayKeys.map((day) => <span key={day}>{t(day)}</span>)}
          </div>
          <div className="month-grid">
            {monthCells.map((dayDate) => {
              const key = dateKey(dayDate);
              const inMonth = dayDate.getMonth() === selectedDate.getMonth();
              const hasEvents = events.some((event) => event.date === key);
              return <button
                key={key}
                type="button"
                className={`${selected === key ? "selected" : ""}${inMonth ? "" : " outside-month"}`}
                aria-pressed={selected === key}
                aria-label={formatDate(key, { weekday: "long", day: "numeric", month: "long", year: "numeric" })}
                onClick={() => setSelected(key)}
              >
                {formatNumber(dayDate.getDate())}
                {hasEvents && <i aria-hidden="true" />}
              </button>;
            })}
          </div>
        </>}
        <div className="panel-heading schedule-day-heading">
          <h2>{t(mode === "week" ? "Schedule · {{date}}" : "Events · {{date}}", { date: formatDate(selected, { day: "numeric", month: "short", year: "numeric" }) })}</h2>
          <span>{formatNumber(visible.length)} {t("items")}</span>
        </div>
        {visible.length ? visible.map((event) => <div className="event-row" key={event.id}>
          <span className="event-time">{event.time}</span>
          <span className={`event-mark ${event.type.toLowerCase()}`} />
          <span className="event-copy"><strong>{localizedRecord(t, event.id, event.title)}</strong><small>{t(event.type)} <LocalizedText text={"·"} /> {localizedRecord(t, event.id, event.location)}</small></span>
          <Link className="icon-button" to={event.type === "Class" ? `/app/classroom/${event.id}` : event.type === "Deadline" ? "/app/assignments" : "/app/classes"} aria-label={t("Details for {{title}}", { title: localizedRecord(t, event.id, event.title) })}><ArrowUpRight size={15} /></Link>
        </div>) : <EmptyState icon={CalendarDays} title="No events on this date" description="Choose another date or move to another period." />}
      </section>
      <aside className="workspace-panel calendar-aside">
        <span className="panel-kicker"><LocalizedText text={"UPCOMING"} /></span>
        <h2><LocalizedText text={"Coming up"} /></h2>
        {events.slice(0, 4).map((event) => <button className="upcoming-row" type="button" key={event.id} onClick={() => setSelected(event.date)}>
          <span>{formatNumber(Number(event.date.slice(-2)))}</span>
          <span><strong>{localizedRecord(t, event.id, event.title)}</strong><small>{event.time} <LocalizedText text={"·"} /> {t(event.type)}</small></span>
        </button>)}
      </aside>
    </div>
  </>;
}

function ChatPage({ initialMessages, setNotice }) {
  const { t } = useLanguage();
  const [messages, setMessages] = useState(initialMessages); const [text, setText] = useState(""); const [warning, setWarning] = useState("");
  async function send(event) { event.preventDefault(); if (!text.trim()) return; const check = await checkMessage(text); if (check.flagged) { setWarning(t(check.reason)); return; } const item = await sendLocalMessage(text.trim()); setMessages((items) => [...items, item]); setText(""); setWarning(""); setNotice(t("Message added to this browser only; it was not delivered to classmates.")); }
  return <><PageHeading title={t("Class chat")} subtitle="A local conversation preview for class discussions." /><div className="chat-layout"><aside className="chat-conversations"><span className="panel-kicker">{<LocalizedText text={"CONVERSATIONS"} />}</span><button className="conversation-item selected"><span className="conversation-avatar">{<LocalizedText text={"B"} />}</span><span><strong>{<LocalizedText text={"Biology · Cell structures"} />}</strong><small>{<LocalizedText text={"Ms. Rivera · Class group"} />}</small></span><i /></button><button className="conversation-item"><span className="conversation-avatar mint">{<LocalizedText text={"M"} />}</span><span><strong>{<LocalizedText text={"Mathematics · Algebra"} />}</strong><small>{<LocalizedText text={"Mr. Chen · Class group"} />}</small></span></button></aside><section className="chat-room"><div className="chat-room-heading"><span className="conversation-avatar">{<LocalizedText text={"B"} />}</span><span><strong>{<LocalizedText text={"Biology · Cell structures"} />}</strong><small>{<LocalizedText text={"24 learners · preview conversation"} />}</small></span><Users size={17} /></div><div className="chat-messages">{messages.map((item) => <article className={`chat-message ${item.mine ? "mine" : ""}`} key={item.id}><span className="chat-author">{localizedRecord(t, item.id, item.author)} <time>{item.time}</time></span><p>{localizedRecord(t, item.id, item.text)}</p></article>)}</div><form className="chat-composer" onSubmit={send}>{warning && <p className="form-error"><ShieldAlert size={15} />{warning}{<LocalizedText text={"Message was not added."} />}</p>}<label htmlFor="chat-message">{<LocalizedText text={"Message the preview conversation"} />}</label><div><input id="chat-message" value={text} onChange={(event) => setText(event.target.value)} placeholder={t("Write a message…")} /><button type="submit" aria-label={t("Add message locally")} disabled={!text.trim()}><ArrowRight size={17} /></button></div><small>{<LocalizedText text={"Preview spam review only. No message is sent to another person."} />}</small></form></section></div></>;
}

function AnnouncementsPage({ announcements }) {
  const { t } = useLanguage();
  const [active, setActive] = useState(announcements[0]?.id);
  const [reportNotice, setReportNotice] = useState("");
  const item = announcements.find((entry) => entry.id === active);

  return <><PageHeading title={t("Announcements")} subtitle="Updates and notes from your learning spaces." /><div className="announcement-layout"><div className="announcement-list">{announcements.map((entry) => <button key={entry.id} className={`announcement-card ${active === entry.id ? "selected" : ""}`} onClick={() => { setActive(entry.id); setReportNotice(""); }}><span>{localizedRecord(t, entry.id, entry.className)}</span><strong>{localizedRecord(t, entry.id, entry.title)}</strong><small>{localizedRecord(t, entry.id, entry.author)}{<LocalizedText text={"·"} />}{localizedRecord(t, entry.id, entry.date)}</small></button>)}</div>{item ? <article className="workspace-panel announcement-detail"><span className="panel-kicker">{localizedRecord(t, item.id, item.className)}</span><h2>{localizedRecord(t, item.id, item.title)}</h2><p className="announcement-byline">{<LocalizedText text={"Posted by"} />}{localizedRecord(t, item.id, item.author)}{<LocalizedText text={"·"} />}{localizedRecord(t, item.id, item.date)}</p><p>{localizedRecord(t, item.id, item.body)}</p><div className="moderation-row"><span><ShieldAlert size={15} />{<LocalizedText text={"Preview moderation controls"} />}</span><button className="text-action" onClick={() => setReportNotice(t("Flag noted in preview"))}>{<LocalizedText text={"Report for review"} />}</button></div>{reportNotice && <p className="form-success" role="status">{reportNotice}</p>}</article> : <EmptyState title={t("No announcements")} description="There are no updates in this preview." />}</div></>;
}

function NotificationsPage({ items, setData, allData }) {
  const { t } = useLanguage();
  const [filter, setFilter] = useState("All"); const [category, setCategory] = useState("All categories");
  const shown = items.filter((item) => (filter === "All" || (filter === "Unread" ? item.unread : !item.unread)) && (category === "All categories" || item.category === category));
  async function markOne(id) { const notifications = await markNotificationRead(id); setData({ ...allData, notifications }); }
  async function markAll() { const notifications = await markAllNotificationsRead(); setData({ ...allData, notifications }); }
  return <><PageHeading title={t("Notifications")} subtitle="Important updates from your learning space." action={<button className="workspace-button" onClick={markAll}><Check size={16} />{<LocalizedText text={"Mark all read"} />}</button>} /><div className="filter-bar"><div className="filter-tabs">{["All", "Unread", "Read"].map((item) => <button key={item} className={filter === item ? "active" : ""} onClick={() => setFilter(item)}>{t(item)}</button>)}</div><select value={category} onChange={(event) => setCategory(event.target.value)} aria-label={t("Notification category")}><option value={"All categories"}>{<LocalizedText text={"All categories"} />}</option><option value={"Classes"}>{<LocalizedText text={"Classes"} />}</option><option value={"Assignments"}>{<LocalizedText text={"Assignments"} />}</option></select></div><div className="notification-list">{shown.map((item) => <article className={`notification-row ${item.unread ? "unread" : ""}`} key={item.id}><span className="notification-icon"><Bell size={17} /></span><div><span className="notification-category">{t(item.category)}</span><strong>{localizedRecord(t, item.id, item.title)}</strong><p>{localizedRecord(t, item.id, item.body)}</p><Link to={item.href}>{<LocalizedText text={"Open related page"} />}<ArrowRight size={14} /></Link></div>{item.unread && <button className="icon-button" aria-label={t("Mark {{title}} as read", { title: localizedRecord(t, item.id, item.title) })} onClick={() => markOne(item.id)}><Check size={16} /></button>}</article>)}</div></>;
}

function MentorPage() {
  const { t } = useLanguage();
  const [messages, setMessages] = useState([{ role: "mentor", textKey: "Hi Alex. I’m your AI Mentor preview. What are you working through today?" }]); const [text, setText] = useState(""); const [loading, setLoading] = useState(false);
  async function ask(prompt) { const question = prompt || text; if (!question.trim() || loading) return; setMessages((items) => [...items, { role: "you", text: question }]); setText(""); setLoading(true); const response = await askMentor(question); setMessages((items) => [...items, { role: "mentor", ...response }]); setLoading(false); }
  function clear() { setMessages([{ role: "mentor", textKey: "Hi Alex. I’m your AI Mentor preview. What are you working through today?" }]); setText(""); }
  return <><PageHeading title={t("AI Mentor")} subtitle="A guided study conversation, powered by a predictable preview responder." action={<button className="workspace-button" onClick={clear}>{<LocalizedText text={"Clear conversation"} />}</button>} /><div className="mentor-workspace"><div className="mentor-head"><span><Bot size={20} /></span><div><strong>{<LocalizedText text={"Your learning companion"} />}</strong><small>{<LocalizedText text={"Preview responses · no AI service connected"} />}</small></div><i>{<LocalizedText text={"PREVIEW"} />}</i></div><div className="mentor-thread">{messages.map((item, index) => <article key={`${item.role}-${index}`} className={`mentor-message ${item.role}`}><span>{item.role === "you" ? t("You") : t("AI Mentor · preview")}</span><p>{item.role === "mentor" && item.textKey ? t(item.textKey) : item.role === "mentor" && item.responseKey ? t(item.responseKey, { subject: t(item.subjectKey) }) : item.text}</p></article>)}{loading && <p className="loading-response">{<LocalizedText text={"Thinking through a preview response…"} />}</p>}</div><div className="prompt-chips"><button onClick={() => ask(t("Explain cell structures"))}>{<LocalizedText text={"Explain cell structures"} />}</button><button onClick={() => ask(t("Plan my algebra practice"))}>{<LocalizedText text={"Plan my algebra practice"} />}</button><button onClick={() => ask(t("Prepare for a quiz"))}>{<LocalizedText text={"Prepare for a quiz"} />}</button></div><form className="mentor-composer" onSubmit={(event) => { event.preventDefault(); ask(); }}><input value={text} onChange={(event) => setText(event.target.value)} placeholder={t("Ask a study question…")} aria-label={t("Ask the preview mentor")} /><button type="submit" disabled={!text.trim() || loading} aria-label={t("Send question")}><ArrowRight size={18} /></button></form></div></>;
}

function QuizPage() {
  const { t } = useLanguage();
  const [topic, setTopic] = useState("Cell structures"); const [count, setCount] = useState("3"); const [difficulty, setDifficulty] = useState("Getting started"); const [questions, setQuestions] = useState([]); const [answers, setAnswers] = useState({}); const [submitted, setSubmitted] = useState(false);
  async function generate(event) { event.preventDefault(); const result = await generateQuiz({ count }); setQuestions(result.questions); setAnswers({}); setSubmitted(false); }
  const score = questions.reduce((total, item, index) => total + (answers[index] === item.answer ? 1 : 0), 0);
  return <><PageHeading title={t("Quiz Generator")} subtitle="Build a short practice round from the sample question set." /><form className="quiz-setup" onSubmit={generate}><label>{<LocalizedText text={"Topic"} />}<input value={topic === "Cell structures" ? t("Cell structures") : topic} onChange={(event) => setTopic(event.target.value === t("Cell structures") ? "Cell structures" : event.target.value)} required /></label><label>{<LocalizedText text={"Difficulty"} />}<select value={difficulty} onChange={(event) => setDifficulty(event.target.value)}><option value={"Getting started"}>{<LocalizedText text={"Getting started"} />}</option><option value={"Steady practice"}>{<LocalizedText text={"Steady practice"} />}</option><option value={"Challenge"}>{<LocalizedText text={"Challenge"} />}</option></select></label><label>{<LocalizedText text={"Questions"} />}<select value={count} onChange={(event) => setCount(event.target.value)}><option value="1">{<LocalizedText text={"1 question"} />}</option><option value="2">{<LocalizedText text={"2 questions"} />}</option><option value="3">{<LocalizedText text={"3 questions"} />}</option></select></label><button className="workspace-button primary-action" type="submit"><Sparkles size={16} />{<LocalizedText text={"Create preview quiz"} />}</button></form><PreviewNotice>{<LocalizedText text={"Question content is predefined sample data, not generated by a model."} />}</PreviewNotice>{questions.length > 0 && <section className="quiz-content"><div className="quiz-title"><span className="panel-kicker">{topic}{<LocalizedText text={"·"} />}{t(difficulty)}</span><h2>{<LocalizedText text={"Practice round"} />}</h2></div>{questions.map((item, index) => <fieldset className="quiz-question" key={item.prompt}><legend><span>{<LocalizedText text={"QUESTION"} />}{index + 1}</span>{t(item.prompt)}</legend>{item.options.map((option, optionIndex) => <label key={option}><input type="radio" name={`question-${index}`} checked={answers[index] === optionIndex} onChange={() => setAnswers({ ...answers, [index]: optionIndex })} />{t(option)}{submitted && optionIndex === item.answer && <Check size={15} />}</label>)}</fieldset>)}{submitted ? <div className="quiz-result"><strong>{score}{<LocalizedText text={"/"} />}{questions.length}</strong><span>{score === questions.length ? t("Excellent work.") : t("Review the answers and give it another try.")}</span><button className="workspace-button" onClick={generate}>{<LocalizedText text={"Try again"} />}</button></div> : <button className="workspace-button primary-action" disabled={Object.keys(answers).length !== questions.length} onClick={() => setSubmitted(true)}>{<LocalizedText text={"Check answers"} />}<Check size={16} /></button>}</section>}</>;
}

function Classroom() {
  const { t } = useLanguage();
  const navigate = useNavigate(); const [camera, setCamera] = useState(false); const [mic, setMic] = useState(false); const [hand, setHand] = useState(false); const [panel, setPanel] = useState("chat"); const [confirmLeave, setConfirmLeave] = useState(false); const [callNotice, setCallNotice] = useState("");
  return <><PageHeading eyebrow="VIRTUAL CLASSROOM · PREVIEW" title={t("Biology · Cell structures")} subtitle="A visual classroom preview. No camera, microphone, or video service is connected." />{callNotice && <div className="workspace-toast" role="status">{callNotice}<button aria-label={t("Dismiss")} onClick={() => setCallNotice("")}><X size={14} /></button></div>}<div className="classroom-layout"><section className="classroom-stage"><div className="stage-screen"><span className="stage-label"><span />{<LocalizedText text={"CLASS IN PROGRESS · PREVIEW"} />}</span><div className="teacher-placeholder"><span><GraduationCap size={36} /></span><strong>{<LocalizedText text={"Ms. Rivera"} />}</strong><small>{<LocalizedText text={"Presenting today’s lesson"} />}</small></div><div className="stage-caption">{<LocalizedText text={"Cell structures · Chapter 04"} />}</div></div><div className="participant-strip"><div><span className="participant-avatar violet">{<LocalizedText text={"MR"} />}</span><strong>{<LocalizedText text={"Ms. Rivera"} />}</strong><small>{<LocalizedText text={"Teacher"} />}</small></div><div><span className="participant-avatar mint">{<LocalizedText text={"AM"} />}</span><strong>{<LocalizedText text={"You"} />}</strong><small>{camera ? t("Camera preview on") : t("Camera off")}</small></div><div><span className="participant-avatar blue">{<LocalizedText text={"SK"} />}</span><strong>{<LocalizedText text={"Sam K."} />}</strong><small>{<LocalizedText text={"Participant preview"} />}</small></div></div><div className="call-controls"><button className={mic ? "on" : ""} onClick={() => setMic(!mic)} aria-label={mic ? t("Turn microphone off") : t("Turn microphone on")}><MessageCircle size={17} /><span>{mic ? t("Mic on") : t("Mic off")}</span></button><button className={camera ? "on" : ""} onClick={() => setCamera(!camera)} aria-label={camera ? t("Turn camera off") : t("Turn camera on")}><Video size={17} /><span>{camera ? t("Camera on") : t("Camera off")}</span></button><button onClick={() => setCallNotice(t("Screen sharing is shown as a preview state only; no screen is shared."))}><FileText size={17} /><span>{<LocalizedText text={"Share screen"} />}</span></button><button className={hand ? "on" : ""} onClick={() => setHand(!hand)}><Check size={17} /><span>{hand ? t("Hand raised") : t("Raise hand")}</span></button><button className="leave-control" onClick={() => setConfirmLeave(true)}><LogOut size={17} /><span>{<LocalizedText text={"Leave class"} />}</span></button></div></section><aside className="classroom-side"><div className="classroom-tabs"><button className={panel === "chat" ? "selected" : ""} onClick={() => setPanel("chat")}>{<LocalizedText text={"Chat"} />}</button><button className={panel === "people" ? "selected" : ""} onClick={() => setPanel("people")}>{<LocalizedText text={"People (24)"} />}</button></div>{panel === "chat" ? <div className="classroom-chat"><p><strong>{<LocalizedText text={"Ms. Rivera"} />}</strong>{<LocalizedText text={"Let’s start with the parts we can see."} />}</p><p><strong>{<LocalizedText text={"Sam K."} />}</strong>{<LocalizedText text={"The nucleus is in the center, right?"} />}</p><div className="class-chat-note">{<LocalizedText text={"Preview messages are not delivered to participants."} />}</div></div> : <div className="classroom-people">{[{ name: "Ms. Rivera", role: "Teacher" }, { name: "You", role: "Student" }, { name: "Sam K.", role: "Student" }, { name: "Jamie P.", role: "Student" }].map((person) => <div key={person.name}><span className="participant-avatar mint">{person.name.slice(0, 1)}</span><span>{t(person.name)} <small>{t(person.role)}</small></span></div>)}</div>}</aside></div>{confirmLeave && <div className="modal-backdrop" role="presentation"><section className="confirm-modal" role="dialog" aria-modal="true" aria-labelledby="leave-title"><button className="modal-close" onClick={() => setConfirmLeave(false)} aria-label={t("Close")}><X size={18} /></button><span className="modal-icon"><LogOut size={20} /></span><h2 id="leave-title">{<LocalizedText text={"Leave this preview class?"} />}</h2><p>{<LocalizedText text={"You’ll return to the class page. No real call is in progress."} />}</p><div><button className="workspace-button" onClick={() => setConfirmLeave(false)}>{<LocalizedText text={"Stay in class"} />}</button><button className="workspace-button danger-action" onClick={() => navigate("/app/classes/biology-10")}>{<LocalizedText text={"Leave class"} />}</button></div></section></div>}</>;
}

function ProfilePage({ user }) {
  const { t } = useLanguage();
  const [saved, setSaved] = useState(false); const [name, setName] = useState(user.name); const [email, setEmail] = useState(user.email || "");
  return <><PageHeading title={t("Your profile")} subtitle="Edit the details shown in this local preview." /><form className="workspace-form narrow-form" onSubmit={(event) => { event.preventDefault(); setSaved(true); }}><div className="profile-summary"><span className={`profile-large-avatar ${user.role}`}>{name.slice(0, 1).toUpperCase()}</span><span><strong>{name}</strong><small>{t(user.role === "student" ? "Student" : "Teacher")}{<LocalizedText text={"preview profile"} />}</small></span></div><label>{<LocalizedText text={"Display name"} />}<input value={name} onChange={(event) => setName(event.target.value)} required /></label><label>{<LocalizedText text={"Email address"} />}<input value={email} onChange={(event) => setEmail(event.target.value)} type="email" placeholder={t("Optional")} /></label><PreviewNotice>{<LocalizedText text={"Profile edits are shown in this page only and are not sent to a service."} />}</PreviewNotice><button className="workspace-button primary-action" type="submit">{<LocalizedText text={"Save profile preview"} />}<Check size={16} /></button>{saved && <p className="form-success" role="status">{<LocalizedText text={"Profile preview updated locally."} />}</p>}</form></>;
}

function SettingsPage() {
  const { t } = useLanguage();
  const [saved, setSaved] = useState(false); const [preferences, setPreferences] = useState(() => { try { return JSON.parse(localStorage.getItem("unified-learn-preview-preferences") || "{}"); } catch { return {}; } });
  useEffect(() => {
    document.documentElement.dataset.reduceMotion = preferences.motion ? "true" : "false";
  }, [preferences.motion]);
  function toggle(key) { setPreferences((current) => ({ ...current, [key]: !current[key] })); setSaved(false); }
  function save() {
    try {
      localStorage.setItem("unified-learn-preview-preferences", JSON.stringify(preferences));
      setSaved(true);
    } catch {
      setSaved(false);
    }
  }
  return <><PageHeading title={t("Settings")} subtitle="Manage preferences for this frontend prototype." /><div className="settings-layout"><section className="workspace-panel settings-section"><span className="panel-kicker">{<LocalizedText text={"PREFERENCES"} />}</span><h2>{<LocalizedText text={"Notifications"} />}</h2><label className="setting-row"><span><strong>{<LocalizedText text={"Assignment reminders"} />}</strong><small>{<LocalizedText text={"Show preview reminders for upcoming work"} />}</small></span><input type="checkbox" checked={Boolean(preferences.assignments)} onChange={() => toggle("assignments")} /></label><label className="setting-row"><span><strong>{<LocalizedText text={"Class announcements"} />}</strong><small>{<LocalizedText text={"Show updates from learning spaces"} />}</small></span><input type="checkbox" checked={Boolean(preferences.announcements)} onChange={() => toggle("announcements")} /></label><h2>{<LocalizedText text={"Accessibility"} />}</h2><label className="setting-row"><span><strong>{<LocalizedText text={"Reduce motion"} />}</strong><small>{<LocalizedText text={"Reduce animations and transitions across the interface"} />}</small></span><input type="checkbox" checked={Boolean(preferences.motion)} onChange={() => toggle("motion")} /></label><button className="workspace-button primary-action" onClick={save}>{<LocalizedText text={"Save preferences"} />}<Check size={16} /></button>{saved && <p className="form-success" role="status">{<LocalizedText text={"Preferences saved in this browser."} />}</p>}</section><section className="workspace-panel privacy-panel"><span className="panel-kicker">{<LocalizedText text={"YOUR DATA"} />}</span><h2>{<LocalizedText text={"Prototype privacy"} />}</h2><p>{<LocalizedText text={"This frontend uses sample content and a local preview role. It does not connect to an authentication provider, server, or storage service."} />}</p><p>{<LocalizedText text={"Role-preview data and selected preferences may remain in this browser until you end the preview session or clear site storage."} />}</p><Link to="/logout" className="workspace-button"><LogOut size={16} />{<LocalizedText text={"End preview session"} />}</Link></section></div></>;
}