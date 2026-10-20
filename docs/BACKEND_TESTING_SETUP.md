# Frontend ↔ backend testing setup

This adapter connects the existing frontend service boundary to the endpoints present in `feature/backend-assignments`:

- `GET/POST /api/assignments` (listing is class-scoped)
- `GET /api/assignments/:id`
- `POST /api/submissions/assignment/:assignmentId`
- `GET /api/submissions/assignment/:assignmentId/student/:studentId`
- `GET/POST /api/materials` (listing is class-scoped)
- `GET/PUT /api/notifications/...`
- `GET /api/calendar/class/:classId`

## Configure

Copy `.env.example` to `.env.local` in the frontend root and replace the placeholder IDs with real 24-character MongoDB ObjectIds from the backend database. The frontend rejects missing or malformed IDs before making requests:

```env
VITE_DATA_MODE=api
VITE_API_BASE_URL=http://localhost:5000/api
VITE_DEMO_CLASS_ID=<real Classroom _id>
VITE_DEMO_TEACHER_ID=<real User _id for teacher>
VITE_DEMO_STUDENT_ID=<real User _id for student>
```

Restart `npm run dev` after changing environment variables. For a local backend, start the backend separately and check `GET http://localhost:5000/api/health`.

`VITE_DATA_MODE` must be `mock` or `api`. In `api` mode, missing or malformed IDs and failed requests are shown as errors; supported features do not fall back to mock records. Features without an implemented backend adapter continue to use their existing mock services.

The current backend models require MongoDB ObjectIds for `classId`, `createdBy`, `uploadedBy`, and `studentId`. The frontend demo IDs `STU-1001` and `TCH-2001` are not MongoDB IDs and cannot be sent to these endpoints. Backend login/authentication and user/class creation endpoints are not included in the supplied backend branch, so the current sign-in remains a local demo session. Do not use this setup as production authentication.

## What remains mock-only

The supplied backend branch does not provide class/user, attendance, announcements, chat, or authentication endpoints. Those existing frontend areas therefore remain on their existing mock services. AI Mentor and quiz generation remain on the ML mock service until the ML API contract is available. In API mode, failures for the supported endpoints are shown as errors and are not silently replaced with mock assignment/material/notification/calendar records.

The backend source also mounts `/api/assignments` twice in `src/server.js`; this is redundant and should be removed by the backend owner. This frontend adapter does not edit backend files.
