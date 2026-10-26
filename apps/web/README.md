# Unified Learn web app

## Configuration

Copy `.env.example` to `.env.local` and restart Vite after changing it. Use `VITE_DATA_MODE=mock` for the local preview, which needs no Firebase settings. Use `VITE_DATA_MODE=api` for protected backend data and set the four Firebase Web app values shown in the example. Firebase client configuration is public; never put service account credentials, private keys, MongoDB credentials, or Cloudinary secrets in a `VITE_` variable.

`VITE_API_BASE_URL` must be reachable by the user's browser. For a Codespace, use the forwarded backend URL rather than `localhost`. The Node backend must allow the frontend origin through `WEB_ORIGIN` (for example, set it to the frontend's full origin, such as `https://<frontend-port>-<codespace>.<domain>`; the current server accepts a comma-separated origin list). A browser CORS error cannot be fixed by changing the frontend URL alone if that origin is not allowed.

API mode uses Firebase email/password sign-in and requires an existing MongoDB user whose `uid` equals the Firebase UID. The backend's `GET /api/auth/me` response supplies the trusted `id`, `name`, `email`, and `role`. A missing profile or role mismatch ends the session with a clear error. Registration and role provisioning are administrator operations in the current system; the frontend does not create a local substitute. Password reset uses Firebase's existing email reset capability.

## Existing API contracts used by the frontend

All listed routes are under `VITE_API_BASE_URL`, require a Firebase ID token in `Authorization: Bearer <token>`, and preserve the backend's `{ success, data }` response envelope.

| Method and route | Frontend use |
| --- | --- |
| `GET /auth/me` | Resolve the backend profile and role |
| `GET /assignments/class/:classId` | List authorized class assignments |
| `GET /assignments/:id` | Read one authorized assignment |
| `POST /assignments` | Create with `classId`, `title`, `dueDate`, optional `description`, `maxMarks` |
| `POST /submissions/assignment/:assignmentId` | Submit multipart `file` and/or `text` |
| `GET /submissions/assignment/:assignmentId/me` | Read the current student's submission |
| `GET /materials/class/:classId` | List class materials |
| `POST /materials` | Create multipart `classId`, `title`, `description`, `link` and/or `file` |
| `GET /notifications/me` | List the current user's notifications |
| `PUT /notifications/:id/read` | Mark one notification read |
| `PUT /notifications/me/read-all` | Mark all current-user notifications read |
| `GET /calendar/class/:classId?month=YYYY-MM` | List assignment deadlines for a class/month |
| `POST /study/mentor` | Send `{ message }` and read `{ text }` |
| `POST /study/quiz` | Send `{ text, count, difficulty }`; lesson notes are required |

Class and account authorization remains a backend decision. `VITE_DEMO_CLASS_ID` selects the class used by existing class-scoped screens; it is not an authentication credential. Protected requests acquire a fresh Firebase ID token from the active Firebase user. Multipart requests leave `Content-Type` to `fetch` so it can add the boundary.

Classes, attendance, timetable, announcements, chat, and some profile/settings features still use the existing local preview services because the current frontend/backend integration does not expose their matching API operations. API errors never switch those supported services to mock data.

## Checks

Run `npm run lint` and `npm run build` from this directory.
