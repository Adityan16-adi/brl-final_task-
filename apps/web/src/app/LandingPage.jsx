import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  ArrowDownRight, ArrowRight, ArrowUpRight, AudioLines, Bell, BookOpen,
  BookOpenCheck, CalendarDays, Check, ChevronDown, ClipboardCheck,
  AtSign, Clock3, FileText, GraduationCap, LayoutDashboard, Menu,
  MessageCircle, Play, ShieldCheck, Sparkles, Users, Video, X,
} from "lucide-react";
import ThemeToggle from "./ThemeToggle.jsx";
import LanguageSelector from "../i18n/LanguageSelector.jsx";
import { useLanguage } from "../i18n/useLanguage.js";
import "./LandingPage.css";
import LocalizedText from "../i18n/LocalizedText.jsx";

const navigation = [
  { label: "Features", href: "#features" },
  { label: "How it works", href: "#how-it-works" },
  { label: "For students", href: "#students" },
  { label: "For teachers", href: "#teachers" },
  { label: "About", href: "#about" },
];

const capabilities = [
  { label: "Live Classes", icon: Video, href: "#feature-live", tone: "violet" },
  { label: "Assignments", icon: ClipboardCheck, href: "#feature-assignments", tone: "cyan" },
  { label: "Materials", icon: BookOpen, href: "#feature-materials", tone: "pink" },
  { label: "Attendance", icon: Check, href: "#feature-attendance", tone: "lime" },
  { label: "Timetable", icon: CalendarDays, href: "#feature-calendar", tone: "cyan" },
  { label: "AI Mentor", icon: Sparkles, href: "#feature-mentor", tone: "violet" },
  { label: "Chat", icon: MessageCircle, href: "#feature-chat", tone: "pink" },
  { label: "Notifications", icon: Bell, href: "#feature-notifications", tone: "lime" },
];

const workflow = [
  { number: "01", title: "Choose your portal", text: "Start in your separate student or teacher portal and create a local preview profile.", icon: ShieldCheck, detail: "YOUR SPACE, YOUR ROLE" },
  { number: "02", title: "Find your classes", text: "Join a class, open your schedule, and see what's coming up.", icon: CalendarDays, detail: "A CLEAR PLACE TO START" },
  { number: "03", title: "Learn together", text: "Take part in lessons, share resources, and keep conversations close.", icon: Users, detail: "CONNECTED BY CONTEXT" },
  { number: "04", title: "See your progress", text: "Keep assignments, attendance, and next steps in view.", icon: BookOpenCheck, detail: "MOMENTUM, MADE VISIBLE" },
];

function Brand({ onClick }) {
  const { t } = useLanguage();
  return <Link className="landing-brand" to="/" onClick={onClick} aria-label={t("Unified Learn home")}>
    <span className="landing-brand-mark"><GraduationCap size={21} strokeWidth={2.2} /></span>
    <span>{<LocalizedText text={"Unified"} />}<strong>{<LocalizedText text={"Learn"} />}</strong></span>
  </Link>;
}

function LandingNavbar({ menuOpen, setMenuOpen, scrolled }) {
  const { t } = useLanguage();
  function closeMenu() { setMenuOpen(false); }
  return <>
    {menuOpen && <button className="landing-scrim" aria-label={t("Close navigation menu")} onClick={closeMenu} />}
    <header className={`landing-header${scrolled ? " is-scrolled" : ""}`}>
      <Brand onClick={closeMenu} />
      <nav className={`landing-nav${menuOpen ? " is-open" : ""}`} id="landing-navigation" aria-label={t("Main navigation")}>
        {navigation.map(({ label, href }) => <a className="landing-nav-link" href={href} key={label} onClick={closeMenu}>{t(label)}</a>)}
        <div className="landing-mobile-actions">
          <Link className="landing-mobile-login" to="/login" onClick={closeMenu}>{t("Log in")}</Link>
          <Link className="landing-button landing-button-primary" to="/register" onClick={closeMenu}>{t("Get Started")} <ArrowRight size={16} /></Link>
          <LanguageSelector />
          <ThemeToggle />
        </div>
      </nav>
      <div className="landing-header-actions">
        <LanguageSelector />
        <ThemeToggle compact />
        <Link className="landing-login" to="/login">{t("Log in")}</Link>
        <Link className="landing-button landing-button-primary landing-header-cta" to="/register">{t("Get Started")} <ArrowRight size={15} /></Link>
      </div>
      <button className="landing-menu-toggle" type="button" aria-label={t(menuOpen ? "Close navigation" : "Open navigation")} aria-expanded={menuOpen} aria-controls="landing-navigation" onClick={() => setMenuOpen((open) => !open)}>
        {menuOpen ? <X size={21} /> : <Menu size={21} />}
      </button>
    </header>
  </>;
}

