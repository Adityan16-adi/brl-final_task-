import { useEffect, useMemo, useRef, useState } from "react";
import { Link, Navigate, NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  AlertCircle, ArrowRight, ArrowUpRight, Bell, BookMarked, BookOpen, Bot,
  CalendarDays, Check, CheckCircle2, ChevronLeft, ChevronRight, CircleHelp,
  Camera, CameraOff, ClipboardCheck, Eye, EyeOff, FileText, GraduationCap, Hand, LayoutDashboard, LogOut, Menu, Mic, MicOff,
  MessageCircle, Minus, Pencil, Plus, ScreenShare, ScreenShareOff, Search, Send, Settings, ShieldAlert, Sparkles, Trash2, TrendingDown, TrendingUp, Users, Video, Vote,
  PhoneOff, Smile, X,
} from "lucide-react";
import {
  addMaterial, askMentor, checkMessage, createAssignment, createClass,
  generateQuiz, getAssignment, getClassRosterAttendance, getSession, joinClass,
  listAnnouncements, listAssignments, listAttendance, listCalendarEvents, listCalendarMonth,
  listClasses, listMaterials, listMessages, listNotifications, loginAccount, resetPassword,
  loginWithGoogle, logoutAccount, markAllNotificationsRead, markNotificationRead, registerAccount,
  saveClassAttendance, sendLocalMessage, submitAssignment,
} from "../services/index.js";
import ThemeToggle from "./ThemeToggle.jsx";
import LanguageSelector from "../i18n/LanguageSelector.jsx";
import { useLanguage, useLocalizedDate, useLocalizedNumber } from "../i18n/useLanguage.js";
import "./Workspace.css";
import LocalizedText from "../i18n/LocalizedText.jsx";
import { isBackendMode } from "../services/api/backendAdapter.js";

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

const AVATAR_OPTIONS = [
  ["robot", "Robot", "🤖"], ["astronaut", "Astronaut", "🧑‍🚀"], ["fox", "Fox", "🦊"], ["cat", "Cat", "🐱"],
  ["panda", "Panda", "🐼"], ["owl", "Owl", "🦉"], ["tiger", "Tiger", "🐯"], ["dolphin", "Dolphin", "🐬"],
  ["penguin", "Penguin", "🐧"], ["rabbit", "Rabbit", "🐰"], ["dragon", "Dragon", "🐉"], ["butterfly", "Butterfly", "🦋"],
  ["planet", "Planet", "🪐"], ["comet", "Comet", "☄️"], ["rocket", "Rocket", "🚀"], ["star", "Star", "🌟"],
  ["book", "Book", "📚"], ["headphones", "Headphones", "🎧"], ["camera", "Camera", "📷"], ["graduation-cap", "Graduation cap", "🎓"],
];

function profileStorageKey(user, suffix = "avatar") {
  return `unified-learn-v1:${encodeURIComponent(user.role)}:${encodeURIComponent(user.id)}:${suffix}`;
}

function meetingStorageKey(classId, feature) {
  return `unified-learn-v1:meeting:${encodeURIComponent(classId)}:${feature}`;
}

function readLocalValue(key, fallback) {
  try {
    const value = JSON.parse(window.localStorage.getItem(key) || "null");
    return value ?? fallback;
  } catch {
    return fallback;
  }
}

function writeLocalValue(key, value) {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch {
    return false;
  }
}

function AvatarFace({ avatar, className = "" }) {
  const option = AVATAR_OPTIONS.find(([id]) => id === avatar);
  return <span className={`avatar-face ${className}`} aria-hidden="true">{option?.[2] || "🎓"}</span>;
}

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

function LocalNotice({ children = isBackendMode ? "Backend mode is enabled for supported records; classes, attendance, and other tools remain in preview." : "Preview mode: sample learning records and local changes stay in this browser." }) {
  const { t } = useLanguage();
  return <div className="local-notice"><Sparkles size={15} /><span>{typeof children === "string" ? t(children) : children}</span></div>;
}

function PreviewNotice({ children }) {
  return <LocalNotice>{children}</LocalNotice>;
}

function AuthHeader() {
  const { t } = useLanguage();
  return <div className="auth-topline"><Link className="auth-brand" to="/" aria-label={t("Pragti home")}><span className="brand-mark"><img src="/pragti-logo.png" alt="Pragti logo" className="brand-logo-img" /></span><span><strong>{<LocalizedText text={"Pragti"} />}</strong></span></Link><div className="auth-header-controls"><LanguageSelector /><ThemeToggle /></div></div>;
}

