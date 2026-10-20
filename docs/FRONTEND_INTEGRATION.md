# Unified Learn frontend integration boundary

This document describes provisional frontend requirements for the backend, video, and ML teams. It is not an API specification. Names and example shapes are discussion aids only and require review with the owning teams. No endpoint URLs, database schema, authorization mechanism, or field constraints are established here.

## Current prototype boundary

The current flow is `React page → named frontend service operation → selected implementation`. With `VITE_DATA_MODE=api`, assignments, assignment submissions, materials, notifications, and calendar events use `apps/web/src/services/api/backendAdapter.js`. In mock mode, these operations use the existing mock services. Authentication, classes, attendance, announcements, messages, and study tools remain on mock services because they are not connected through this adapter. Shared English/Hindi strings are maintained in `apps/web/src/i18n/translations.js`; `LanguageProvider` and `ThemeProvider` own independent local preferences and do not own account identity.

All request and response shapes below are provisional. The backend team owns final authentication, permissions, persistence, validation, and error semantics. The frontend must display loading, empty, success, and failure states without treating mock success as a server operation.

## Backend operations for team review

| Suggested operation | Purpose and provisional input | Provisional response | Possible errors | Frontend caller |
| --- | --- | --- | --- | --- |
| `signIn({ accountId, accessCode })` | Start a real session; production credential fields and flow are backend-owned. The backend must resolve the role from the verified identity, never accept a client-selected role as authority. | `{ user: { id, name, email, role }, session }` | Invalid credentials, unavailable service, policy rejection, disabled account | Separate student/teacher login pages |
| `signOut()` | End the current session. | `{ success: true }` | Session unavailable, service failure | Logout page |
| `getCurrentUser()` | Resolve the signed-in user's profile and role. | `{ id, name, email, role }` | Expired session, unavailable service | App shell, dashboards, profile |
| `listClasses({ query, subject })` | Retrieve visible classes and optional filters. | `{ items: [{ id, name, subject, teacher, schedule }] }` | Access denied, service failure | Classes, dashboard |
| `getClass({ classId })` | Retrieve class detail and member summary. | `{ class, members, announcements }` | Not found, access denied | Class detail |
| `createClass({ name, subject, schedule })` | Request a class be created; exact fields remain to be agreed. | `{ class }` | Validation failure, access denied | Create class |
| `joinClass({ code })` | Request to join an eligible class. | `{ class, membership }` | Invalid/expired code, already joined, access denied | Join class |
| `getMeetingInfo({ classId, sessionId? })` | Retrieve meeting information owned by the selected video integration. | `{ meetingId, joinInformation }` | Session unavailable, access denied | Class detail, classroom |
| `listAssignments({ classId?, status? })` | Retrieve work and optional status filters. | `{ items: [{ id, title, dueDate, status }] }` | Not found, access denied, service failure | Dashboard, assignments |
| `createAssignment({ classId, title, instructions, dueDate })` | Request assignment creation. | `{ assignment }` | Validation failure, access denied | Assignment creation |
| `getAssignment({ assignmentId })` | Retrieve instructions, status, marks, and feedback as permitted. | `{ assignment, submission?, feedback? }` | Not found, access denied | Assignment detail |
| `submitAssignment({ assignmentId, fileReferences, text? })` | Submit work using the backend-approved file-storage flow. | `{ submission, status }` | File rejected, deadline/policy rejection, service failure | Assignment detail |
| `listMaterials({ classId?, category? })` | Retrieve class learning resources. | `{ items: [{ id, title, type, subject, resourceReference }] }` | Not found, access denied, service failure | Materials, class detail |
| `uploadMaterial({ classId, metadata, fileReference })` | Register a resource through an agreed storage adapter. | `{ material }` | File too large/type rejected, access denied, storage failure | Materials |
| `listAttendance({ classId?, from?, to? })` | Retrieve attendance records and summary. | `{ records, summary }` | Not found, access denied, service failure | Attendance, dashboard |
| `updateAttendance({ classId, date, records })` | Request updates for a class session. | `{ records, savedAt }` | Validation failure, access denied, conflict | Teacher attendance |
| `listCalendarEvents({ from, to, classId? })` | Retrieve timetable and academic events in a range. | `{ items: [{ id, title, start, end, type }] }` | Invalid range, access denied, service failure | Timetable, calendar |
| `listAnnouncements({ classId? })` | Retrieve announcements visible to the user. | `{ items }` | Access denied, service failure | Announcements, dashboard |
| `createAnnouncement({ classId, title, body })` | Request a class announcement. | `{ announcement }` | Validation failure, access denied | Teacher class controls |
| `listMessages({ conversationId, cursor? })` | Retrieve messages for an authorized conversation. | `{ items, nextCursor? }` | Not found, access denied, service failure | Chat, classroom |
| `sendMessage({ conversationId, text })` | Submit a message for delivery under backend policy. | `{ message }` | Validation/moderation rejection, access denied, service failure | Chat, classroom |
| `listNotifications({ unreadOnly? })` | Retrieve in-app notification records. | `{ items, unreadCount }` | Service failure | Notifications, app shell |
| `updateNotification({ notificationId, read })` | Update one notification's read state. | `{ notification }` | Not found, access denied, service failure | Notifications |
| `updateProfile({ displayName, ...approvedFields })` | Update backend-approved profile values. | `{ user }` | Validation failure, access denied, service failure | Profile |