function HeroInterface() {
  const { t } = useLanguage();
  return <div className="hero-art" aria-label={t("Preview of the Unified Learn classroom and learning dashboard")}>
    <div className="hero-art-grid" aria-hidden="true" />
    <div className="art-label art-label-class"><span className="art-label-dot" /> {t("CLASS IN SESSION")} <ArrowUpRight size={13} /></div>
    <div className="classroom-window glass-panel">
      <div className="classroom-topbar">
        <div className="classroom-brand"><span className="classroom-mark"><GraduationCap size={15} /></span><span><strong>{t("Live study room")}</strong><small>{t("Biology · Cell structures")}</small></span></div>
        <span className="classroom-live"><i />{<LocalizedText text={"LIVE"} />}<span>{<LocalizedText text={"24:08"} />}</span></span>
      </div>
      <div className="classroom-stage">
        <div className="instructor-stage">
          <div className="instructor-avatar"><span>{<LocalizedText text={"MR"} />}</span><Sparkles size={17} /></div>
          <div className="instructor-caption"><strong>{<LocalizedText text={"Ms. Rivera"} />}</strong><span>{t("Explaining cell division")}</span></div>
          <div className="stage-status"><AudioLines size={15} /> {t("Speaking")}</div>
        </div>
        <div className="stage-side-tiles"><div className="student-tile student-tile-one"><span>{<LocalizedText text={"AL"} />}</span><small>{<LocalizedText text={"Alex"} />}</small></div><div className="student-tile student-tile-two"><span>{<LocalizedText text={"MK"} />}</span><small>{<LocalizedText text={"Maya"} />}</small></div></div>
        <div className="lesson-chip"><BookOpen size={13} /><span>{t("Lesson notes")}</span><ArrowUpRight size={12} /></div>
      </div>
      <div className="classroom-controls"><span className="participant-count"><Users size={14} />{<LocalizedText text={"24 in class"} />}</span><div><span><AudioLines size={15} /></span><span><Video size={15} /></span><span className="control-end"><X size={15} /></span></div><span className="classroom-more"><ChevronDown size={15} /></span></div>
    </div>
    <div className="art-label art-label-week"><Clock3 size={13} /> {t("YOUR WEEK, IN FOCUS")}</div>
    <div className="progress-float glass-panel"><div className="progress-float-head"><span className="progress-icon"><LayoutDashboard size={15} /></span><span><small>{t("WEEKLY PROGRESS")}</small><strong>{t("You're on track")}</strong></span><ArrowUpRight size={14} /></div><div className="progress-bar"><span /></div><div className="progress-float-foot"><span>{t("6 of 8 tasks complete")}</span><strong>{<LocalizedText text={"75%"} />}</strong></div></div>
    <div className="mentor-float glass-panel"><span className="mentor-float-icon"><Sparkles size={16} /></span><span><small>{t("AI MENTOR · PREVIEW")}</small><strong>{t("Ready when you are")}</strong></span><ArrowRight size={14} /></div>
    <div className="art-orbit orbit-one" aria-hidden="true" /><div className="art-orbit orbit-two" aria-hidden="true" />
  </div>;
}