function PageHeading({ eyebrow = "PRAGTI", title, subtitle, action }) {
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
  const [showPassword, setShowPassword] = useState(false);
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
      setLoading(true);
      try {
        await resetPassword(recoveryEmail);
        setMessage(t("If an account exists for this email, Firebase has sent a password reset link."));
      } catch (cause) {
        setError(t(cause.message));
      } finally {
        setLoading(false);
      }
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
        : await loginAccount(isBackendMode ? { role, email: accountId, password: accessCode } : { role, accountId, accessCode });
      navigate(`/app/${session.user.role}/dashboard`);
    } catch (cause) {
      setError(t(cause.message));
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogleSignIn() {
    setError("");
    setMessage("");
    setLoading(true);
    try {
      const session = await loginWithGoogle(role);
      navigate(`/app/${session.user.role}/dashboard`);
    } catch (cause) {
      setError(t(cause.message));
    } finally {
      setLoading(false);
    }
  }

  return <main className={`auth-page ${role}-theme`} data-role={role}>
    <AuthHeader />
    <div className="auth-layout">
      <section className="auth-story"><span className="section-kicker">{t(mode === "forgot" ? "UNIFIED LEARN" : role === "student" ? "STUDENT PORTAL" : "TEACHER PORTAL")}</span><h1>{heading}</h1><p>{t("Classes, learning resources, and helpful next steps, all in one connected space.")}</p><div className="auth-story-art"><div><BookOpen size={23} /><span>{t("Everything you need")}<br />{t("for your next step")}</span></div><span className="auth-art-star">{<LocalizedText text={"✳"} />}</span><span className="auth-art-line" /></div></section>
      <section className="auth-form-wrap"><div className="auth-form-heading"><span className="page-eyebrow">{t("ACCOUNT ACCESS")}</span><h2>{mode === "forgot" ? t("Reset your password") : mode === "register" ? t(role === "student" ? "Create a student profile" : "Create a teacher profile") : t(role === "student" ? "Student sign in" : "Teacher sign in")}</h2><p>{mode === "forgot" ? t(isBackendMode ? "Enter the email address for your provisioned Firebase account." : "Password recovery is not available in mock mode.") : mode === "register" ? t(isBackendMode ? "Online account creation is managed by your administrator." : "Profile setup is stored locally and does not create an online account.") : t(isBackendMode ? "Sign in with the email and password for your provisioned account." : role === "student" ? "Sign in to the student portal with the account ID assigned to you." : "Sign in to the teacher portal with the account ID assigned to you.")}</p></div>
        {mode !== "forgot" ? <form onSubmit={handleSubmit} className="form-stack">
          {mode === "register" ? <label>{t("Display name")}<input required value={name} onChange={(event) => setName(event.target.value)} placeholder={t("How should we address you?")} /></label> : <>
            <label>{t(isBackendMode ? "Email" : role === "student" ? "Student ID" : "Teacher ID")}<input required type={isBackendMode ? "email" : "text"} value={accountId} onChange={(event) => setAccountId(event.target.value)} placeholder={isBackendMode ? t("you@example.com") : t(role === "student" ? "Enter student ID" : "Enter teacher ID")} autoComplete="username" /></label>
            <label>{t(isBackendMode ? "Password" : "Access code")}<span className="password-field"><input required type={showPassword ? "text" : "password"} value={accessCode} onChange={(event) => setAccessCode(event.target.value)} placeholder={t(isBackendMode ? "Enter your password" : "Enter your access code")} autoComplete="current-password" /><button type="button" aria-label={t(showPassword ? "Hide password" : "Show password")} aria-pressed={showPassword} onClick={() => setShowPassword((visible) => !visible)}><span className="sr-only">{t(showPassword ? "Hide password" : "Show password")}</span>{showPassword ? <EyeOff size={17} /> : <Eye size={17} />}</button></span></label>
          </>}
          {error && <p className="form-error" role="alert">{error}</p>}
          <LocalNotice>{mode === "register" ? t(isBackendMode ? "Ask your administrator to create and link your online account." : "Profile setup is local to this browser; no online account is created.") : isBackendMode ? t("Use an account provisioned for this portal. Your role is confirmed by the backend.") : t("Use the account details configured for this local preview.")}</LocalNotice>
          <button className="workspace-button primary-action" type="submit" disabled={loading || (isBackendMode && mode === "register")}>{loading ? t("Opening your space…") : mode === "register" ? t(isBackendMode ? "Online registration unavailable" : "Create profile") : t(role === "student" ? "Sign in as student" : "Sign in as teacher")}<ArrowRight size={16} /></button>
          {isBackendMode && <><div className="auth-divider"><span>{t("or continue with")}</span></div><button className="workspace-button google-action" type="button" onClick={handleGoogleSignIn} disabled={loading}><svg className="google-mark" viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5Z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.25 5.48-4.72 7.18l7.62 5.91c4.45-4.1 7.14-10.15 7.14-17.56Z"/><path fill="#FBBC05" d="M10.53 28.59A14.4 14.4 0 0 1 9.75 24c0-1.59.27-3.13.75-4.59l-7.98-6.19A23.9 23.9 0 0 0 0 24c0 3.89.93 7.58 2.56 10.78l7.97-6.19Z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.9-5.89l-7.62-5.91c-2.11 1.41-4.82 2.25-8.28 2.25-6.26 0-11.57-4.22-13.46-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48Z"/></svg>{loading ? t("Connecting to Google…") : t("Continue with Google")}</button></>}
        </form> : <form onSubmit={handleSubmit} className="form-stack"><label>{t("Email")}<input required type="email" value={recoveryEmail} onChange={(event) => setRecoveryEmail(event.target.value)} placeholder={t("you@example.com")} /></label>{error && <p className="form-error" role="alert">{error}</p>}<button className="workspace-button primary-action" type="submit" disabled={loading}>{loading ? t("Sending reset link…") : t("Request reset link")} <ArrowRight size={16} /></button>{message && <p className="form-success" role="status">{message}</p>}</form>}
        {mode !== "forgot" && message && <p className="form-success" role="status">{message}</p>}
        {mode !== "forgot" && <div className="auth-links">{mode === "login" && <Link to="/forgot-password">{t("Forgot password?")}</Link>}<span>{t(mode === "register" ? "Already have a profile?" : "Need a profile?")} <Link to={`/${role}/${mode === "register" ? "login" : "register"}`}>{t(mode === "register" ? role === "student" ? "Student sign in" : "Teacher sign in" : role === "student" ? "Register as student" : "Register as teacher")}</Link></span></div>}
        {mode === "forgot" && <div className="auth-links"><Link to="/student/login">{t("Student sign in")}</Link><Link to="/teacher/login">{t("Teacher sign in")}</Link></div>}
      </section>
    </div>
    <span className="auth-footnote">{t(isBackendMode ? "Secure sign-in powered by your Pragti account." : "A frontend prototype · Authentication is simulated")}</span>
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
        <div className="auth-links"><Link to={isRegister ? "/login" : "/register"}>{t(isRegister ? "Already exploring? Choose a login portal" : "New to Pragti? Choose a registration portal")}</Link></div>
      </section>
    </div>
    <span className="auth-footnote">{t(isBackendMode ? "Secure sign-in powered by your Pragti account." : "A frontend prototype · Authentication is simulated")}</span>
  </main>;
}

export function LogoutPage() {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const [done, setDone] = useState(false);
  const [error, setError] = useState("");
  async function handleLogout() {
    try { await logoutAccount(); setDone(true); setError(""); }
    catch (cause) { setError(cause.message || "Sign out could not be completed."); }
  }
  return <main className="logout-page"><AuthHeader /><section><span className="logout-icon"><LogOut size={23} /></span><h1>{done ? t("You have signed out") : t("Sign out?")}</h1><p>{done ? t(isBackendMode ? "Your Firebase session has been cleared." : "Your local account session has been cleared.") : t(isBackendMode ? "This signs you out of your Firebase account." : "This clears the account session stored in this browser.")}</p>{error && <p className="form-error" role="alert">{t(error)}</p>}{done ? <Link className="workspace-button primary-action" to="/login">{<LocalizedText text={"Return to portal selection"} />}<ArrowRight size={16} /></Link> : <div className="logout-actions"><button className="workspace-button primary-action" onClick={handleLogout}>{<LocalizedText text={"Sign out"} />}<LogOut size={16} /></button><button className="workspace-button" onClick={() => navigate(-1)}>{<LocalizedText text={"Stay here"} />}</button></div>}</section></main>;
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
  const [sessionError, setSessionError] = useState("");
  const [avatar, setAvatar] = useState("graduation-cap");

  useEffect(() => {
    let active = true;
    getSession().then(async (value) => {
      if (!active) return;
      setSession(value);
      if (!value) return;
      const results = await Promise.allSettled([
        listClasses(), listAssignments(), listMaterials(), listAttendance(), listCalendarEvents(), listAnnouncements(), listMessages(), listNotifications(),
      ]);
      if (active) {
        const keys = ["classes", "assignments", "materials", "attendance", "events", "announcements", "messages", "notifications"];
        const nextData = {};
        const failures = [];
        results.forEach((result, index) => {
          if (result.status === "fulfilled") nextData[keys[index]] = result.value;
          else {
            nextData[keys[index]] = [];
            failures.push(result.reason?.message || "A learning service could not be reached.");
          }
        });
        setData(nextData);
        if (failures.length) setNotice([...new Set(failures)].join(" "));
        setDataLoaded(true);
      }
    }).catch((error) => {
      if (!active) return;
      setSessionError(error.message || "Your account could not be verified by the backend. Sign in again or contact your administrator.");
      setSession(null);
    });
    return () => { active = false; };
  }, []);

  const user = session?.user;
  const activeAvatar = user ? readLocalValue(profileStorageKey(user), avatar) : avatar;
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
  if (!session) return <Navigate to="/login" replace state={{ accessMessageKey: sessionError || "Sign in with a student or teacher account to continue." }} />;
  if (portalMatch && portalMatch[1] !== user.role) {
    return <Navigate to={`${rolePath}/dashboard`} replace state={{ accessMessageKey: "This {{role}} space is unavailable to your {{userRole}} account. Sign out and use a separate {{role}} account to access it.", values: { role: t(portalMatch[1] === "student" ? "Student" : "Teacher").toLowerCase(), userRole: t(user.role === "student" ? "Student" : "Teacher").toLowerCase() } }} />;
  }
  if (!portalMatch) {
    const requestedPath = location.pathname.slice("/app".length) || "/dashboard";
    return <Navigate to={`${rolePath}${requestedPath}`} replace />;
  }

  const workspacePath = `/app${location.pathname.slice(rolePath.length)}`;

  return <div className={`workspace-shell ${user.role}-theme`} data-role={user.role}>
    {mobileOpen && <button className="workspace-scrim" aria-label={t("Close navigation menu")} onClick={() => setMobileOpen(false)} />}
    <aside className={`workspace-sidebar ${mobileOpen ? "sidebar-open" : ""}`}>
      <Link className="workspace-brand" to={`${rolePath}/dashboard`}><span className="brand-mark"><img src="/pragti-logo.png" alt="Pragti logo" className="brand-logo-img" /></span><span><strong>{<LocalizedText text={"Pragti"} />}</strong></span></Link>
      <div className="sidebar-role" aria-label={t("{{role}} account", { role: t(user.role === "student" ? "Student" : "Teacher").toLowerCase() })}><AvatarFace avatar={activeAvatar} className={`role-avatar ${user.role}`} /><span><strong>{user.name}</strong><small>{t("{{role}} account · {{id}}", { role: t(user.role === "student" ? "Student" : "Teacher"), id: user.id })}</small></span></div>
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
  <div className="workspace-nav-divider" role="separator" />
  <Link
    to="/logout"
    onClick={() => setMobileOpen(false)}
    className="workspace-nav-link nav-logout"
    aria-label={t("Sign out")}
  >
    <LogOut size={17} />
    <span>{t("Sign out")}</span>
  </Link>
</nav>
      <div className="sidebar-bottom"><Link to="/app/profile" onClick={() => setMobileOpen(false)}><Users size={17} /> {t("Profile")}</Link><Link to="/app/settings" onClick={() => setMobileOpen(false)}><Settings size={17} /> {t("Settings")}</Link></div>
    </aside>
    <div className="workspace-main">
      <header className="workspace-topbar">
        <button className="workspace-menu-button" aria-label={t("Open navigation")} onClick={() => setMobileOpen(true)}><Menu size={20} /></button>
        <div className="workspace-breadcrumb"><Link to={`${rolePath}/dashboard`}><img src="/pragti-logo.png" alt="Pragti" className="topbar-brand-logo" /><span>{t("Workspace")}</span></Link><ChevronRight size={14} /><span>{title}</span></div>
        <label className="workspace-search"><Search size={16} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder={t("Search your learning space")} aria-label={t("Search learning content")} />{query && <button type="button" aria-label={t("Clear search")} onClick={() => setQuery("")}><X size={14} /></button>}</label>
        <LanguageSelector />
        <ThemeToggle compact />
        <Link to="/app/notifications" className="topbar-icon" aria-label={t("Notifications")}><Bell size={18} />{data.notifications.some((item) => item.unread) && <i />}</Link>
        <Link className="topbar-profile" to="/app/profile"><AvatarFace avatar={activeAvatar} className={`role-avatar ${user.role}`} /><span>{user.name.split(" ")[0]}</span></Link>
      </header>
      <main className="workspace-content">
        <LocalNotice />
        {visibleNotice && <div className="workspace-toast" role="status"><ShieldAlert size={16} />{visibleNotice}<button aria-label={t("Dismiss")} onClick={dismissNotice}><X size={14} /></button></div>}
        {dataLoaded ? <WorkspacePage path={workspacePath} user={user} avatar={activeAvatar} setAvatar={setAvatar} data={filtered} allData={data} setData={setData} setNotice={setNotice} query={query} /> : <div className="page-loading" role="status">{<LocalizedText text={"Loading learning records…"} />}</div>}
      </main>
      <footer className="workspace-footer"><span>{<LocalizedText text={"Pragti"} />} · {t("Learn · Grow · Achieve")}</span><span>{t(isBackendMode ? "Backend mode is enabled for supported records; other tools remain in preview." : "Changes are stored only in this browser.")}</span></footer>
    </div>
  </div>;
}

function WorkspacePage({ path, user, avatar, setAvatar, data, allData, setData, setNotice, query }) {
  if (path.endsWith("/dashboard")) return <Dashboard user={user} avatar={avatar} data={data} />;
  if (path.endsWith("/classes/create")) return <ClassForm />;
  if (path.endsWith("/classes/join")) return <JoinClass />;
  if (path.includes("/classroom/")) return <Classroom key={path} path={path} user={user} classes={data.classes} />;
  if (path.includes("/classes/")) return <ClassDetail path={path} classes={data.classes} />;
  if (path.endsWith("/classes")) return <ClassesPage classes={data.classes} query={query} />;
  if (path.endsWith("/assignments/create")) return <AssignmentForm />;
  if (path.includes("/assignments/")) return <AssignmentDetail path={path} assignments={data.assignments} />;
  if (path.endsWith("/assignments")) return <AssignmentsPage assignments={data.assignments} user={user} />;
  if (path.endsWith("/materials")) return <MaterialsPage materials={data.materials} />;
  if (path.endsWith("/attendance")) return <AttendancePage records={allData.attendance} classes={allData.classes} user={user} setNotice={setNotice} />;
  if (path.endsWith("/timetable")) return <SchedulePage events={allData.events} mode="week" user={user} setNotice={setNotice} />;
  if (path.endsWith("/calendar")) return <SchedulePage events={allData.events} mode="month" user={user} setNotice={setNotice} />;
  if (path.endsWith("/chat")) return <ChatPage initialMessages={data.messages} setNotice={setNotice} />;
  if (path.endsWith("/announcements")) return <AnnouncementsPage announcements={data.announcements} />;
  if (path.endsWith("/notifications")) return <NotificationsPage items={data.notifications} setData={setData} allData={allData} />;
  if (path.endsWith("/mentor")) return <MentorPage />;
  if (path.endsWith("/quizzes")) return <QuizPage />;
  if (path.endsWith("/profile")) return <ProfilePage user={user} avatar={avatar} setAvatar={setAvatar} />;
  if (path.endsWith("/settings")) return <SettingsPage />;
  return <Navigate to="/app/dashboard" replace />;
}

function Dashboard({ user, avatar, data }) {
  return user.role === "teacher"
    ? <TeacherDashboard user={user} avatar={avatar} data={data} />
    : <StudentDashboard user={user} avatar={avatar} data={data} />;
}

function WorkspaceUpdates({ notifications, materials }) {
  const { t } = useLanguage();
  const unread = notifications.filter((item) => item.unread).slice(0, 3);
  const recentMaterials = materials.slice(0, 3);
  return <>
    <section className="announcement-mini">
      <div className="panel-heading"><h2>{t("Unread updates")}</h2><Link to="/app/notifications" aria-label={t("View all notifications")}><ArrowUpRight size={16} /></Link></div>
      {unread.length ? unread.map((item) => <Link className="announcement-mini-row" to={item.href || "/app/notifications"} key={item.id}><strong>{localizedRecord(t, item.id, item.title)}</strong><small>{localizedRecord(t, item.id, item.body)}</small></Link>) : <p className="dashboard-empty-copy">{t("You’re all caught up.")}</p>}
    </section>
    <section className="announcement-mini">
      <div className="panel-heading"><h2>{t("Recent materials")}</h2><Link to="/app/materials" aria-label={t("Browse learning materials")}><ArrowUpRight size={16} /></Link></div>
      {recentMaterials.length ? recentMaterials.map((item) => <Link className="announcement-mini-row" to="/app/materials" key={item.id}><strong>{localizedRecord(t, item.id, item.title)}</strong><small>{localizedRecord(t, item.id, item.subject)} · {t(item.type)}</small></Link>) : <div className="dashboard-empty-copy">{t("Learning materials will appear here when they’re available.")} <Link to="/app/materials">{t("Browse materials")}</Link></div>}
    </section>
  </>;
}

function StudentDashboard({ user, avatar, data }) {
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

  const studentAttendance = data.attendance.filter((item) => [item.studentId, item.userId, item.student?.id, item.student?.email].some((id) => id && [user.id, user.email].includes(id)));
  const presentCount = studentAttendance.filter(
    (item) => (item.status || "").toLowerCase() === "present"
  ).length;

  const attendanceRate = studentAttendance.length
    ? `${Math.round((presentCount / studentAttendance.length) * 100)}%`
    : "—";

  return (
    <div className="role-dashboard student-dashboard">
      <PageHeading
        eyebrow="YOUR LEARNING SPACE"
        title={t("Good morning, {{name}}.", { name: firstName })}
        subtitle={t("Here’s your day, at a glance.")}
        action={<div className="dashboard-heading-actions"><div className="dashboard-identity"><AvatarFace avatar={avatar} /><span>{user.name}</span></div><Link to={`${base}/timetable`} className="workspace-button"><CalendarDays size={16} />{t("View calendar")}</Link></div>}
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

      <nav className="student-quick-actions" aria-label={t("Quick learning links")}>
        {[[BookOpen, "Classes", `${base}/classes`], [ClipboardCheck, "Assignments", `${base}/assignments`], [FileText, "Learning materials", `${base}/materials`], [CalendarDays, "Calendar", `${base}/calendar`]].map(([Icon, label, href]) => <Link key={href} to={href}><Icon size={17} /><span>{t(label)}</span><ArrowUpRight size={14} /></Link>)}
      </nav>

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

            <h3>{t(attendanceRate === "—" ? "Attendance data unavailable" : "Attendance progress")}</h3>
            <p>{t(attendanceRate === "—" ? "Attendance records linked to your account will appear here." : "Your attendance rate is calculated from records linked to your account.")}</p>

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
            {!data.announcements.length && <p className="dashboard-empty-copy">{t("Class announcements will appear here when they’re available.")}</p>}
          </section>

          <WorkspaceUpdates notifications={data.notifications} materials={data.materials} />

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

function TeacherDashboard({ user, avatar, data }) {
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

  return (
    <div className="role-dashboard teacher-dashboard">
      <PageHeading
        eyebrow="TEACHER SPACE"
        title={t("Good morning, {{name}}.", { name: firstName })}
        subtitle={t("Your classes and follow-ups are ready.")}
        action={<div className="dashboard-heading-actions"><div className="dashboard-identity"><AvatarFace avatar={avatar} /><span>{user.name}</span></div><Link to={`${base}/assignments`} className="workspace-button primary-action"><ClipboardCheck size={16} />{t("Recent submissions")}</Link></div>}
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
          <span>{t("Upcoming sessions")}</span>
          <strong>{upcomingClasses.length}</strong>
          <small>{t("From available calendar records")}</small>
        </div>

        <div>
          <span>{t("To review")}</span>
          <strong>{reviewQueue.length}</strong>
          <small>{t("Submissions waiting")}</small>
        </div>
      </div>

      <div className="dashboard-grid teacher-command-grid">
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

              {data.classes[0] && <Link className="portal-option" to={`/app/classroom/${data.classes[0].id}`}>
                <span className="role-icon"><Video size={17} /></span>
                <span><strong>{t("Open classroom")}</strong><small>{localizedRecord(t, data.classes[0].id, data.classes[0].name)} · {t("local meeting preview")}</small></span>
                <ArrowUpRight size={15} />
              </Link>}

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
          <WorkspaceUpdates notifications={data.notifications} materials={data.materials} />
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
  return <><PageHeading title={t("Classes")} subtitle="Your learning spaces, in one place." action={<div className="heading-actions"><Link className="workspace-button" to="/app/classes/join"><Users size={16} /> {t("Join class")}</Link><Link className="workspace-button primary-action" to="/app/classes/create"><Plus size={16} /> {t("Create class")}</Link></div>} /><div className="filter-bar"><div className="filter-tabs">{subjects.map((item) => <button className={subject === item ? "active" : ""} key={item} onClick={() => setSubject(item)}>{t(item)}</button>)}</div><span>{t("{{count}} classes", { count: shown.length })}</span></div>{shown.length ? <div className="class-grid">{shown.map((item) => <article className="class-card" key={item.id}><div className={`class-card-cover ${item.color}`}><span>{item.subject.slice(0, 2).toUpperCase()}</span><small>{t("Class preview")}</small></div><div className="class-card-body"><span className="class-subject">{localizedRecord(t, item.id, item.subject)}</span><h2>{localizedRecord(t, item.id, item.name)}</h2><p>{item.teacher}{<LocalizedText text={"·"} />}{localizedRecord(t, item.id, item.room)}</p><div className="class-card-bottom"><span><CalendarDays size={14} />{localizedRecord(t, item.id, item.schedule)}</span><Link to={`/app/classes/${item.id}`} aria-label={t("Open {{title}}", { title: localizedRecord(t, item.id, item.name) })}><ArrowUpRight size={17} /></Link></div></div></article>)}</div> : <EmptyState icon={Search} title={t("No classes match")} description={query ? "Try another search." : "Create a class or join with a preview code."} action={<Link className="workspace-button" to="/app/classes/join">{t("Join a class")}</Link>} />}</>;
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
  return <><PageHeading eyebrow={localizedRecord(t, item.id, item.subject)} title={localizedRecord(t, item.id, item.name)} subtitle={`${item.teacher} · ${localizedRecord(t, item.id, item.room)} · ${localizedRecord(t, item.id, item.schedule)}`} action={<Link to={`/app/classroom/${item.id}`} className="workspace-button primary-action"><Video size={16} />{<LocalizedText text={"Open classroom"} />}</Link>} /><div className="detail-grid"><section className="workspace-panel"><div className="panel-heading"><div><span className="panel-kicker">{<LocalizedText text={"CLASS SPACE"} />}</span><h2>{<LocalizedText text={"Welcome to"} />}{localizedRecord(t, item.id, item.subject)}</h2></div><span className="preview-tag">{<LocalizedText text={"PREVIEW"} />}</span></div><p className="panel-body-copy">{<LocalizedText text={"Your class space brings sessions, resources, assignments, and updates together. These records are sample content for a frontend preview."} />}</p><div className="meeting-preview"><Video size={19} /><span><strong>{<LocalizedText text={"Meeting link preview"} />}</strong><small>{<LocalizedText text={"unified-learn.preview/class/"} />}{item.id}{<LocalizedText text={"· not a real meeting"} />}</small></span><button className="icon-button" aria-label={t("Copy preview meeting link")} onClick={() => navigator.clipboard?.writeText(`https://unified-learn.preview/class/${item.id}`)}> <ArrowUpRight size={16} /></button></div></section><section className="workspace-panel"><div className="panel-heading"><div><span className="panel-kicker">{t("CLASS MEMBERS")}</span><h2>{t("Roster unavailable")}</h2></div><Users size={17} /></div><EmptyState icon={Users} title="No verified roster is available" description="Participant names and enrollment counts require linked class roster data." /></section><section className="workspace-panel detail-wide"><div className="panel-heading"><div><span className="panel-kicker">{t("RECENT WORK")}</span><h2>{t("Assignments")}</h2></div><Link to="/app/assignments">{t("All work")}<ArrowRight size={15} /></Link></div><EmptyState icon={ClipboardCheck} title="No class-linked assignments available" description="Assignments will appear here when the service provides their class association." /></section></div></>;
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
  const navigate = useNavigate(); const [error, setError] = useState(""); const [saving, setSaving] = useState(false);
  async function submit(event) { event.preventDefault(); if (saving) return; setSaving(true); setError(""); const form = new FormData(event.currentTarget); try { const item = await createAssignment({ title: form.get("title"), subject: form.get("subject"), dueDate: form.get("dueDate"), description: form.get("description"), teacher: "Jordan Rivera", points: form.get("points") }); navigate(`/app/assignments/${item.id}`); } catch (cause) { setError(t(cause.message)); } finally { setSaving(false); } }
  return <><PageHeading title={t("Create assignment")} subtitle={isBackendMode ? "Create an assignment for the configured class." : "Draft a task in this browser-only preview."} /><form className="workspace-form" onSubmit={submit}><label>{<LocalizedText text={"Assignment title"} />}<input name="title" required placeholder={t("e.g. Ecosystems reflection")} /></label><div className="form-row"><label>{<LocalizedText text={"Subject"} />}<input name="subject" required placeholder={t("e.g. Biology")} /></label><label>{<LocalizedText text={"Due date"} />}<input name="dueDate" required type="date" /></label></div><div className="form-row"><label>{<LocalizedText text={"Points"} />}<input name="points" type="number" min="1" defaultValue="10" /></label><span /></div><label>{<LocalizedText text={"Instructions"} />}<textarea name="description" rows="5" required placeholder={t("Describe the learning goal and what to submit.")} /></label>{isBackendMode ? <p className="field-hint">{t("This will be sent to the configured backend class.")}</p> : <PreviewNotice>{<LocalizedText text={"Creating this assignment only updates sample data held in this page session."} />}</PreviewNotice>}{error && <p className="form-error" role="alert">{error}</p>}<div className="form-actions"><Link className="workspace-button" to="/app/assignments">{<LocalizedText text={"Cancel"} />}</Link><button className="workspace-button primary-action" disabled={saving} type="submit">{saving ? t("Saving…") : t(isBackendMode ? "Create assignment" : "Create preview assignment")}<ArrowRight size={16} /></button></div></form></>;
}

function AssignmentDetail({ path, assignments }) {
  const { t } = useLanguage();
  const formatDate = useLocalizedDate();
  const formatNumber = useLocalizedNumber();
  const id = path.split("/").at(-1); const [loadedItem, setLoadedItem] = useState(null); const [loadFailure, setLoadFailure] = useState(null); const [file, setFile] = useState(null); const [message, setMessage] = useState(""); const [submitError, setSubmitError] = useState(""); const [submitting, setSubmitting] = useState(false);
  const item = loadedItem?.id === id ? loadedItem : assignments.find((entry) => entry.id === id);
  const loadError = loadFailure?.id === id ? loadFailure.message : "";
  useEffect(() => { let active = true; getAssignment(id).then((entry) => { if (active) setLoadedItem(entry); }).catch((cause) => { if (active) setLoadFailure({ id, message: cause.message || "Assignment could not be loaded." }); }); return () => { active = false; }; }, [id]);
  if (!item) return <><PageHeading title={loadError ? t("Could not load assignment") : t("Loading assignment…")} />{loadError && <p className="form-error" role="alert">{t(loadError)}</p>}<Link className="workspace-button" to="/app/assignments">{<LocalizedText text={"View assignments"} />}</Link></>;
  async function submit(event) { event.preventDefault(); if (!file || submitting) return; setSubmitting(true); setSubmitError(""); try { const result = await submitAssignment(item.id, file); setLoadedItem({ ...item, status: "submitted", fileName: file.name, submission: result }); setMessage(t("Assignment submitted successfully.")); } catch (cause) { setSubmitError(t(cause.message)); } finally { setSubmitting(false); } }
  const subject = localizedRecord(t, item.id, item.subject);
  const title = localizedRecord(t, item.id, item.title);
  const description = localizedRecord(t, item.id, item.description);
  const dueDate = formatDate(item.dueDate, { day: "numeric", month: "short", year: "numeric" });
  return <><PageHeading eyebrow={`${subject} · ${formatNumber(item.points)} ${t("POINTS")}`} title={title} subtitle={`${t("Due")} ${dueDate} · ${t("Set by")} ${item.teacher}`} />{loadError && <p className="form-error" role="alert">{t(loadError)}</p>}<div className="detail-grid"><section className="workspace-panel detail-wide"><span className="panel-kicker">{<LocalizedText text={"INSTRUCTIONS"} />}</span><p className="assignment-instructions">{description}</p><div className="assignment-meta"><span className={`status-pill ${item.status}`}>{localizedStatus(t, item.status)}</span><span><CalendarDays size={14} />{t("Due")} {dueDate}</span></div></section><section className="workspace-panel submit-panel"><span className="panel-kicker">{<LocalizedText text={"YOUR SUBMISSION"} />}</span><h2>{item.status === "submitted" ? t("Work submitted") : t("Ready when you are")}</h2>{(item.fileName || item.submission?.fileUrl) && <p className="file-selected"><FileText size={16} />{item.fileName || item.submission?.fileUrl}</p>}<form onSubmit={submit} className="upload-form"><label className="file-picker"><Plus size={16} /><span>{file?.name || t("Choose a file")}</span><input type="file" onChange={(event) => setFile(event.target.files?.[0] || null)} /></label><small>{isBackendMode ? t("The selected file will be uploaded to the configured backend.") : t("The selected file will be uploaded when backend mode is enabled.")}</small>{submitError && <p className="form-error" role="alert">{submitError}</p>}<button className="workspace-button primary-action" disabled={!file || submitting} type="submit">{submitting ? t("Submitting…") : t("Submit assignment")}<ArrowRight size={15} /></button></form>{message && <p className="form-success" role="status">{message}</p>}</section></div></>;
}

function MaterialsPage({ materials }) {
  const { t } = useLanguage();
  const [type, setType] = useState("All"); const [formOpen, setFormOpen] = useState(false); const [added, setAdded] = useState(""); const [error, setError] = useState(""); const [saving, setSaving] = useState(false); const [localMaterials, setLocalMaterials] = useState(materials);
  const shown = localMaterials.filter((item) => type === "All" || item.type === type);
  async function add(event) { event.preventDefault(); if (saving) return; setSaving(true); setError(""); setAdded(""); const form = new FormData(event.currentTarget); try { const item = await addMaterial({ title: form.get("title"), subject: form.get("subject"), type: form.get("type"), link: form.get("link") }); setLocalMaterials((items) => [item, ...items]); setAdded(t("{{title}} was added successfully.", { title: item.title })); setFormOpen(false); } catch (cause) { setError(t(cause.message)); } finally { setSaving(false); } }
  return <><PageHeading title={t("Learning materials")} subtitle="Notes, references, and lesson resources." action={<button className="workspace-button primary-action" onClick={() => setFormOpen((open) => !open)}><Plus size={16} />{<LocalizedText text={"Add material"} />}</button>} />{formOpen && <form className="inline-create" onSubmit={add}><label>{<LocalizedText text={"Title"} />}<input required name="title" placeholder={t("Resource title")} /></label><label>{<LocalizedText text={"Subject"} />}<input required name="subject" placeholder={t("Subject")} /></label><label>{<LocalizedText text={"Resource URL"} />}<input type="url" name="link" required placeholder="https://…" /></label><label>{<LocalizedText text={"Type"} />}<select name="type"><option value={"Notes"}>{<LocalizedText text={"Notes"} />}</option><option value={"Document"}>{<LocalizedText text={"Document"} />}</option><option value={"Video"}>{<LocalizedText text={"Video"} />}</option><option value={"Image"}>{<LocalizedText text={"Image"} />}</option></select></label>{error && <p className="form-error" role="alert">{error}</p>}<button className="workspace-button primary-action" disabled={saving} type="submit">{saving ? t("Saving…") : t("Add material")}</button></form>}{added && <p className="form-success" role="status">{added}</p>}<div className="filter-bar"><div className="filter-tabs">{["All", "Notes", "Document", "Video", "Image"].map((item) => <button className={type === item ? "active" : ""} key={item} onClick={() => setType(item)}>{t(item)}</button>)}</div><span>{shown.length}{<LocalizedText text={"resources"} />}</span></div><div className="material-grid">{shown.map((item) => <article className="material-card" key={item.id}><div className={`material-preview ${item.color}`}><span>{item.type === "Video" ? <Video size={26} /> : item.type === "Image" ? <Sparkles size={26} /> : item.type === "Notes" ? <BookOpen size={26} /> : <FileText size={26} />}</span><small>{t(item.type)}</small></div><div><span className="class-subject">{localizedRecord(t, item.id, item.subject)}</span><h2>{localizedRecord(t, item.id, item.title)}</h2><p>{localizedRecord(t, item.id, item.details)}</p><button className="text-action" onClick={() => setAdded(t("{{title}} opened in the preview.", { title: item.title }))}>{<LocalizedText text={"Preview resource"} />}<ArrowUpRight size={15} /></button></div></article>)}</div></>;
}

function getInitials(name) {
  if (!name) return "ST";
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  return name.slice(0, 2).toUpperCase();
}

function StudentAttendancePredictor({ records, selectedClassLabel }) {
  const { t } = useLanguage();
  const [projectCount, setProjectCount] = useState(3);

  const totalHeld = records.length;
  const totalAttended = records.filter((r) => r.status === "Present").length;
  const currentPct = totalHeld > 0 ? (totalAttended / totalHeld) * 100 : 0;

  const n = Math.max(1, Math.min(20, Number(projectCount) || 1));
  const attendNPct = totalHeld + n > 0 ? ((totalAttended + n) / (totalHeld + n)) * 100 : 0;
  const missNPct = totalHeld + n > 0 ? (totalAttended / (totalHeld + n)) * 100 : 0;
  const deltaAttend = attendNPct - currentPct;
  const deltaMiss = missNPct - currentPct;

  const isAboveThreshold = currentPct >= 75;
  const neededConsecutive = totalHeld > 0 && !isAboveThreshold
    ? Math.max(0, Math.ceil((0.75 * totalHeld - totalAttended) / 0.25))
    : 0;
  const safeToMiss = totalHeld > 0 && isAboveThreshold
    ? Math.max(0, Math.floor((totalAttended - 0.75 * totalHeld) / 0.75))
    : 0;

  const progressFillWidth = Math.min(100, Math.max(0, currentPct));

  return (
    <section className="workspace-panel attendance-predictor" aria-labelledby="predictor-heading">
      <div className="panel-heading">
        <div>
          <span className="panel-kicker">{t("ATTENDANCE SIMULATOR & TARGET TRACKER")}</span>
          <h2 id="predictor-heading">{t("Attendance Predictor")}</h2>
        </div>
        <span className="predictor-scope-badge">
          {selectedClassLabel || t("Overall attendance")}
        </span>
      </div>

      <div className="predictor-hero-grid">
        <div className="predictor-stat-card current-stat">
          <span className="stat-label">{t("Current attendance")}</span>
          <div className="stat-value-group">
            <strong className={`stat-pct ${isAboveThreshold ? "on-track" : "deficit"}`}>
              {totalHeld > 0 ? `${currentPct.toFixed(1)}%` : "—"}
            </strong>
            <span className={`status-badge-inline ${isAboveThreshold ? "on-track" : "deficit"}`}>
              {isAboveThreshold ? t("Attendance on track") : t("Attendance deficit")}
            </span>
          </div>
          <span className="stat-subtext">
            {t("{{attended}} of {{total}} classes attended", { attended: totalAttended, total: totalHeld })}
          </span>
        </div>

        <div className="predictor-progress-container">
          <div className="progress-label-row">
            <span>{t("Progress toward required threshold")}</span>
            <span className="target-pill">{t("Target: 75%")}</span>
          </div>
          <div className="predictor-bar-track" role="progressbar" aria-valuenow={Math.round(currentPct)} aria-valuemin="0" aria-valuemax="100">
            <div
              className={`predictor-bar-fill ${isAboveThreshold ? "emerald" : "amber"}`}
              style={{ width: `${progressFillWidth}%` }}
            />
            <div className="target-marker" style={{ left: "75%" }} title="75% target threshold">
              <span className="target-marker-flag">75%</span>
            </div>
          </div>
          <div className="progress-scale-labels">
            <span>0%</span>
            <span>50%</span>
            <span className="scale-target">75%</span>
            <span>100%</span>
          </div>
        </div>
      </div>

      <div className="predictor-controls-panel">
        <div className="predictor-sim-control">
          <label htmlFor="n-slider" className="sim-control-label">
            <span>{t("Upcoming classes to project (N)")}</span>
            <span className="n-counter-badge">{n} {n === 1 ? "class" : "classes"}</span>
          </label>
          <div className="stepper-slider-group">
            <button
              type="button"
              className="stepper-btn"
              disabled={n <= 1}
              onClick={() => setProjectCount((c) => Math.max(1, c - 1))}
              aria-label="Decrease class projection by 1"
            >
              <Minus size={16} />
            </button>
            <input
              id="n-slider"
              type="range"
              min="1"
              max="20"
              value={n}
              onChange={(e) => setProjectCount(Number(e.target.value))}
              className="n-slider"
              aria-label="Upcoming classes to project"
            />
            <button
              type="button"
              className="stepper-btn"
              disabled={n >= 20}
              onClick={() => setProjectCount((c) => Math.min(20, c + 1))}
              aria-label="Increase class projection by 1"
            >
              <Plus size={16} />
            </button>
          </div>
        </div>

        <div className="projections-dual-grid">
          <div className="projection-card attend-card">
            <div className="proj-header">
              <TrendingUp size={20} className="proj-icon positive" />
              <span>{t("If you attend next {{count}} classes", { count: n })}</span>
            </div>
            <div className="proj-value-row">
              <strong className="proj-pct">{totalHeld + n > 0 ? `${attendNPct.toFixed(1)}%` : "—"}</strong>
              <span className="proj-delta positive">
                {deltaAttend >= 0 ? `+${deltaAttend.toFixed(1)}%` : `${deltaAttend.toFixed(1)}%`}
              </span>
            </div>
            <small className="proj-note">
              {t("{{attended}} of {{total}} classes", { attended: totalAttended + n, total: totalHeld + n })}
            </small>
          </div>

          <div className="projection-card miss-card">
            <div className="proj-header">
              <TrendingDown size={20} className="proj-icon negative" />
              <span>{t("If you miss next {{count}} classes", { count: n })}</span>
            </div>
            <div className="proj-value-row">
              <strong className="proj-pct">{totalHeld + n > 0 ? `${missNPct.toFixed(1)}%` : "—"}</strong>
              <span className="proj-delta negative">
                {deltaMiss.toFixed(1)}%
              </span>
            </div>
            <small className="proj-note">
              {t("{{attended}} of {{total}} classes", { attended: totalAttended, total: totalHeld + n })}
            </small>
          </div>
        </div>
      </div>

      <div className={`threshold-tracker-banner ${totalHeld === 0 ? "neutral" : isAboveThreshold ? "positive" : "warning"}`}>
        <div className="tracker-banner-icon">
          {totalHeld === 0 ? <AlertCircle size={22} /> : isAboveThreshold ? <CheckCircle2 size={22} /> : <AlertCircle size={22} />}
        </div>
        <div className="tracker-banner-content">
          <h4>
            {totalHeld === 0
              ? t("No attendance sessions recorded yet")
              : isAboveThreshold
                ? t("Attendance requirement satisfied (>= 75%)")
                : t("Attendance recovery needed (< 75%)")}
          </h4>
          <p>
            {totalHeld === 0
              ? t("Attend your upcoming scheduled classes to establish your attendance record.")
              : isAboveThreshold
                ? (safeToMiss > 0
                    ? t("You have a positive attendance cushion. You can safely miss up to {{count}} class(es) while remaining at or above the 75% requirement.", { count: safeToMiss })
                    : t("You are currently at the 75% boundary. Attend upcoming classes to build a safe attendance cushion."))
                : t("You must attend the next {{count}} consecutive class(es) without absence to reach the 75% minimum threshold.", { count: neededConsecutive })}
          </p>
        </div>
        {totalHeld > 0 && (
          <div className="tracker-metric-pill">
            <span className="metric-num">
              {isAboveThreshold ? safeToMiss : neededConsecutive}
            </span>
            <span className="metric-tag">
              {isAboveThreshold ? t("Classes you can miss") : t("Consecutive classes needed for 75%")}
            </span>
          </div>
        )}
      </div>
    </section>
  );
}

function StudentAttendanceView({ records, user }) {
  const formatDate = useLocalizedDate();
  const { t } = useLanguage();
  const storageKey = profileStorageKey(user, "attendance");
  const studentRecords = useMemo(() => {
    return records.filter((item) =>
      [item.studentId, item.userId, item.student?.id, item.student?.email].some(
        (id) => id && [user.id, user.email, "STU-1001"].includes(id)
      )
    );
  }, [records, user]);

  const [local] = useState(() => readLocalValue(storageKey, studentRecords));
  const [date, setDate] = useState(() => dateKey(new Date()));
  const [classFilter, setClassFilter] = useState("all");

  const classes = useMemo(() => {
    return [...new Set(local.map((item) => item.className).filter(Boolean))];
  }, [local]);

  const predictorRecords = useMemo(() => {
    if (classFilter === "all") return local;
    return local.filter((r) => r.className === classFilter || r.classId === classFilter);
  }, [local, classFilter]);

  const visible = useMemo(() => {
    return local.filter(
      (item) => item.date === date && (classFilter === "all" || item.className === classFilter || item.classId === classFilter)
    );
  }, [local, date, classFilter]);

  const summary = useMemo(() => {
    return ["Present", "Absent", "Late", "Excused"].map((status) => [
      status,
      visible.filter((item) => item.status === status).length,
    ]);
  }, [visible]);

  return (
    <>
      <PageHeading
        title={t("Attendance")}
        subtitle="Review your attendance records, track progress, and project upcoming class standing."
      />
      <PreviewNotice>
        {t("Only records associated with this signed-in student are shown. Attendance data is unavailable if the service has not linked any records to this account.")}
      </PreviewNotice>
      <div className="attendance-filters">
        <label>
          {t("Date")}
          <input type="date" value={date} onChange={(event) => setDate(event.target.value)} />
        </label>
        <label>
          {t("Class")}
          <select value={classFilter} onChange={(event) => setClassFilter(event.target.value)}>
            <option value="all">{t("All available classes")}</option>
            {classes.map((name) => (
              <option key={name} value={name}>{name}</option>
            ))}
          </select>
        </label>
      </div>

      <div className="overview-strip attendance-overview">
        {summary.map(([status, count]) => (
          <div key={status}>
            <span>{t(status)}</span>
            <strong>{count}</strong>
            <small>{t("On selected date")}</small>
          </div>
        ))}
      </div>

      <StudentAttendancePredictor
        records={predictorRecords}
        selectedClassLabel={classFilter === "all" ? t("Overall attendance") : classFilter}
      />

      <section className="workspace-panel attendance-table">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">{t("DATE-BASED RECORDS")}</span>
            <h2>{t("Attendance history")}</h2>
          </div>
        </div>
        {visible.length ? (
          visible.map((item) => (
            <div className="attendance-row" key={item.id}>
              <span className="attendance-date">
                {formatDate(item.date, { day: "numeric", month: "short", year: "numeric" })}
              </span>
              <strong>{item.className ? localizedRecord(t, item.id, item.className) : item.studentName}</strong>
              <span className={`status-pill ${String(item.status).toLowerCase()}`}>{t(item.status)}</span>
            </div>
          ))
        ) : (
          <EmptyState
            icon={ClipboardCheck}
            title="No attendance records for this date"
            description="Choose another date or class to review available records."
          />
        )}
      </section>
    </>
  );
}

function TeacherAttendanceRoster({ classes = [], setNotice }) {
  const { t } = useLanguage();
  const formatDate = useLocalizedDate();

  const classList = useMemo(() => {
    if (classes && classes.length) return classes;
    return [
      { id: "biology-10", name: "Biology · Cell structures" },
      { id: "math-10", name: "Mathematics · Algebra" },
      { id: "history-10", name: "World History · 1900s" },
    ];
  }, [classes]);

  const [selectedClassId, setSelectedClassId] = useState(() => classList[0]?.id || "biology-10");
  const [date, setDate] = useState(() => dateKey(new Date()));
  const [search, setSearch] = useState("");
  const currentKey = `${selectedClassId}_${date}`;
  const [loadedKey, setLoadedKey] = useState("");
  const loading = loadedKey !== currentKey;
  const [saving, setSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState(null);
  const [confirmAll, setConfirmAll] = useState(false);
  const [students, setStudents] = useState([]);
  const [rosterStatus, setRosterStatus] = useState({});
  const [currentClassName, setCurrentClassName] = useState("");

  const selectedClass = classList.find((c) => c.id === selectedClassId || c.name === selectedClassId) || classList[0];

  useEffect(() => {
    let active = true;

    getClassRosterAttendance(selectedClassId, date)
      .then((result) => {
        if (!active) return;
        const enrolled = result.students || [];
        const records = result.records || [];
        setStudents(enrolled);
        setCurrentClassName(result.className || selectedClass?.name || selectedClassId);

        const statusMap = {};
        enrolled.forEach((student) => {
          const matchingRecord = records.find(
            (r) => r.studentId === student.id || r.userId === student.id || (student.email && r.student?.email === student.email)
          );
          if (matchingRecord) {
            statusMap[student.id] = matchingRecord.status;
          } else {
            statusMap[student.id] = "";
          }
        });
        setRosterStatus(statusMap);
        setLoadedKey(currentKey);
      })
      .catch((err) => {
        if (!active) return;
        setSaveStatus({ text: err.message || "Failed to load class roster.", type: "error" });
        setLoadedKey(currentKey);
      });

    return () => { active = false; };
  }, [selectedClassId, date, currentKey, selectedClass?.name]);

  const filteredStudents = useMemo(() => {
    if (!search.trim()) return students;
    const q = search.toLowerCase();
    return students.filter(
      (s) => s.name?.toLowerCase().includes(q) || s.id?.toLowerCase().includes(q) || s.email?.toLowerCase().includes(q)
    );
  }, [students, search]);

  const summary = useMemo(() => {
    let present = 0;
    let absent = 0;
    let late = 0;
    let excused = 0;
    students.forEach((s) => {
      const st = rosterStatus[s.id];
      if (st === "Present") present++;
      else if (st === "Absent") absent++;
      else if (st === "Late") late++;
      else if (st === "Excused") excused++;
    });
    return [
      ["Present", present],
      ["Absent", absent],
      ["Late", late],
      ["Excused", excused],
    ];
  }, [students, rosterStatus]);

  function handleSetStatus(studentId, newStatus) {
    setRosterStatus((prev) => ({
      ...prev,
      [studentId]: newStatus,
    }));
    setSaveStatus(null);
  }

  function handleMarkAllPresent() {
    setRosterStatus((prev) => {
      const next = { ...prev };
      filteredStudents.forEach((student) => {
        next[student.id] = "Present";
      });
      return next;
    });
    setConfirmAll(false);
    setSaveStatus(null);
  }

  async function handleSaveRoster() {
    setSaving(true);
    setSaveStatus(null);

    const recordsToSave = students
      .filter((s) => rosterStatus[s.id])
      .map((s) => ({
        studentId: s.id,
        studentName: s.name,
        status: rosterStatus[s.id],
      }));

    try {
      await saveClassAttendance(selectedClassId, date, recordsToSave);
      setSaveStatus({ text: t("Attendance saved successfully."), type: "success" });
      if (setNotice) setNotice(t("Attendance saved successfully."));
    } catch (err) {
      setSaveStatus({
        text: t(err.message || "Could not save attendance. Please try again."),
        type: "error",
      });
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
      <PageHeading
        title={t("Attendance")}
        subtitle="Review and record student attendance by class and date."
        action={
          <button
            className="workspace-button primary-action"
            type="button"
            onClick={handleSaveRoster}
            disabled={saving || loading}
          >
            <Check size={16} />
            {saving ? t("Saving…") : t("Save changes")}
          </button>
        }
      />
      <PreviewNotice>
        {t(isBackendMode
          ? "Attendance updates are synced with the backend service for enrolled students."
          : "These are preview attendance records. Changes are stored in this browser only.")}
      </PreviewNotice>

      {saveStatus && (
        <p className={saveStatus.type === "success" ? "form-success" : "form-error"} role="status">
          {saveStatus.text}
        </p>
      )}

      <div className="attendance-filters">
        <label>
          {t("Date")}
          <input type="date" value={date} onChange={(e) => setDate(e.target.value)} />
        </label>
        <label>
          {t("Class")}
          <select value={selectedClassId} onChange={(e) => setSelectedClassId(e.target.value)}>
            {classList.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
        </label>
        <label>
          {t("Search records")}
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t("Search by student name or ID…")}
          />
        </label>
      </div>

      <div className="overview-strip attendance-overview">
        {summary.map(([status, count]) => (
          <div key={status}>
            <span>{t(status)}</span>
            <strong>{count}</strong>
            <small>{t("On selected date")}</small>
          </div>
        ))}
      </div>

      <section className="workspace-panel attendance-table">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">{t("CLASS ATTENDANCE ROSTER")}</span>
            <h2>{currentClassName || selectedClass?.name || t("Class attendance roster")}</h2>
          </div>
          <button
            className="workspace-button"
            type="button"
            onClick={() => setConfirmAll(true)}
            disabled={loading || !filteredStudents.length}
          >
            {t("Mark all present")}
          </button>
        </div>

        {loading ? (
          <div className="roster-loading-state">
            <span className="spinner" />
            <p>{t("Loading class attendance roster…")}</p>
          </div>
        ) : !students.length ? (
          <EmptyState
            icon={Users}
            title={t("No enrolled students in this class")}
            description={t("Students enrolled in this class will appear here.")}
          />
        ) : !filteredStudents.length ? (
          <EmptyState
            icon={Search}
            title={t("No students match your search")}
            description={t("Try searching with a different name or student ID.")}
          />
        ) : (
          <div className="roster-list" role="list" aria-label="Student roster">
            {filteredStudents.map((student) => {
              const currentStatus = rosterStatus[student.id];
              const isPresent = currentStatus === "Present";
              const isAbsent = currentStatus === "Absent";
              const isOther = currentStatus && !isPresent && !isAbsent;

              return (
                <div className="attendance-roster-row" key={student.id} role="listitem">
                  <div className="roster-student-info">
                    <div className="student-avatar-badge" aria-hidden="true">
                      {student.avatar || getInitials(student.name)}
                    </div>
                    <div className="student-details">
                      <strong className="student-name">{student.name}</strong>
                      <span className="student-id-tag">{student.id}</span>
                    </div>
                  </div>

                  <div className="roster-status-col">
                    {isOther && (
                      <span className={`status-pill ${currentStatus.toLowerCase()}`}>
                        {t(currentStatus)}
                      </span>
                    )}

                    <div
                      className="pa-toggle"
                      role="group"
                      aria-label={t("Attendance status for {{name}}", { name: student.name })}
                    >
                      <button
                        type="button"
                        className={`pa-btn pa-present ${isPresent ? "active" : ""}`}
                        aria-pressed={isPresent}
                        aria-label={t("Mark {{name}} Present", { name: student.name })}
                        onClick={() => handleSetStatus(student.id, "Present")}
                      >
                        P
                      </button>
                      <button
                        type="button"
                        className={`pa-btn pa-absent ${isAbsent ? "active" : ""}`}
                        aria-pressed={isAbsent}
                        aria-label={t("Mark {{name}} Absent", { name: student.name })}
                        onClick={() => handleSetStatus(student.id, "Absent")}
                      >
                        A
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      {confirmAll && (
        <div className="modal-backdrop" role="presentation">
          <section className="confirm-modal" role="dialog" aria-modal="true" aria-labelledby="mark-present-title">
            <h2 id="mark-present-title">
              {t("Mark {{count}} students present for {{date}}?", {
                count: filteredStudents.length,
                date: formatDate(date, { day: "numeric", month: "short", year: "numeric" }),
              })}
            </h2>
            <p>{t("This will update any absent or unmarked students in the listed roster.")}</p>
            <div>
              <button className="workspace-button" type="button" onClick={() => setConfirmAll(false)}>
                {t("Cancel")}
              </button>
              <button className="workspace-button primary-action" type="button" onClick={handleMarkAllPresent}>
                {t("Apply to listed records")}
              </button>
            </div>
          </section>
        </div>
      )}
    </>
  );
}

function AttendancePage({ records = [], classes = [], user, setNotice }) {
  const teacher = user.role === "teacher";
  if (teacher) {
    return <TeacherAttendanceRoster classes={classes} user={user} setNotice={setNotice} />;
  }
  return <StudentAttendanceView records={records} user={user} setNotice={setNotice} />;
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

function SchedulePage({ events, mode, user, setNotice }) {
  const { t, language } = useLanguage();
  const formatDate = useLocalizedDate();
  const formatNumber = useLocalizedNumber();
  const [selected, setSelected] = useState(() => dateKey(new Date()));
  const [calendarData, setCalendarData] = useState(() => ({ month: dateKey(new Date()).slice(0, 7), items: events }));
  const notesKey = profileStorageKey(user, "calendar-notes");
  const [notes, setNotes] = useState(() => readLocalValue(notesKey, []));
  const [noteForm, setNoteForm] = useState(null);
  const [noteError, setNoteError] = useState("");
  const firstMonth = useRef(selected.slice(0, 7));
  const monthKey = selected.slice(0, 7);
  const calendarEvents = calendarData.month === monthKey ? calendarData.items : [];
  useEffect(() => {
    if (firstMonth.current === monthKey) {
      firstMonth.current = "";
      return;
    }
    let active = true;
    listCalendarMonth(monthKey).then((items) => {
      if (active) setCalendarData({ month: monthKey, items });
    }).catch((cause) => {
      if (active) {
        setCalendarData({ month: monthKey, items: [] });
        setNotice(t(cause.message || "Calendar events could not be loaded."));
      }
    });
    return () => { active = false; };
  }, [monthKey, setNotice, t]);
  const selectedDate = parseDateKey(selected);
  const locale = language === "hi" ? "hi-IN" : "en-IN";
  const weekdayKeys = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const weekStart = startOfMondayWeek(selectedDate);
  const weekDates = Array.from({ length: 7 }, (_, index) => addDays(weekStart, index));
  const monthStart = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1, 12);
  const monthFirstDayOffset = (monthStart.getDay() + 6) % 7;
  const monthCells = Array.from({ length: 42 }, (_, index) => addDays(monthStart, index - monthFirstDayOffset));
  const monthLabel = new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }).format(selectedDate);
  const visible = [...calendarEvents, ...notes].filter((item) => item.date === selected);
  const allMonthEvents = [...calendarEvents, ...notes].filter((item) => item.date?.startsWith(monthKey));

  function saveNote(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const title = String(form.get("title") || "").trim();
    if (!title) { setNoteError(t("Add a title for this calendar entry.")); return; }
    const category = String(form.get("category") || "note");
    const id = noteForm?.id || `local-${Date.now()}`;
    const next = noteForm?.id
      ? notes.map((item) => item.id === id ? { ...item, title, details: String(form.get("details") || "").trim(), date: String(form.get("date")), type: category, time: "" } : item)
      : [...notes, { id, title, details: String(form.get("details") || "").trim(), date: String(form.get("date")), type: category, time: "" }];
    if (!writeLocalValue(notesKey, next)) { setNoteError(t("Could not save this entry in browser storage.")); return; }
    setNotes(next); setSelected(String(form.get("date"))); setNoteForm(null); setNoteError("");
    setNotice(t("Calendar entry saved in this browser only."));
  }
  function removeNote(id) {
    const next = notes.filter((item) => item.id !== id);
    if (writeLocalValue(notesKey, next)) { setNotes(next); setNotice(t("Calendar entry removed from this browser.")); }
  }

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
              const dayEvents = allMonthEvents.filter((event) => event.date === key);
              const hasRed = dayEvents.some((event) => ["holiday", "festival"].includes(event.type));
              return <button
                key={key}
                type="button"
                className={`${selected === key ? "selected" : ""}${inMonth ? "" : " outside-month"}`}
                aria-pressed={selected === key}
                aria-label={formatDate(key, { weekday: "long", day: "numeric", month: "long", year: "numeric" })}
                onClick={() => setSelected(key)}
              >
                {formatNumber(dayDate.getDate())}
                {dayEvents.length > 0 && <i className={hasRed ? "calendar-dot red" : "calendar-dot"} aria-hidden="true" />}
              </button>;
            })}
          </div>
        </>}
        <div className="panel-heading schedule-day-heading">
          <h2>{t(mode === "week" ? "Schedule · {{date}}" : "Events · {{date}}", { date: formatDate(selected, { day: "numeric", month: "short", year: "numeric" }) })}</h2>
          <span>{formatNumber(visible.length)} {t("items")}</span>
        </div>
        <div className="calendar-legend"><span><i className="legend-dot class-dot" />{t("Classes and meetings")}</span><span><i className="legend-dot red" />{t("Holidays and festivals")}</span><span><i className="legend-dot note-dot" />{t("Personal notes")}</span></div>
        {visible.length ? visible.map((event) => {
          const localNote = notes.some((item) => item.id === event.id);
          return <div className={`event-row ${["holiday", "festival"].includes(event.type) ? "red-event" : ""}`} key={event.id}>
            <span className="event-time">{event.time || ""}</span>
            <span className={`event-mark ${String(event.type).toLowerCase()}`} />
            <span className="event-copy"><strong>{localizedRecord(t, event.id, event.title)}</strong><small>{t(event.type)}{event.details ? ` · ${event.details}` : event.location ? ` · ${localizedRecord(t, event.id, event.location)}` : ""}</small></span>
            {localNote ? <span className="note-actions"><button className="icon-button" type="button" aria-label={t("Edit {{title}}", { title: event.title })} onClick={() => { setNoteForm(event); setNoteError(""); }}><Pencil size={14} /></button><button className="icon-button" type="button" aria-label={t("Delete {{title}}", { title: event.title })} onClick={() => removeNote(event.id)}><Trash2 size={14} /></button></span> : <Link className="icon-button" to={event.type === "Class" ? `/app/classroom/${event.id}` : event.type === "Deadline" ? "/app/assignments" : "/app/classes"} aria-label={t("Details for {{title}}", { title: localizedRecord(t, event.id, event.title) })}><ArrowUpRight size={15} /></Link>}
          </div>;
        }) : <EmptyState icon={CalendarDays} title="No events on this date" description="Choose another date or add a personal calendar entry." />}
      </section>
      <aside className="workspace-panel calendar-aside">
        <span className="panel-kicker"><LocalizedText text={"UPCOMING"} /></span>
        <h2><LocalizedText text={"Coming up"} /></h2>
        {allMonthEvents.slice(0, 6).map((event) => <button className={`upcoming-row ${["holiday", "festival"].includes(event.type) ? "red-event" : ""}`} type="button" key={event.id} onClick={() => setSelected(event.date)}>
          <span>{formatNumber(Number(event.date.slice(-2)))}</span>
          <span><strong>{localizedRecord(t, event.id, event.title)}</strong><small>{event.time ? `${event.time} · ` : ""}{t(event.type)}</small></span>
        </button>)}
        {!allMonthEvents.length && <p className="dashboard-empty-copy">{t("No upcoming items are recorded for this month.")}</p>}
        <button className="workspace-button primary-action calendar-add-note" type="button" onClick={() => { setNoteForm({ date: selected, type: "note" }); setNoteError(""); }}><Plus size={15} />{t("Add to selected date")}</button>
        <PreviewNotice>{t("Personal calendar entries are stored in this browser only. No holiday schedule is preloaded; add dates verified for your college.")}</PreviewNotice>
      </aside>
    </div>
    {noteForm && <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setNoteForm(null); }}><section className="confirm-modal calendar-note-modal" role="dialog" aria-modal="true" aria-labelledby="calendar-note-title"><button className="modal-close" type="button" onClick={() => setNoteForm(null)} aria-label={t("Close")}><X size={17} /></button><h2 id="calendar-note-title">{t(noteForm.id ? "Edit calendar entry" : "Add calendar entry")}</h2><form className="workspace-form" onSubmit={saveNote}><label>{t("Title")}<input name="title" required maxLength={100} defaultValue={noteForm.title || ""} autoFocus /></label><label>{t("Date")}<input name="date" type="date" required defaultValue={noteForm.date || selected} /></label><label>{t("Category")}<select name="category" defaultValue={noteForm.type || "note"}><option value="note">{t("Personal note")}</option><option value="holiday">{t("Academic holiday")}</option><option value="festival">{t("Festival or celebration")}</option></select></label><label>{t("Details (optional)")}<textarea name="details" maxLength={1000} defaultValue={noteForm.details || ""} /></label>{noteError && <p className="form-error" role="alert">{noteError}</p>}<div className="calendar-note-actions"><button className="workspace-button" type="button" onClick={() => setNoteForm(null)}>{t("Cancel")}</button><button className="workspace-button primary-action" type="submit">{t("Save in this browser")}</button></div></form></section></div>}
  </>;
}

function ChatPage({ initialMessages, setNotice }) {
  const { t } = useLanguage();
  const [messages, setMessages] = useState(initialMessages); const [text, setText] = useState(""); const [warning, setWarning] = useState("");
  async function send(event) { event.preventDefault(); if (!text.trim()) return; const check = await checkMessage(text); if (check.flagged) { setWarning(t(check.reason)); return; } const item = await sendLocalMessage(text.trim()); setMessages((items) => [...items, item]); setText(""); setWarning(""); setNotice(t("Message added to this browser only; it was not delivered to classmates.")); }
  return <><PageHeading title={t("Class chat")} subtitle="A local conversation preview for class discussions." /><div className="chat-layout"><aside className="chat-conversations"><span className="panel-kicker">{<LocalizedText text={"CONVERSATIONS"} />}</span><button className="conversation-item selected"><span className="conversation-avatar">{<LocalizedText text={"B"} />}</span><span><strong>{<LocalizedText text={"Biology · Cell structures"} />}</strong><small>{<LocalizedText text={"Ms. Rivera · Class group"} />}</small></span><i /></button><button className="conversation-item"><span className="conversation-avatar mint">{<LocalizedText text={"M"} />}</span><span><strong>{<LocalizedText text={"Mathematics · Algebra"} />}</strong><small>{<LocalizedText text={"Mr. Chen · Class group"} />}</small></span></button></aside><section className="chat-room"><div className="chat-room-heading"><span className="conversation-avatar">{<LocalizedText text={"B"} />}</span><span><strong>{<LocalizedText text={"Biology · Cell structures"} />}</strong><small>{<LocalizedText text={"Preview conversation · not live"} />}</small></span><Users size={17} /></div><div className="chat-messages">{messages.map((item) => <article className={`chat-message ${item.mine ? "mine" : ""}`} key={item.id}><span className="chat-author">{localizedRecord(t, item.id, item.author)} <time>{item.time}</time></span><p>{localizedRecord(t, item.id, item.text)}</p></article>)}</div><form className="chat-composer" onSubmit={send}>{warning && <p className="form-error"><ShieldAlert size={15} />{warning}{<LocalizedText text={"Message was not added."} />}</p>}<label htmlFor="chat-message">{<LocalizedText text={"Message the preview conversation"} />}</label><div><input id="chat-message" value={text} onChange={(event) => setText(event.target.value)} placeholder={t("Write a message…")} /><button type="submit" aria-label={t("Add message locally")} disabled={!text.trim()}><ArrowRight size={17} /></button></div><small>{<LocalizedText text={"Preview spam review only. No message is sent to another person."} />}</small></form></section></div></>;
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
  const [filter, setFilter] = useState("All"); const [category, setCategory] = useState("All categories"); const [error, setError] = useState(""); const [busy, setBusy] = useState(false);
  const shown = items.filter((item) => (filter === "All" || (filter === "Unread" ? item.unread : !item.unread)) && (category === "All categories" || item.category === category));
  async function updateReadState(operation) { if (busy) return; setBusy(true); setError(""); try { const notifications = await operation(); setData({ ...allData, notifications }); } catch (cause) { setError(t(cause.message)); } finally { setBusy(false); } }
  return <><PageHeading title={t("Notifications")} subtitle="Important updates from your learning space." action={<button className="workspace-button" disabled={busy} onClick={() => updateReadState(markAllNotificationsRead)}><Check size={16} />{<LocalizedText text={"Mark all read"} />}</button>} />{error && <p className="form-error" role="alert">{error}</p>}<div className="filter-bar"><div className="filter-tabs">{["All", "Unread", "Read"].map((item) => <button key={item} className={filter === item ? "active" : ""} onClick={() => setFilter(item)}>{t(item)}</button>)}</div><select value={category} onChange={(event) => setCategory(event.target.value)} aria-label={t("Notification category")}><option value={"All categories"}>{<LocalizedText text={"All categories"} />}</option><option value={"Classes"}>{<LocalizedText text={"Classes"} />}</option><option value={"Assignments"}>{<LocalizedText text={"Assignments"} />}</option></select></div><div className="notification-list">{shown.map((item) => <article className={`notification-row ${item.unread ? "unread" : ""}`} key={item.id}><span className="notification-icon"><Bell size={17} /></span><div><span className="notification-category">{t(item.category)}</span><strong>{localizedRecord(t, item.id, item.title)}</strong><p>{localizedRecord(t, item.id, item.body)}</p><Link to={item.href}>{<LocalizedText text={"Open related page"} />}<ArrowRight size={14} /></Link></div>{item.unread && <button className="icon-button" disabled={busy} aria-label={t("Mark {{title}} as read", { title: localizedRecord(t, item.id, item.title) })} onClick={() => updateReadState(() => markNotificationRead(item.id))}><Check size={16} /></button>}</article>)}</div></>;
}

function MentorPage() {
  const { t } = useLanguage();
  const previewGreeting = { role: "mentor", textKey: "Hi Alex. I’m your AI Mentor preview. What are you working through today?" };
  const [messages, setMessages] = useState(() => isBackendMode ? [] : [previewGreeting]); const [text, setText] = useState(""); const [loading, setLoading] = useState(false); const [error, setError] = useState("");
  async function ask(prompt) { const question = prompt || text; if (!question.trim() || loading) return; setMessages((items) => [...items, { role: "you", text: question }]); setText(""); setLoading(true); setError(""); try { const response = await askMentor(question); setMessages((items) => [...items, { role: "mentor", ...(response.text ? { text: response.text } : response) }]); } catch (cause) { setError(cause.message); } finally { setLoading(false); } }
  function clear() { setMessages(isBackendMode ? [] : [previewGreeting]); setText(""); setError(""); }
  return <><PageHeading title={t("AI Mentor")} subtitle={isBackendMode ? "Study questions are sent to the configured ML service." : "A guided study conversation, powered by a predictable preview responder."} action={<button className="workspace-button" onClick={clear}>{<LocalizedText text={"Clear conversation"} />}</button>} /><div className="mentor-workspace"><div className="mentor-head"><span><Bot size={20} /></span><div><strong>{<LocalizedText text={"Your learning companion"} />}</strong><small>{isBackendMode ? "ML service" : <LocalizedText text={"Preview responses · no AI service connected"} />}</small></div><i>{isBackendMode ? "API" : <LocalizedText text={"PREVIEW"} />}</i></div><div className="mentor-thread">{messages.map((item, index) => <article key={`${item.role}-${index}`} className={`mentor-message ${item.role}`}><span>{item.role === "you" ? t("You") : t(isBackendMode ? "AI Mentor" : "AI Mentor · preview")}</span><p>{item.role === "mentor" && item.textKey ? t(item.textKey) : item.role === "mentor" && item.responseKey ? t(item.responseKey, { subject: t(item.subjectKey) }) : item.text}</p></article>)}{loading && <p className="loading-response">{<LocalizedText text={isBackendMode ? "Waiting for the ML service…" : "Thinking through a preview response…"} />}</p>}{error && <p className="form-error" role="alert">{error}</p>}</div><div className="prompt-chips"><button onClick={() => ask(t("Explain cell structures"))}>{<LocalizedText text={"Explain cell structures"} />}</button><button onClick={() => ask(t("Plan my algebra practice"))}>{<LocalizedText text={"Plan my algebra practice"} />}</button><button onClick={() => ask(t("Prepare for a quiz"))}>{<LocalizedText text={"Prepare for a quiz"} />}</button></div><form className="mentor-composer" onSubmit={(event) => { event.preventDefault(); ask(); }}><input value={text} onChange={(event) => setText(event.target.value)} placeholder={t(isBackendMode ? "Ask the AI Mentor…" : "Ask a study question…")} aria-label={t(isBackendMode ? "Ask the AI Mentor" : "Ask the preview mentor")} /><button type="submit" disabled={!text.trim() || loading} aria-label={t("Send question")}><ArrowRight size={18} /></button></form></div></>;
}

function QuizPage() {
  const { t } = useLanguage();
  const [topic, setTopic] = useState("Cell structures"); const [lessonNotes, setLessonNotes] = useState(""); const [count, setCount] = useState("3"); const [difficulty, setDifficulty] = useState("Getting started"); const [questions, setQuestions] = useState([]); const [answers, setAnswers] = useState({}); const [submitted, setSubmitted] = useState(false); const [error, setError] = useState("");
  async function generate(event) { event.preventDefault(); setError(""); try { const result = await generateQuiz({ count, topic, text: lessonNotes, difficulty: difficulty === "Getting started" ? "easy" : difficulty === "Challenge" ? "hard" : "medium" }); setQuestions(result.questions); setAnswers({}); setSubmitted(false); } catch (cause) { setError(cause.message); } }
  const score = questions.reduce((total, item, index) => total + (answers[index] === item.answer ? 1 : 0), 0);
  return <><PageHeading title={t("Quiz Generator")} subtitle={isBackendMode ? "Generate questions from your lesson notes using the ML service." : "Build a short practice round from the sample question set."} /><form className="quiz-setup" onSubmit={generate}>{isBackendMode ? <label>{<LocalizedText text={"Lesson notes"} />}<textarea value={lessonNotes} onChange={(event) => setLessonNotes(event.target.value)} maxLength={30000} required placeholder={t("Paste lesson notes to generate questions")} /></label> : <label>{<LocalizedText text={"Topic"} />}<input value={topic === "Cell structures" ? t("Cell structures") : topic} onChange={(event) => setTopic(event.target.value === t("Cell structures") ? "Cell structures" : event.target.value)} required /></label>}<label>{<LocalizedText text={"Difficulty"} />}<select value={difficulty} onChange={(event) => setDifficulty(event.target.value)}><option value={"Getting started"}>{<LocalizedText text={"Getting started"} />}</option><option value={"Steady practice"}>{<LocalizedText text={"Steady practice"} />}</option><option value={"Challenge"}>{<LocalizedText text={"Challenge"} />}</option></select></label><label>{<LocalizedText text={"Questions"} />}<select value={count} onChange={(event) => setCount(event.target.value)}><option value="1">{<LocalizedText text={"1 question"} />}</option><option value="2">{<LocalizedText text={"2 questions"} />}</option><option value="3">{<LocalizedText text={"3 questions"} />}</option></select></label><button className="workspace-button primary-action" type="submit"><Sparkles size={16} />{<LocalizedText text={isBackendMode ? "Generate quiz" : "Create preview quiz"} />}</button></form>{error && <p className="form-error" role="alert">{error}</p>}{!isBackendMode && <PreviewNotice>{<LocalizedText text={"Question content is predefined sample data, not generated by a model."} />}</PreviewNotice>}{questions.length > 0 && <section className="quiz-content"><div className="quiz-title"><span className="panel-kicker">{isBackendMode ? t("Generated from lesson notes") : topic}{<LocalizedText text={"·"} />}{t(difficulty)}</span><h2>{<LocalizedText text={"Practice round"} />}</h2></div>{questions.map((item, index) => <fieldset className="quiz-question" key={item.prompt}><legend><span>{<LocalizedText text={"QUESTION"} />}{index + 1}</span>{t(item.prompt)}</legend>{item.options.map((option, optionIndex) => <label key={option}><input type="radio" name={`question-${index}`} checked={answers[index] === optionIndex} onChange={() => setAnswers({ ...answers, [index]: optionIndex })} />{t(option)}{submitted && optionIndex === item.answer && <Check size={15} />}</label>)}</fieldset>)}{submitted ? <div className="quiz-result"><strong>{score}{<LocalizedText text={"/"} />}{questions.length}</strong><span>{score === questions.length ? t("Excellent work.") : t("Review the answers and give it another try.")}</span><button className="workspace-button" onClick={generate}>{<LocalizedText text={"Try again"} />}</button></div> : <button className="workspace-button primary-action" disabled={Object.keys(answers).length !== questions.length} onClick={() => setSubmitted(true)}>{<LocalizedText text={"Check answers"} />}<Check size={16} /></button>}</section>}</>;
}

function Classroom({ path, user, classes }) {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const cameraStream = useRef(null);
  const micStream = useRef(null);
  const screenStream = useRef(null);
  const videoRef = useRef(null);
  const screenVideoRef = useRef(null);
  const [camera, setCamera] = useState(false);
  const [mic, setMic] = useState(false);
  const [screenSharing, setScreenSharing] = useState(false);
  const [hand, setHand] = useState(false);
  const [reactionsOpen, setReactionsOpen] = useState(false);
  const [reaction, setReaction] = useState("");
  const [flyingReactions, setFlyingReactions] = useState([]);
  const [panel, setPanel] = useState("people");
  const [chatText, setChatText] = useState("");
  const [chatError, setChatError] = useState("");
  const initialClassId = path.split("/classroom/")[1]?.split("/")[0] || "biology-10";
  const [chatMessages, setChatMessages] = useState(() => readLocalValue(meetingStorageKey(initialClassId, "chat"), []));
  const [polls, setPolls] = useState(() => readLocalValue(meetingStorageKey(initialClassId, "polls"), []));
  const [pollQuestion, setPollQuestion] = useState("");
  const [pollOptions, setPollOptions] = useState(["", ""]);
  const [pollError, setPollError] = useState("");
  const [selectedVote, setSelectedVote] = useState({});
  const [confirmLeave, setConfirmLeave] = useState(false);
  const [callNotice, setCallNotice] = useState("");
  const classId = path.split("/classroom/")[1]?.split("/")[0] || "biology-10";
  const currentClass = classes.find((item) => String(item.id) === classId);
  const roomTitle = currentClass ? `${currentClass.subject} · ${currentClass.name}` : "Virtual classroom";
  const chatKey = meetingStorageKey(classId, "chat");
  const pollsKey = meetingStorageKey(classId, "polls");
  const participants = [{ id: user.id, name: user.name, role: user.role, mic, camera, hand, screenSharing }];
  const chatEndRef = useRef(null);

  useEffect(() => { writeLocalValue(chatKey, chatMessages); }, [chatKey, chatMessages]);
  useEffect(() => { writeLocalValue(pollsKey, polls); }, [pollsKey, polls]);
  useEffect(() => { chatEndRef.current?.scrollIntoView({ behavior: "smooth", block: "end" }); }, [chatMessages]);

  useEffect(() => {
    if (videoRef.current && cameraStream.current) videoRef.current.srcObject = cameraStream.current;
  }, [camera, screenSharing]);

  useEffect(() => {
    if (screenVideoRef.current && screenStream.current) {
      screenVideoRef.current.srcObject = screenStream.current;
    }
  }, [screenSharing]);

  useEffect(() => () => {
    cameraStream.current?.getTracks().forEach((track) => track.stop());
    micStream.current?.getTracks().forEach((track) => track.stop());
    screenStream.current?.getTracks().forEach((track) => track.stop());
  }, []);
  useEffect(() => {
    if (!reactionsOpen) return undefined;
    const onKeyDown = (event) => { if (event.key === "Escape") setReactionsOpen(false); };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [reactionsOpen]);
  useEffect(() => {
    if (!confirmLeave) return undefined;
    const previousFocus = document.activeElement;
    const dialog = document.querySelector(".confirm-modal");
    const focusable = () => [...(dialog?.querySelectorAll('button:not([disabled])') || [])];
    focusable()[0]?.focus();
    const onKeyDown = (event) => {
      if (event.key === "Escape") setConfirmLeave(false);
      if (event.key === "Tab") {
        const items = focusable();
        if (!items.length) return;
        if (event.shiftKey && document.activeElement === items[0]) { event.preventDefault(); items.at(-1).focus(); }
        else if (!event.shiftKey && document.activeElement === items.at(-1)) { event.preventDefault(); items[0].focus(); }
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      if (previousFocus instanceof HTMLElement) previousFocus.focus();
    };
  }, [confirmLeave]);

  async function toggleDevice(kind) {
    setCallNotice("");
    const streamRef = kind === "camera" ? cameraStream : micStream;
    const setEnabled = kind === "camera" ? setCamera : setMic;
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
      setEnabled(false);
      return;
    }
    if (!navigator.mediaDevices?.getUserMedia) {
      setCallNotice(t("Device access is unavailable in this browser or page context."));
      return;
    }
    try {
      streamRef.current = await navigator.mediaDevices.getUserMedia(kind === "camera" ? { video: true, audio: false } : { audio: true, video: false });
      setEnabled(true);
    } catch (error) {
      setCallNotice(error.name === "NotAllowedError" ? t("Permission was denied. Allow device access in your browser settings and try again.") : t("The device could not be opened. Check that it is connected and available."));
    }
  }

  function stopScreenShare() {
    if (screenStream.current) {
      screenStream.current.getTracks().forEach((track) => {
        try { track.stop(); } catch (error) { console.debug(error); }
      });
      screenStream.current = null;
    }
    if (screenVideoRef.current) {
      screenVideoRef.current.srcObject = null;
    }
    setScreenSharing(false);
  }

  async function toggleScreenShare() {
    setCallNotice("");
    if (screenSharing || screenStream.current) {
      stopScreenShare();
      return;
    }
    if (!navigator.mediaDevices?.getDisplayMedia) {
      setCallNotice(t("Screen sharing is not supported in this browser."));
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({ video: true, audio: false });
      screenStream.current = stream;
      setScreenSharing(true);
      const videoTrack = stream.getVideoTracks()[0];
      if (videoTrack) {
        videoTrack.onended = () => {
          stopScreenShare();
        };
      }
    } catch (error) {
      if (error.name === "NotAllowedError" || error.name === "PermissionDeniedError" || error.name === "AbortError") {
        return;
      }
      setCallNotice(t("Screen sharing could not be started: ") + (error.message || error.name));
    }
  }

  function leaveClass() {
    cameraStream.current?.getTracks().forEach((track) => track.stop());
    micStream.current?.getTracks().forEach((track) => track.stop());
    stopScreenShare();
    cameraStream.current = null;
    micStream.current = null;
    navigate(`/app/classes/${classId}`);
  }

  function launchReaction(emoji) {
    setReaction(emoji);
    setFlyingReactions((items) => [...items, { id: `${Date.now()}-${Math.random()}`, emoji, left: 18 + Math.random() * 64, size: 26 + Math.random() * 20, rotate: -18 + Math.random() * 36 }]);
    setReactionsOpen(false);
  }

  function sendMeetingMessage(event) {
    event.preventDefault();
    const text = chatText.trim();
    if (!text || text.length > 1000) { setChatError(t("Enter a message of 1,000 characters or fewer.")); return; }
    setChatMessages((items) => [...items, { id: `${Date.now()}-${Math.random()}`, author: user.name, role: user.role, text, time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) }]);
    setChatText(""); setChatError("");
  }

  function publishPoll(event) {
    event.preventDefault();
    const question = pollQuestion.trim();
    const options = pollOptions.map((item) => item.trim()).filter(Boolean);
    if (!question || options.length < 2 || new Set(options.map((item) => item.toLowerCase())).size !== options.length) { setPollError(t("Enter a question and at least two distinct answer options.")); return; }
    setPolls((items) => [{ id: `${Date.now()}`, question, options, votes: {}, closed: false }, ...items.map((item) => ({ ...item, closed: true }))]);
    setPollQuestion(""); setPollOptions(["", ""]); setPollError("");
  }

  function votePoll(poll) {
    const option = selectedVote[poll.id];
    if (!option || poll.votes[user.id] || poll.closed) return;
    setPolls((items) => items.map((item) => item.id === poll.id ? { ...item, votes: { ...item.votes, [user.id]: option } } : item));
  }

  return <>
    <PageHeading eyebrow="VIRTUAL CLASSROOM · LOCAL PREVIEW" title={roomTitle} subtitle="This room has no conferencing or signaling service. Camera and microphone controls affect this device only." />
    {callNotice && <div className="workspace-toast" role="alert">{callNotice}<button aria-label={t("Dismiss")} onClick={() => setCallNotice("")}><X size={14} /></button></div>}
    <div className="classroom-layout">
      <section className="classroom-stage">
        <div className={`stage-screen local-stage${screenSharing ? " screen-stage-active" : ""}`}>
          <span className="stage-label"><span />{t("LOCAL DEVICE PREVIEW")}</span>
          {screenSharing ? (
            <div className="screen-share-viewport">
              <span className="stage-sharing-badge"><ScreenShare size={13} /> {t("Screen sharing active (local preview only · not broadcast)")}</span>
              <video ref={screenVideoRef} autoPlay muted playsInline aria-label={t("Your local screen share preview")} />
            </div>
          ) : (
            camera ? <video ref={videoRef} autoPlay muted playsInline aria-label={t("Your local camera preview")} /> : <div className="teacher-placeholder"><span><GraduationCap size={36} /></span><strong>{t("Your camera is off")}</strong><small>{t("Turn on the camera to preview your device")}</small></div>
          )}
          {screenSharing && camera && (
            <div className="camera-pip-tile" aria-label={t("Camera picture-in-picture preview")}>
              <span className="pip-label">{t("Camera")}</span>
              <video ref={videoRef} autoPlay muted playsInline aria-label={t("Your local camera preview")} />
            </div>
          )}
          <div className="stage-reactions" aria-hidden="true">{flyingReactions.map((item) => <span key={item.id} className="flying-reaction" style={{ left: `${item.left}%`, fontSize: `${item.size}px`, "--reaction-rotate": `${item.rotate}deg` }} onAnimationEnd={() => setFlyingReactions((items) => items.filter((reactionItem) => reactionItem.id !== item.id))}>{item.emoji}</span>)}</div>
          <div className="stage-caption">{t("{{count}} participant · local preview", { count: participants.length })}</div>
        </div>
        <div className="device-status-row">
          <span className={mic ? "device-on" : ""}>{mic ? <Mic size={15} /> : <MicOff size={15} />}{mic ? t("Microphone active on this device") : t("Microphone muted")}</span>
          <span className={camera ? "device-on" : ""}>{camera ? <Camera size={15} /> : <CameraOff size={15} />}{camera ? t("Camera preview active") : t("Camera off")}</span>
          <span className={screenSharing ? "device-on screen-device-on" : ""}>{screenSharing ? <ScreenShare size={15} /> : <ScreenShareOff size={15} />}{screenSharing ? t("Screen sharing active (local preview only)") : t("Screen sharing off")}</span>
        </div>
        <div className="call-controls" aria-label={t("Classroom controls")}>
          <button className={mic ? "on" : ""} onClick={() => toggleDevice("mic")} aria-label={mic ? t("Turn microphone off") : t("Turn microphone on")} title={mic ? t("Turn microphone off") : t("Turn microphone on")}>{mic ? <Mic size={18} /> : <MicOff size={18} />}<span>{mic ? t("Mic on") : t("Mic off")}</span></button>
          <button className={camera ? "on" : ""} onClick={() => toggleDevice("camera")} aria-label={camera ? t("Turn camera off") : t("Turn camera on")} title={camera ? t("Turn camera off") : t("Turn camera on")}>{camera ? <Camera size={18} /> : <CameraOff size={18} />}<span>{camera ? t("Camera on") : t("Camera off")}</span></button>
          <button className={screenSharing ? "on screen-share-on" : ""} onClick={toggleScreenShare} aria-label={screenSharing ? t("Stop Sharing") : t("Start Sharing")} title={screenSharing ? t("Stop Sharing") : t("Start Sharing")}>{screenSharing ? <ScreenShareOff size={18} /> : <ScreenShare size={18} />}<span>{screenSharing ? t("Stop Sharing") : t("Start Sharing")}</span></button>
          <button className={hand ? "on hand-raised" : ""} onClick={() => setHand((raised) => !raised)} aria-pressed={hand} aria-label={hand ? t("Lower hand") : t("Raise hand")}><Hand size={18} /><span>{hand ? t("Hand raised") : t("Raise hand")}</span></button>
          <div className="reaction-control"><button className={reactionsOpen ? "on" : ""} type="button" aria-expanded={reactionsOpen} aria-haspopup="true" onClick={() => setReactionsOpen((open) => !open)}><Smile size={18} /><span>{reaction || t("React")}</span></button>{reactionsOpen && <div className="reaction-tray" role="group" aria-label={t("Choose a reaction")}>{[{ emoji: "👏", label: "Clap" }, { emoji: "👍", label: "Like" }, { emoji: "❤️", label: "Love" }, { emoji: "😂", label: "Laugh" }, { emoji: "🎉", label: "Celebrate" }, { emoji: "😮", label: "Surprised" }].map(({ emoji, label }) => <button key={label} type="button" aria-label={t(label)} onClick={() => launchReaction(emoji)}>{emoji}</button>)}</div>}</div>
          <button type="button" className={panel === "people" ? "on" : ""} onClick={() => setPanel("people")} aria-label={t("Participants, {{count}}", { count: participants.length })}><Users size={18} /><span>{participants.length} {t("People")}</span></button>
          <button type="button" className={panel === "chat" ? "on" : ""} onClick={() => setPanel("chat")} aria-label={t("Open classroom chat")}><MessageCircle size={18} /><span>{t("Chat")}</span></button>
          <button type="button" className={panel === "polls" ? "on" : ""} onClick={() => setPanel("polls")} aria-label={t("Open classroom polls")}><Vote size={18} /><span>{t("Polls")}</span></button>
          <button className="leave-control" onClick={() => setConfirmLeave(true)} aria-label={t("Leave class")}><PhoneOff size={18} /><span>{t("Leave class")}</span></button>
        </div>
        <p className="local-call-note" role="status">{reaction && t("Reaction selected: {{reaction}} · local only", { reaction })}{hand && ` ${t("Your hand is raised locally.")}`}</p>
      </section>
      <aside className="classroom-side"><div className="classroom-tabs" role="tablist" aria-label={t("Meeting panels")}>{[["people", Users, "Participants"], ["chat", MessageCircle, "Chat"], ["polls", Vote, "Polls"]].map(([key, Icon, label]) => <button type="button" role="tab" aria-selected={panel === key} className={panel === key ? "selected" : ""} key={key} onClick={() => setPanel(key)}><Icon size={14} />{key === "people" ? `${t(label)} (${participants.length})` : t(label)}</button>)}</div>
        {panel === "people" && <div className="classroom-people"><PreviewNotice>{t("Only this signed-in participant is available in the local preview. Remote participants are not connected.")}</PreviewNotice>{participants.map((person) => <div className="meeting-person" key={person.id}><span className={`participant-avatar ${person.role}`}>{person.name.slice(0, 1).toUpperCase()}</span><span><strong>{person.name} ({t("You")})</strong><small>{t(person.role === "teacher" ? "Teacher" : "Student")}{person.hand ? ` · ${t("Hand raised")}` : ""}</small></span><span className="meeting-device-status" title={person.mic ? t("Microphone on") : t("Microphone muted")}>{person.mic ? <Mic size={14} /> : <MicOff size={14} />}</span><span className="meeting-device-status" title={person.camera ? t("Camera on") : t("Camera off")}>{person.camera ? <Camera size={14} /> : <CameraOff size={14} />}</span><span className="meeting-device-status" title={person.screenSharing ? t("Screen sharing active (local preview only)") : t("Screen sharing off")}>{person.screenSharing ? <ScreenShare size={14} /> : <ScreenShareOff size={14} />}</span></div>)}</div>}
        {panel === "chat" && <div className="meeting-chat-panel"><PreviewNotice>{t("Meeting chat is stored in this browser only and is not sent to other participants.")}</PreviewNotice><div className="meeting-chat-messages" aria-live="polite">{chatMessages.length ? chatMessages.map((message) => <article className="meeting-chat-message mine" key={message.id}><strong>{message.author} <small>{t(message.role)} · {message.time}</small></strong><p>{message.text}</p></article>) : <EmptyState icon={MessageCircle} title="No messages yet" description="Start the local meeting conversation." />}<div ref={chatEndRef} /></div><form className="meeting-chat-composer" onSubmit={sendMeetingMessage}><label className="sr-only" htmlFor="meeting-chat-input">{t("Message text")}</label><textarea id="meeting-chat-input" value={chatText} onChange={(event) => { setChatText(event.target.value); setChatError(""); }} maxLength={1000} rows={2} placeholder={t("Write a message…")} />{chatError && <p className="form-error" role="alert">{chatError}</p>}<button type="submit" className="workspace-button primary-action" disabled={!chatText.trim()}><Send size={14} />{t("Send locally")}</button></form></div>}
        {panel === "polls" && <div className="meeting-polls-panel"><PreviewNotice>{t("Polls are saved only in this browser and do not sync to attendees.")}</PreviewNotice>{user.role === "teacher" && <form className="meeting-poll-form" onSubmit={publishPoll}><label>{t("Poll question")}<input value={pollQuestion} onChange={(event) => setPollQuestion(event.target.value)} maxLength={180} placeholder={t("Ask your class a question")} /></label>{pollOptions.map((option, index) => <label key={index}>{t("Option {{number}}", { number: index + 1 })}<span className="poll-option-input"><input value={option} onChange={(event) => setPollOptions((items) => items.map((item, itemIndex) => itemIndex === index ? event.target.value : item))} maxLength={100} /><button type="button" aria-label={t("Remove option {{number}}", { number: index + 1 })} disabled={pollOptions.length <= 2} onClick={() => setPollOptions((items) => items.filter((_, itemIndex) => itemIndex !== index))}><X size={14} /></button></span></label>)}{pollOptions.length < 6 && <button className="text-action" type="button" onClick={() => setPollOptions((items) => [...items, ""])}><Plus size={14} />{t("Add option")}</button>}{pollError && <p className="form-error" role="alert">{pollError}</p>}<button type="submit" className="workspace-button primary-action"><Vote size={14} />{t("Publish poll locally")}</button></form>}{polls.length ? polls.map((poll) => { const count = Object.keys(poll.votes || {}).length; const canSeeResults = user.role === "teacher" || Boolean(poll.votes?.[user.id]) || poll.closed; return <article className="meeting-poll-card" key={poll.id}><div><span className="panel-kicker">{poll.closed ? t("CLOSED") : t("OPEN POLL")}</span><h3>{poll.question}</h3></div>{!poll.closed && user.role === "teacher" && <button className="text-action" type="button" onClick={() => setPolls((items) => items.map((item) => item.id === poll.id ? { ...item, closed: true } : item))}>{t("Close poll")}</button>}{!poll.closed && user.role === "student" && !poll.votes?.[user.id] && <fieldset className="poll-vote-options"><legend className="sr-only">{poll.question}</legend>{poll.options.map((option) => <label key={option}><input type="radio" name={`poll-${poll.id}`} checked={selectedVote[poll.id] === option} onChange={() => setSelectedVote((items) => ({ ...items, [poll.id]: option }))} />{option}</label>)}<button className="workspace-button primary-action" type="button" disabled={!selectedVote[poll.id]} onClick={() => votePoll(poll)}>{t("Submit vote")}</button></fieldset>}{canSeeResults && <div className="poll-results">{poll.options.map((option) => { const votes = Object.values(poll.votes || {}).filter((vote) => vote === option).length; const percent = count ? Math.round(votes / count * 100) : 0; return <div className="poll-result-row" key={option}><span>{option}</span><strong>{percent}%</strong><i><b style={{ width: `${percent}%` }} /></i></div>})}<small>{t("{{count}} local votes", { count })}</small></div>}{poll.votes?.[user.id] && <p className="form-success" role="status">{t("Your vote is recorded in this browser.")}</p>}</article>}) : <EmptyState icon={Vote} title="No polls in this room" description={user.role === "teacher" ? "Create a poll for the local meeting preview." : "Polls shared in this meeting will appear here."} />}</div>}
      </aside>
    </div>
    {confirmLeave && <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setConfirmLeave(false); }}><section className="confirm-modal" role="dialog" aria-modal="true" aria-labelledby="leave-title"><button className="modal-close" onClick={() => setConfirmLeave(false)} aria-label={t("Close")}><X size={18} /></button><span className="modal-icon"><PhoneOff size={20} /></span><h2 id="leave-title">{t("Leave this preview class?")}</h2><p>{t("Your local camera, microphone, and screen-sharing tracks will be stopped.")}</p><div><button className="workspace-button" onClick={() => setConfirmLeave(false)}>{t("Stay in class")}</button><button className="workspace-button danger-action" onClick={leaveClass}>{t("Leave class")}</button></div></section></div>}
  </>;
}

function ProfilePage({ user, avatar, setAvatar }) {
  const { t } = useLanguage();
  const [saved, setSaved] = useState(false); const [avatarSaved, setAvatarSaved] = useState(true); const [name, setName] = useState(user.name); const [email, setEmail] = useState(user.email || "");
  function chooseAvatar(id) { setAvatar(id); setAvatarSaved(writeLocalValue(profileStorageKey(user), id)); }
  return <><PageHeading title={t("Your profile")} subtitle="Edit the details shown in this local preview." /><div className="profile-layout"><form className="workspace-form narrow-form" onSubmit={(event) => { event.preventDefault(); setSaved(true); }}><div className="profile-summary"><AvatarFace avatar={avatar} className={`profile-large-avatar ${user.role}`} /><span><strong>{name}</strong><small>{t(user.role === "student" ? "Student" : "Teacher")} · {t("preview profile")}</small></span></div><label>{t("Display name")}<input value={name} onChange={(event) => setName(event.target.value)} required /></label><label>{t("Email address")}<input value={email} onChange={(event) => setEmail(event.target.value)} type="email" placeholder={t("Optional")} /></label><PreviewNotice>{t(isBackendMode ? "Profile edits and avatar selection are local to this browser and are not sent to the account service." : "Profile edits are shown in this page only and are not sent to a service.")}</PreviewNotice><button className="workspace-button primary-action" type="submit">{t("Save profile preview")}<Check size={16} /></button>{saved && <p className="form-success" role="status">{t("Profile preview updated locally.")}</p>}</form><section className="workspace-panel avatar-gallery-panel"><div className="panel-heading"><div><span className="panel-kicker">{t("MAKE IT YOURS")}</span><h2>{t("Choose your avatar")}</h2></div><AvatarFace avatar={avatar} className={`profile-large-avatar ${user.role}`} /></div><p className="panel-body-copy">{t("Select an avatar to preview it across your workspace. Your choice is saved in this browser.")}</p><div className="avatar-gallery" role="group" aria-label={t("20 profile avatars")}>{AVATAR_OPTIONS.map(([id, label]) => <button type="button" key={id} className={`avatar-choice ${avatar === id ? "selected" : ""}`} aria-label={t(label)} aria-pressed={avatar === id} onClick={() => chooseAvatar(id)}><AvatarFace avatar={id} /><span>{t(label)}</span></button>)}</div>{avatarSaved ? <p className="form-success" role="status">{t("Avatar selection is saved in this browser.")}</p> : <p className="form-error" role="alert">{t("Avatar preview updated, but browser storage could not save it.")}</p>}</section></div></>;
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
