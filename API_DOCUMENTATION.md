# Unified Learn API

## Canonical services

The React web adapter uses the `apps/backend` Node API at `http://localhost:5000/api`. Root `server.js` owns legacy Firebase identity sync and classroom operations on port 3000. `apps/backend` owns assignments, submissions, materials, notifications, calendar, and the controlled study-tool proxy on port 5000. Duplicate data route mounts were removed from the legacy server. Both services share MongoDB user and classroom collections. The Python service is internal at `http://127.0.0.1:8001` by default.

## Authentication and authorization

All data and study routes require `Authorization: Bearer <Firebase ID token>`. The API verifies the token using Firebase Admin Application Default Credentials, then loads the server-side user record from MongoDB (`users` collection). The role and user ID always come from that record. Assignment/material/calendar access also checks the corresponding class's teacher UID or student membership. Writes require the class teacher; submissions require a student; grading requires the class teacher. Notifications are scoped to the authenticated user.

`GET /api/auth/me` returns `{ success, data: { id, name, email, role } }`. User records are currently synchronized through the legacy root service's `POST /api/auth/sync`; teacher role assignment remains an administrative database operation. The web app's demo login is not Firebase authentication and cannot access protected APIs until Firebase web authentication is integrated. Never use demo IDs or local role values as authorization.

## Routes

All successful data endpoints return `{ success: true, data }` (health and error responses have their own status shape). Protected route errors use 400 for invalid input, 401 for missing/invalid tokens, 403 for denied access, 404 for missing records, 429 for upstream rate limits when returned, 503 for unavailable services, and 502/504 for upstream failures/timeouts.

| Method | Route | Contract |
|---|---|---|
| GET | `/api/health` | 200 only when MongoDB is connected; otherwise 503 |
| GET | `/api/auth/me` | Current server-side profile and role |
| GET | `/api/assignments/class/:classId` | Assignments for a class the caller belongs to |
| GET | `/api/assignments/:id` | Assignment detail after class membership check |
| POST | `/api/assignments` | Teacher only; JSON `classId,title,dueDate`, optional `description,maxMarks`; optional multipart `file` is supported on upload requests |
| POST | `/api/submissions/assignment/:assignmentId` | Student only; multipart `file` and/or `text`; repeat submissions update the student's existing record |
| GET | `/api/submissions/assignment/:assignmentId/me` | Current student's submission; returns `data: null` when not submitted |
| GET | `/api/submissions/assignment/:assignmentId` | Class teacher only; list submissions |
| PUT | `/api/submissions/:id/grade` | Assignment teacher only; JSON `marks`, optional `feedback` |
| GET | `/api/materials/class/:classId` | Class materials |
| POST | `/api/materials` | Class teacher only; multipart fields `classId,title,description,link,file`; must provide a link or file |
| GET | `/api/notifications/me` | Current user's notifications |
| PUT | `/api/notifications/:id/read` | Mark one owned notification read |
| PUT | `/api/notifications/me/read-all` | Mark caller's notifications read |
| GET | `/api/calendar/class/:classId?month=YYYY-MM` | Assignment deadlines in the UTC month interval |
| GET | `/api/study/health` | Node-to-Python health probe |
| POST | `/api/study/mentor` | JSON `{ message, sessionId?, courseId? }` -> `{ data: { text } }` |
| POST | `/api/study/quiz` | JSON `{ text, count?, difficulty? }`; lesson text is required |

Uploads are limited to 10 MiB and the MIME types configured in `apps/backend/src/middleware/upload.js`. File bytes are uploaded to Cloudinary and returned as secure URLs; the API does not claim a successful upload if Cloudinary fails.

## ML service

From `ml_service`, create/activate a Python virtual environment, install `requirements.txt`, copy `.env.example` to `.env`, configure `GROQ_API_KEY`, and run `uvicorn main:app --host 127.0.0.1 --port 8001`. The Node service uses `ML_SERVICE_URL` and `ML_TIMEOUT_MS`; model/provider keys stay in the Python environment and are never sent to the browser. Mentor and quiz use actual provider inference and return explicit errors for invalid input, missing provider setup, timeout, or service failure. The quiz page currently has no lesson-notes field, so its API-mode request fails validation visibly. Spam-review, captions, denoising, and summarization are not exposed through the web API.

## Legacy behavior and remaining gaps

The root service still owns Firebase token sync and classroom create/join/list routes on port 3000. Attendance, announcements, delivered messages, full web Firebase login, quiz source notes, and message review are not integrated into the web app.