function HeroSection() {
  const { t } = useLanguage();
  return <section className="landing-hero" id="home">
    <div className="hero-copy reveal">
      <span className="hero-eyebrow"><span className="eyebrow-spark"><Sparkles size={13} /></span> {t("THE FUTURE OF CONNECTED LEARNING")}</span>
      <h1>{t("Learning has")}<br />{t("a")} <span className="hero-gradient">{t("new dimension.")}</span></h1>
      <p className="hero-description">{t("Live classrooms, thoughtful study tools, and everything your learning journey needs, connected in one beautiful space.")}</p>
      <div className="hero-actions">
        <Link className="landing-button landing-button-primary hero-primary" to="/register">{t("Start Learning Free")} <ArrowRight size={17} /></Link>
        <a className="landing-button landing-button-secondary" href="#how-it-works"><span className="play-mark"><Play size={12} fill="currentColor" /></span> {t("Explore the Platform")}</a>
      </div>
      <div className="hero-trust"><div className="trust-avatars" aria-hidden="true"><span>{<LocalizedText text={"AL"} />}</span><span>{<LocalizedText text={"MK"} />}</span><span>{<LocalizedText text={"SR"} />}</span><span>{<LocalizedText text={"JT"} />}</span></div><div><strong>{t("One space for every school day")}</strong><span>{t("Built for curious minds and great teachers")}</span></div><span className="trust-divider" /><span className="trust-stat"><strong>{<LocalizedText text={"8"} />}</strong><small>{t("connected tools")}</small></span></div>
    </div>
    <HeroInterface />
    <a className="hero-scroll" href="#capabilities"><span>{t("SCROLL TO EXPLORE")}</span><ArrowDownRight size={14} /></a>
  </section>;
}

function LearningStrip() {
  const { t } = useLanguage();
  return <section className="capability-section" id="capabilities" aria-labelledby="capability-heading">
    <div className="capability-intro"><span className="section-kicker">{t("ONE CONNECTED SPACE")}</span><h2 id="capability-heading">{t("Everything in")}<br />{t("its right place.")}</h2></div>
    <div className="capability-grid">{capabilities.map(({ label, icon: Icon, href, tone }) => <a href={href} className="capability-item" key={label}><span className={`capability-icon tone-${tone}`}><Icon size={18} /></span><span>{t(label)}</span><ArrowUpRight className="capability-arrow" size={13} /></a>)}</div>
  </section>;
}

function WorkflowSection() {
  const { t } = useLanguage();
  return <section className="workflow-section landing-section" id="how-it-works">
    <div className="section-heading reveal"><span className="section-kicker">{t("A SIMPLE WAY FORWARD")}</span><h2>{t("Four steps.")}<br /><span>{t("One more connected day.")}</span></h2><p>{t("A calmer school routine starts with knowing where to go and what comes next.")}</p></div>
    <div className="workflow-path">{workflow.map(({ number, title, text, icon: Icon, detail }) => <article className="workflow-step reveal" key={number}><div className="step-top"><span className="step-number">{number}</span><span className="step-icon"><Icon size={19} /></span></div><span className="step-detail">{t(detail)}</span><h3>{t(title)}</h3><p>{t(text)}</p></article>)}</div>
  </section>;
}

function MiniLivePreview() {
  const { t } = useLanguage();
  return <div className="mini-live-preview"><div className="mini-live-top"><span><i /> {t("LIVE CLASS")}</span><span>{<LocalizedText text={"09:30"} />}</span></div><div className="mini-live-scene"><div className="mini-teacher"><span>{<LocalizedText text={"MR"} />}</span><small>{<LocalizedText text={"Ms. Rivera"} />}</small></div><div className="mini-scene-note"><BookOpen size={15} /><span>{t("Cell structures")}<br /><strong>{t("Lesson 04")}</strong></span></div></div><div className="mini-live-bottom"><span className="mini-people"><i>{<LocalizedText text={"AL"} />}</i><i>{<LocalizedText text={"MK"} />}</i><i>{<LocalizedText text={"JT"} />}</i><small>{<LocalizedText text={"+21"} />}</small></span><span className="mini-call-controls"><AudioLines size={13} /><Video size={13} /><MessageCircle size={13} /></span></div></div>;
}