Shapes are illustrative and should be adjusted to the backend team's chosen domain model. The UI must not infer access rights from role values; server-side permissions remain authoritative.

## Video service boundary

The virtual classroom is a visual demo, not a video call. No camera or microphone is accessed, and no screen is shared. A future video adapter will need reviewed operations and events for:

- Create or retrieve meeting information for a class session.
- Join and exit a session, including clear handling of denied or expired access.
- Report camera and microphone state and user-controlled state changes.
- Provide participant identity/presence information for the UI.
- Start and stop screen sharing through the chosen service.
- Surface connection, participant, device-permission, and session-ended states.

The video team owns the SDK, signaling, transport, security, and service-specific request shape. The frontend should consume a small service contract and must not implement WebRTC or assume a provider.

## ML service boundary

Current study tools use deterministic sample content. The mock implementations can be replaced by adapters after request/response agreements are reviewed.

| Capability | Provisional input | Provisional output | UI caller |
| --- | --- | --- | --- |
| AI Mentor | `{ conversationId?, message, context? }` | `{ responseId, text, suggestedFollowUps? }` | AI Mentor |
| Quiz generation | `{ topic, difficulty, questionCount, questionTypes }` | `{ quizId, questions: [{ prompt, options?, answerFormat }] }` | Quiz Generator |
| Spam review | `{ conversationId, messageId?, text }` | `{ decision, reasonCode?, userMessage? }` | Chat moderation UI |

The ML team owns model selection, inference, training, moderation policy, and any model-service transport. The frontend owns rendering pending, result, retry, fallback, and reviewed/flagged states. The UI must not promise model accuracy or imply that the sample responder is a real AI system.

## Frontend demo behavior

- The current role-specific frontend accounts are `STU-1001` and `TCH-2001`. The shared illustrative access code is `learn2026`; the mock validates the ID, code, and portal match in frontend code. It stores only a local session, never the access code, and makes no network call. These fixtures are not production accounts or authentication.
- Student routes and teacher routes are separated in the UI. Route guards and browser-stored sessions are convenience behavior only and can be modified by a user; they must never be treated as trusted authorization.
- Registration creates only a local display name for the selected fixed account. It does not create a real account.
- Production integration must replace the mock auth adapter with the agreed Firebase/backend adapter. The trusted authenticated identity and role must come from Firebase/backend authentication and authorization, not from a client-selected role, URL, local storage, or any other editable browser value. The backend must enforce permissions for every protected operation; frontend route guards are supplementary UX only.
- Language (`en`/`hi`), theme (`dark`/`light`), and reduced-motion preferences are stored separately from authentication and role state. They are browser preferences, not user profile fields.
- Class creation, attendance edits, announcements, and messages remain local mock operations. Assignment creation and submission, material addition, notification read-state changes, and calendar retrieval use the configured backend in API mode; otherwise, their mock implementations are used.
- Chat additions are not delivered to another person. The current phrase check is a deterministic sample rule, not a spam model.
- Selecting an assignment file alone does not upload it. Submitting uploads the file when API mode is enabled; in mock mode, submission remains a local preview.
- Classroom controls change visible state only; they do not access devices or create a call.
- Mentor responses and quiz questions are predefined sample content; no model or inference API is connected.
- Newsletter and password-recovery forms confirm that no email is sent.

## ML frontend operation mapping

These are frontend contract concepts for review, not approved endpoints. The ML teammate should confirm request/response shape, model behavior, rate limits, moderation policy, and errors before implementation.

| Current frontend operation | Purpose | Provisional input | Provisional output | Errors the UI must handle |
| --- | --- | --- | --- | --- |
| `askMentor(prompt)` in `apps/web/src/services/mock/mockStudyService.js` | Answer a learner's study question with relevant lesson context. | `{ conversationId?, message, classId?, subject?, context? }` | `{ responseId, text, suggestedFollowUps? }` | Invalid/empty prompt, unavailable model, timeout, safety refusal, rate limit |
| `generateQuiz({ count })` in `apps/web/src/services/mock/mockStudyService.js` | Generate practice questions for a topic, difficulty, and requested count. | `{ topic, difficulty, questionCount, questionTypes?, context? }` | `{ quizId, questions: [{ id, prompt, options?, answerFormat }] }` | Invalid topic/count, unsupported question type, unavailable model, timeout |
| `checkMessage(text)` in `apps/web/src/services/mock/mockStudyService.js` | Assess a message for spam/abuse before display or submission. | `{ conversationId, messageId?, text, locale? }` | `{ decision, reasonCode?, userMessage? }` | Unavailable moderation service, timeout, invalid text; define fail-open/closed policy with backend/product |

The React pages should continue calling these named frontend operations. The existing adapter handles the supported backend APIs through `apps/web/src/services/index.js`; other operations should be connected only after their API contracts are agreed.
