# Unified Learning - Backend API

REST API for the Unified Learning & Virtual Classroom app (web + mobile).
This part covers: Assignments, Submissions, Grading, Notifications, Learning Materials and Calendar.

## Tech Stack

- Node.js and Express
- MongoDB with Mongoose
- Multer and Cloudinary (file uploads)

## Setup

1. Go to the backend folder:
```bash
   cd apps/backend
```
2. Install packages:
```bash
   npm install
```
3. Create a `.env` file (copy `.env.example`) and fill in your values.
4. Start the server:
```bash
   npm run dev
```
5. Check it works: open http://localhost:5000/api/health

## Environment Variables

| Name | Meaning |
|---|---|
| PORT | Server port (default 5000) |
| MONGO_URI | MongoDB connection string |
| CLOUDINARY_CLOUD_NAME | Cloudinary cloud name |
| CLOUDINARY_API_KEY | Cloudinary API key |
| CLOUDINARY_API_SECRET | Cloudinary API secret |

Never commit the real `.env` file.

## Response Format

Every response looks like this:

```json
{ "success": true, "message": "optional text", "data": {} }
```

On error: `{ "success": false, "message": "what went wrong" }`

## API Endpoints

### Assignments

| Action | Method and URL |
|---|---|
| Create (files in field `files`) | POST /api/assignments |
| List by class | GET /api/assignments/class/:classId |
| Get one | GET /api/assignments/:id |
| Update | PUT /api/assignments/:id |
| Delete | DELETE /api/assignments/:id |

Create body (form-data or JSON): `classId`, `createdBy`, `title`, `description`, `dueDate`, `maxMarks`

### Submissions and Grading

| Action | Method and URL |
|---|---|
| Submit (resubmit updates the same one) | POST /api/submissions/assignment/:assignmentId |
| All submissions (teacher) | GET /api/submissions/assignment/:assignmentId |
| One student's submission | GET /api/submissions/assignment/:assignmentId/student/:studentId |
| Grade | PUT /api/submissions/:id/grade |

Submit body (form-data): `studentId`, `text`, `file`
Grade body (JSON): `{ "marks": 40, "feedback": "Good work" }`
Late submissions are flagged with `isLate: true`.

### Notifications

| Action | Method and URL |
|---|---|
| List for a user | GET /api/notifications/user/:userId |
| Unread count | GET /api/notifications/user/:userId/unread-count |
| Mark one as read | PUT /api/notifications/:id/read |
| Mark all as read | PUT /api/notifications/user/:userId/read-all |

A notification is created automatically when a teacher grades a submission.

### Learning Materials

| Action | Method and URL |
|---|---|
| Upload (form-data: `classId`, `uploadedBy`, `title`, `description`, `file` or `link`) | POST /api/materials |
| List by class (optional `?type=note|image|video|link`) | GET /api/materials/class/:classId |
| Get one | GET /api/materials/:id |
| Delete | DELETE /api/materials/:id |

### Calendar

| Action | Method and URL |
|---|---|
| Deadlines of a class (optional `?month=YYYY-MM`) | GET /api/calendar/class/:classId |

### Health

GET /api/health

## File Uploads

- Send files as `multipart/form-data`.
- Allowed types: pdf, doc, docx, ppt, pptx, txt, png, jpg, jpeg, mp4, zip (max 20 MB).
- Files are stored on Cloudinary and the API returns a full https link.

## Pending

- Firebase auth middleware and teacher/student role checks
- Notification when a new assignment is created