function MentorPreview() {
  const { t } = useLanguage();
  return <div className="mentor-preview"><div className="mentor-preview-head"><span className="mentor-preview-mark"><Sparkles size={15} /></span><span><strong>{t("AI Mentor")}</strong><small>{t("STUDY PREVIEW · SAMPLE RESPONSE")}</small></span><span className="mentor-online" /></div><div className="mentor-question">{t("Can you help me understand how cells divide?")}</div><div className="mentor-answer"><span className="answer-mark"><Sparkles size={12} /></span><p>{t("Think of cell division as a carefully coordinated copy-and-split process. First, the cell duplicates its DNA...")}</p></div><div className="mentor-prompt">{t("Ask about a lesson")} <ArrowUpRight size={13} /></div></div>;
}

function AssignmentPreview() {
  const { t } = useLanguage();
  const tasks = [{ label: "Cell concept map", meta: "Biology · Due tomorrow", state: "IN PROGRESS", width: "68%" }, { label: "Algebra practice", meta: "Mathematics · Due Friday", state: "NOT STARTED", width: "24%" }, { label: "History reflection", meta: "World History · Due Oct 24", state: "REVIEWED", width: "100%" }];
  return <div className="assignment-preview">{tasks.map((task) => <div className="assignment-task" key={task.label}><span className="task-mark"><ClipboardCheck size={14} /></span><span className="task-copy"><strong>{t(task.label)}</strong><small>{t(task.meta)}</small><i><b style={{ width: task.width }} /></i></span><span className="task-state">{t(task.state)}</span></div>)}</div>;
}

function MaterialsPreview() {
  const { t } = useLanguage();
  return <div className="materials-preview"><div className="material-doc doc-purple"><span><FileText size={17} /></span><i /><i /><i /></div><div className="material-doc doc-cyan"><span><Play size={14} fill="currentColor" /></span><i /><i /><i /></div><div className="material-doc doc-green"><span><BookOpen size={16} /></span><i /><i /><i /></div><div className="materials-caption"><strong>{t("Course materials")}</strong><small>{t("Notes, videos, and references")}</small></div></div>;
}

function AttendancePreview() {
  const { t } = useLanguage();
  return <div className="attendance-preview"><div className="attendance-ring"><div><strong>{<LocalizedText text={"94"} />}<span>{<LocalizedText text={"%"} />}</span></strong><small>{t("ATTENDANCE")}</small></div></div><div className="attendance-copy"><span className="status-dot" /><strong>{t("Looking good")}</strong><small>{t("18 of 19 classes attended")}</small><div className="attendance-month"><span>{t("SEP")}</span><i /><i /><i /><i /><i /><span>{t("OCT")}</span><i /><i /><i /><i className="missed" /><i /></div></div></div>;
}

function CalendarPreview() {
  const { t } = useLanguage();
  return <div className="calendar-preview"><div className="calendar-preview-head"><span>{t("THIS WEEK")}</span><strong>{t("Oct 19 – 23")} <ArrowRight size={13} /></strong></div><div className="calendar-row"><time>{<LocalizedText text={"09:30"} />}</time><span className="calendar-event event-cyan"><strong>{t("Biology")}</strong><small>{t("Cell structures · Room 204")}</small></span></div><div className="calendar-row"><time>{<LocalizedText text={"10:15"} />}</time><span className="calendar-event event-violet"><strong>{t("Mathematics")}</strong><small>{t("Algebra · Room 108")}</small></span></div><div className="calendar-row"><time>{<LocalizedText text={"13:00"} />}</time><span className="calendar-event event-pink"><strong>{t("World History")}</strong><small>{t("Modern Europe · Room 312")}</small></span></div></div>;
}

function FeatureShowcase() {
  const { t } = useLanguage();
  return <section className="feature-section landing-section" id="features">
    <div className="section-heading feature-heading reveal"><span className="section-kicker">{t("MADE FOR THE WHOLE SCHOOL DAY")}</span><h2>{t("Tools that work")}<br /><span>{t("better together.")}</span></h2><p>{t("Every detail has a place, from the first class of the day to the last assignment check-in.")}</p></div>
    <div className="feature-mosaic" id="showcase">
      <article className="feature-window feature-live reveal" id="feature-live"><div className="feature-window-copy"><span className="feature-label"><Video size={13} /> {t("LIVE CLASSROOMS")}</span><h3>{t("Be there,")}<br />{t("even from here.")}</h3><p>{t("Lessons, class chat, and shared notes stay together while you learn.")}</p><a href="/app/classes">{t("Explore classrooms")} <ArrowUpRight size={14} /></a></div><MiniLivePreview /></article>
      <article className="feature-window feature-mentor reveal" id="feature-mentor"><span className="feature-label"><Sparkles size={13} /> {t("AI MENTOR · PREVIEW")}</span><h3>{t("A little help with")}<br />{t("the next big question.")}</h3><MentorPreview /></article>
      <article className="feature-window feature-assignments reveal" id="feature-assignments"><span className="feature-label"><ClipboardCheck size={13} /> {t("ASSIGNMENTS & QUIZZES")}</span><h3>{t("Know what’s next.")}</h3><AssignmentPreview /><a href="/app/assignments">{t("View assignments")} <ArrowUpRight size={14} /></a></article>
      <article className="feature-window feature-materials reveal" id="feature-materials"><span className="feature-label"><BookOpen size={13} /> {t("LEARNING MATERIALS")}</span><h3>{t("Keep good resources close.")}</h3><MaterialsPreview /><a href="/app/materials">{t("Browse materials")} <ArrowUpRight size={14} /></a></article>
      <article className="feature-window feature-attendance reveal" id="feature-attendance"><span className="feature-label"><Check size={13} /> {t("ATTENDANCE & PROGRESS")}</span><AttendancePreview /></article>
      <article className="feature-window feature-calendar reveal" id="feature-calendar"><span className="feature-label"><CalendarDays size={13} /> {t("CALENDAR & TIMETABLE")}</span><h3>{t("A week with room to focus.")}</h3><CalendarPreview /></article>
      <article className="feature-window feature-chat reveal" id="feature-chat"><span className="feature-label"><MessageCircle size={13} /> {t("CLASS COMMUNICATION")}</span><div className="message-preview"><span className="message-avatar">{<LocalizedText text={"MR"} />}</span><div><div className="message-author"><strong>{<LocalizedText text={"Ms. Rivera"} />}</strong><small>{<LocalizedText text={"10:42"} />}</small></div><p>{t("Reminder: bring your cell model notes to class tomorrow.")}</p></div></div><a href="/app/chat">{t("Open class chat")} <ArrowUpRight size={14} /></a></article>
      <article className="feature-window feature-notifications reveal" id="feature-notifications"><span className="feature-label"><Bell size={13} /> {t("NOTIFICATIONS")}</span><div className="notification-preview"><span className="notification-icon"><Bell size={15} /></span><span><strong>{t("Three things to catch up on")}</strong><small>{t("New feedback · Tomorrow’s class · Due date")}</small></span><span className="notification-count">{<LocalizedText text={"3"} />}</span></div><a href="/app/notifications">{t("See your updates")} <ArrowUpRight size={14} /></a></article>
    </div>
    <p className="preview-caption"><ShieldCheck size={14} /> {t("Previews are illustrative. This frontend preview does not connect to live classes or AI services.")}</p>
  </section>;
}

function StudentDashboardPreview() {
  const { t } = useLanguage();
  return <div className="audience-dashboard student-dashboard"><div className="dashboard-topline"><span>{t("STUDENT SPACE")}</span><span className="dashboard-avatar student-avatar">{<LocalizedText text={"A"} />}</span></div><div className="dashboard-welcome"><small>{t("MONDAY, OCTOBER 19")}</small><strong>{t("Good morning, Alex.")}</strong><span>{t("Here’s your day, at a glance.")}</span></div><div className="student-next-class"><span className="next-class-icon"><Video size={15} /></span><span><small>{t("NEXT UP · 09:30")}</small><strong>{t("Biology · Cell structures")}</strong><em>{t("Room 204 · Ms. Rivera")}</em></span><ArrowUpRight size={15} /></div><div className="student-dashboard-stats"><span><small>{t("TO DO")}</small><strong>{<LocalizedText text={"3"} />}<i>{t("tasks")}</i></strong></span><span><small>{t("ATTENDANCE")}</small><strong>{<LocalizedText text={"94"} />}<em>{<LocalizedText text={"%"} />}</em></strong></span><span><small>{t("ON TRACK")}</small><strong>{<LocalizedText text={"6"} />}<i>{t("of 8")}</i></strong></span></div><div className="dashboard-bottom-line"><span /><span /><span /><span /><span /><span /><span /></div></div>;
}

function TeacherDashboardPreview() {
  const { t } = useLanguage();
  return <div className="audience-dashboard teacher-dashboard"><div className="dashboard-topline"><span>{t("TEACHER SPACE")}</span><span className="dashboard-avatar teacher-avatar">{<LocalizedText text={"J"} />}</span></div><div className="dashboard-welcome"><small>{t("MONDAY, OCTOBER 19")}</small><strong>{t("Good morning, Jordan.")}</strong><span>{t("Your classes are ready.")}</span></div><div className="teacher-stat-row"><span><small>{t("ACTIVE CLASSES")}</small><strong>{<LocalizedText text={"04"} />}</strong></span><span><small>{t("TO REVIEW")}</small><strong>{<LocalizedText text={"12"} />}</strong></span><span><small>{t("ATTENDANCE")}</small><strong>{<LocalizedText text={"94%"} />}</strong></span></div><div className="teacher-dashboard-class"><span className="class-time">{<LocalizedText text={"10:15"} />}</span><span><strong>{t("Year 10 · Mathematics")}</strong><small>{t("Algebra · 24 students")}</small></span><span className="class-start-dot" /></div><div className="teacher-dashboard-class"><span className="class-time">{<LocalizedText text={"13:00"} />}</span><span><strong>{t("Year 9 · World History")}</strong><small>{t("Modern Europe · 21 students")}</small></span><span className="class-start-dot" /></div></div>;
}

function AudienceSection() {
  const { t } = useLanguage();
  return <section className="audience-section landing-section" id="students">
    <div className="audience-block student-block reveal"><StudentDashboardPreview /><div className="audience-copy"><span className="section-kicker">{t("FOR STUDENTS")}</span><h2>{t("Make space")}<br />{t("for your next idea.")}</h2><p>{t("Join classes, keep assignments organized, find the right resources, and make steady progress at your pace.")}</p><ul><li><Check size={16} /> {t("Classes and deadlines in one view")}</li><li><Check size={16} /> {t("Study materials close at hand")}</li><li><Check size={16} /> {t("Progress you can actually see")}</li></ul><div className="audience-actions"><Link className="landing-button landing-button-primary" to="/student/login">{t("Student Login")} <ArrowRight size={15} /></Link><Link className="audience-text-link" to="/student/register">{t("Create a student profile")} <ArrowUpRight size={14} /></Link></div></div></div>
    <div className="audience-block teacher-block reveal" id="teachers"><div className="audience-copy"><span className="section-kicker">{t("FOR TEACHERS")}</span><h2>{t("More clarity.")}<br />{t("More room to teach.")}</h2><p>{t("Manage classes, share materials, take attendance, and review submissions without losing the thread.")}</p><ul><li><Check size={16} /> {t("Class planning and updates together")}</li><li><Check size={16} /> {t("A focused view of work to review")}</li><li><Check size={16} /> {t("Schedules and follow-ups at a glance")}</li></ul><div className="audience-actions"><Link className="landing-button landing-button-primary" to="/teacher/login">{t("Teacher Login")} <ArrowRight size={15} /></Link><Link className="audience-text-link" to="/teacher/register">{t("Create a teacher profile")} <ArrowUpRight size={14} /></Link></div></div><TeacherDashboardPreview /></div>
  </section>;
}

function AboutSection() {
  const { t } = useLanguage();
  return <section className="about-section" id="about"><div className="about-mark"><GraduationCap size={22} /></div><div><span className="section-kicker">{t("ABOUT UNIFIED LEARN")}</span><h2>{t("A little more connected, every day.")}</h2></div><p>{t("Unified Learn brings the everyday rhythm of school into one thoughtful space, designed for students and teachers to move forward together.")}</p></section>;
}

function FooterDialog({ kind, onClose }) {
  const { t } = useLanguage();
  if (!kind) return null;
  const content = kind === "privacy"
    ? { title: "Privacy in this preview", text: "Theme, language, and account session preferences are stored in this browser only. No personal information is sent to a server." }
    : { title: "Terms for this preview", text: "Unified Learn shows sample classes, messages, assignments, and connected tools. It is not a live education service." };
  return <div className="footer-dialog-backdrop" onClick={onClose}><section className="footer-dialog" role="dialog" aria-modal="true" aria-labelledby="footer-dialog-title" onClick={(event) => event.stopPropagation()}><button className="dialog-close" type="button" aria-label={t("Close dialog")} onClick={onClose}><X size={18} /></button><span className="section-kicker">{t("UNIFIED LEARN · FRONTEND PREVIEW")}</span><h2 id="footer-dialog-title">{t(content.title)}</h2><p>{t(content.text)}</p><button className="landing-button landing-button-primary" type="button" onClick={onClose}>{t("Understood")} <Check size={15} /></button></section></div>;
}

function LandingFooter({ setActiveDialog, notice, setNotice }) {
  const { t } = useLanguage();
  return <footer className="landing-footer">
    <div className="footer-main">
      <div className="footer-brand-column"><Brand /><p>{t("One connected space for learning, teaching, and everything that moves a school day forward.")}</p><div className="footer-socials" aria-label={t("Social channels")}><button type="button" aria-label={t("Community preview channel")} onClick={() => setNotice(t("Unified Learn social channels are not connected in this frontend preview."))}><Users size={16} /></button><button type="button" aria-label={t("Contact preview channel")} onClick={() => setNotice(t("Unified Learn social channels are not connected in this frontend preview."))}><AtSign size={16} /></button><button type="button" aria-label={t("Video preview channel")} onClick={() => setNotice(t("Unified Learn social channels are not connected in this frontend preview."))}><Play size={16} /></button></div>{notice && <p className="footer-notice" role="status">{notice}</p>}</div>
      <div className="footer-link-group"><strong>{t("Platform")}</strong><a href="#features">{t("Features")}</a><a href="#how-it-works">{t("How it works")}</a><a href="#feature-live">{t("Live classrooms")}</a><a href="#feature-materials">{t("Learning materials")}</a></div>
      <div className="footer-link-group"><strong>{t("Students")}</strong><Link to="/student/login">{t("Student login")}</Link><Link to="/student/register">{t("Create a profile")}</Link><a href="#feature-assignments">{t("Assignments")}</a><a href="#feature-mentor">{t("Study support")}</a></div>
      <div className="footer-link-group"><strong>{t("Teachers")}</strong><Link to="/teacher/login">{t("Teacher login")}</Link><Link to="/teacher/register">{t("Create a profile")}</Link><a href="#feature-attendance">{t("Attendance")}</a><a href="#feature-chat">{t("Communication")}</a></div>
      <div className="footer-link-group footer-help"><strong>{t("Help & information")}</strong><button type="button" onClick={() => setNotice(t("Contact support is not connected in this frontend preview."))}>{t("Contact support")} <span>{t("Preview only")}</span></button><a href="/forgot-password">{t("Password help")}</a><button type="button" onClick={() => setActiveDialog("privacy")}>{t("Privacy")} <span>{t("Preview info")}</span></button><button type="button" onClick={() => setActiveDialog("terms")}>{t("Terms")} <span>{t("Preview info")}</span></button></div>
    </div>
    <div className="footer-bottom"><span>{<LocalizedText text={"© 2026 Unified Learn ·"} />}{t("Frontend preview")}</span><span className="footer-bottom-note"><ShieldCheck size={13} /> {t("No live account or classroom services are connected.")}</span><a href="#home">{t("Back to top")} <ArrowUpRight size={13} /></a></div>
  </footer>;
}

export default function LandingPage() {
  const { t } = useLanguage();
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [newsletterEmail, setNewsletterEmail] = useState("");
  const [newsletterMessage, setNewsletterMessage] = useState("");
  const [notice, setNotice] = useState("");
  const [activeDialog, setActiveDialog] = useState(null);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 24);
    handleScroll();
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    function handleKeyDown(event) {
      if (event.key === "Escape") {
        setMenuOpen(false);
        setActiveDialog(null);
      }
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  useEffect(() => {
    const targets = document.querySelectorAll(".landing-page .reveal");
    if (!("IntersectionObserver" in window)) {
      targets.forEach((target) => target.classList.add("is-visible"));
      return undefined;
    }
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -32px 0px" });
    targets.forEach((target) => observer.observe(target));
    return () => observer.disconnect();
  }, []);

  function submitNewsletter(event) {
    event.preventDefault();
    setNewsletterMessage("Thanks for your interest. This preview does not send or store email.");
    setNewsletterEmail("");
  }

  return <div className="landing-page">
    <div className="landing-ambient" aria-hidden="true" />
    <LandingNavbar menuOpen={menuOpen} setMenuOpen={setMenuOpen} scrolled={scrolled} />
    <main>
      <HeroSection />
      <LearningStrip />
      <WorkflowSection />
      <FeatureShowcase />
      <AudienceSection />
      <section className="final-cta-section" id="get-started"><div className="cta-ambient" aria-hidden="true" /><div className="cta-content reveal"><span className="section-kicker">{t("YOUR NEXT CHAPTER")}</span><h2>{t("Your next chapter")}<br /><span>{t("starts here.")}</span></h2><p>{t("Make room for better questions, clearer plans, and more connected learning.")}</p><div className="cta-actions"><Link className="landing-button landing-button-primary" to="/register">{t("Start Learning Free")} <ArrowRight size={16} /></Link><a className="landing-button landing-button-secondary" href="#features">{t("Explore Features")} <ArrowUpRight size={15} /></a></div></div><div className="cta-side-note"><span><GraduationCap size={17} /></span><strong>{<LocalizedText text={"Unified Learn"} />}</strong><small>{t("Learn. Grow. Achieve.")}</small></div></section>
      <AboutSection />
    </main>
    <section className="newsletter-section" aria-labelledby="newsletter-title"><div><span className="section-kicker">{t("NOTES FROM UNIFIED LEARN")}</span><h2 id="newsletter-title">{t("A thoughtful note,")}<br />{t("now and then.")}</h2><p>{t("Ideas on learning, teaching, and what’s next.")}</p></div><form onSubmit={submitNewsletter}><label className="visually-hidden" htmlFor="landing-newsletter-email">{t("Email address")}</label><div className="newsletter-field"><input id="landing-newsletter-email" type="email" value={newsletterEmail} onChange={(event) => setNewsletterEmail(event.target.value)} placeholder={t("Your email address")} autoComplete="email" required /><button type="submit" aria-label={t("Subscribe to newsletter")}><ArrowRight size={17} /></button></div><span className="newsletter-confirmation" role="status">{newsletterMessage ? t(newsletterMessage) : t("Frontend preview only. No email is sent.")}</span></form></section>
    <LandingFooter setActiveDialog={setActiveDialog} notice={notice} setNotice={setNotice} />
    <FooterDialog kind={activeDialog} onClose={() => setActiveDialog(null)} />
  </div>;
}
