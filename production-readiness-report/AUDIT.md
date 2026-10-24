# Production Readiness Technical Audit

**Project:** Unified Learning & Virtual Classroom App  
**Target Working Directory:** `C:\Users\adity\Downloads\brl-final_task--main (3)\brl-final_task--main-production-fix-work`  
**Baseline Reference (Untouched Original):** `C:\Users\adity\Downloads\brl-final_task--main (3)\brl-final_task--main-backup-original`  
**Git Repository Reference:** `C:\dev\brl-final_task-` (branch: `safety/production-readiness`, preserved untouched)  
**Date of Audit:** October 23, 2026  

---

## 1. System Architecture Overview

The system consists of four primary software layers:

```
                                +-----------------------------+
                                |      React Web Client       |
                                |       (Vite / Port 5173)    |
                                +--------------+--------------+
                                               |
                                               | REST API (HTTP 5000)
                                               v
+-------------------------+     +-----------------------------+     +-------------------------+
|   Flutter Mobile App    |     |     Root Unified Backend    |     |   apps/backend Sub-API  |
|       (Dart/Dio)        |     |      (Node/Express 5000)    |     |    (Node/Express 5001)  |
+------------+------------+     +--------------+--------------+     +------------+------------+
             |                                 |                                 |
             | ML REST (HTTP 8001)             | Mongoose                        | Mongoose
             v                                 v                                 v
+-------------------------+     +-----------------------------+     +-------------------------+
|    Python ML Service    |     |      MongoDB Database       |     |   Isolated / Redundant  |
|    (FastAPI / 8001)     |     |   (mongodb://127.0.0.1)     |     |      Database Copy      |
+-------------------------+     +-----------------------------+     +-------------------------+
```

### Canonical Backend Determination
- **Root Backend (`server.js`)**: **Canonical**. Implements complete user authentication (`/api/auth`), classroom spaces (`/api/classrooms`), assignments (`/api/assignments`), submissions (`/api/submissions`), learning materials (`/api/materials`), calendar deadlining (`/api/calendar`), notifications (`/api/notifications`), dynamic database health reporting (`/api/health`), and Socket.IO real-time events (`src/sockets/handRaise.js`).
- **`apps/backend/src/server.js`**: **Sub-backend / Redundant**. Contains only assignments, submissions, materials, notifications, and calendar. It lacks user authentication, classroom management, and real-time sockets.
- **Client Consumer Wiring**:
  - `apps/web`: Points to `VITE_API_BASE_URL` defaulting to `http://localhost:5000/api` (Root Backend).
  - `apps/mobile`: Configured via `dio_client.dart` to call `ML_API_BASE_URL` defaulting to `http://192.168.0.105:8001` (ML microservice).
- **Port Conflict Resolution**:
  - Root Backend: Port 5000 (`PORT=5000`)
  - `apps/backend`: Port 5001 (`PORT=5001` configured in `.env.example` and `server.js`)
  - ML Microservice: Port 8001 (`PORT=8001`)
  - React Web Frontend: Port 5173 (`PORT=5173`)

---

## 2. Confirmed Feature Status

| Feature Area | Implementation Status | Functional Level | Verification Method |
| :--- | :--- | :--- | :--- |
| **Authentication & RBAC** | Implemented (Teacher & Student roles) | Operational; fails closed with HTTP 503 if Firebase unconfigured | Integration suite (`test-backend-integration.js`) |
| **Classrooms** | Implemented | Operational (Create, Join by code, List by role) | In-memory MongoDB suite |
| **Assignments & Deadlines** | Implemented | Operational (CRUD, maxMarks, due dates, late flag) | Integration tests |
| **Submissions & Grading** | Implemented | Operational (Text-only, multipart upload, resubmission, grading) | Integration tests |
| **Learning Materials** | Implemented | Operational (Images, notes, videos, link-based documents) | Integration tests |
| **Calendar Deadlines** | Implemented | Operational (Aggregates assignment deadlines by month) | Contract adapter test |
| **In-App Notifications** | Implemented | Operational (Auto-generated on grading, mark read, unread count) | Integration tests |
| **Chat Spam Detection** | Implemented | Operational (TF-IDF + Naive Bayes, strike tracking, unblock) | FastAPI TestClient |
| **Audio Noise Cancellation**| Implemented | Operational (Spectral gating noisereduce on 16kHz WAV) | FastAPI TestClient |
| **AI Mentor Chatbot** | Implemented | Operational (LangChain Groq pipeline; HTTP 502 on missing key) | FastAPI TestClient |
| **Live Web Video Meeting** | Mock / UI Only | Visual interface only; no WebRTC media server attached | Code audit of `ClassroomView` |
| **Attendance Tracking** | 0-Byte Stub | Not implemented (`attendanceController.js` is 0 bytes) | Code audit |
| **Persistent Room Chat** | 0-Byte Stub | In-memory React state only (`chatController.js` is 0 bytes) | Code audit |
| **Homework Model** | 0-Byte Stub | Redundant; covered under Assignment model | Code audit |

---

## 3. Security and Reliability Findings

1. **Authentication Fail-Closed Guarantee**:
   - `config/firebase.js` now validates credentials before calling `admin.initializeApp()`.
   - `src/middleware/authMiddleware.js` and `src/sockets/handRaise.js` gracefully fail closed with `HTTP 503 Service Unavailable` if Firebase is unconfigured, preventing unauthorized access or server crashes.
2. **Dynamic Database Health Reporting**:
   - `/api/health` dynamically queries `mongoose.connection.readyState === 1`.
   - Returns `HTTP 200` with `{ status: "ok", database: "connected" }` when healthy.
   - Returns `HTTP 503` with `{ status: "degraded", database: "disconnected" }` when MongoDB is offline.
3. **Storage & Cloudinary Fail-Safety**:
   - Unconfigured Cloudinary uploads return clean `HTTP 503 Service Unavailable: Storage service not configured. Unable to upload file.`.
   - Text-only submissions and URL-based materials succeed without Cloudinary.
   - Deferred cleanup: Previous cloud assets are deleted only *after* the database update has succeeded. If a database write fails, the newly uploaded asset is safely rolled back, preventing orphaned assets or corrupted records.
4. **Secret Leakage Prevention**:
   - Upstream LLM errors in the ML service are logged internally; clients receive a sanitized `HTTP 502` payload (`{"detail": "The AI Mentor service is currently unavailable. Please try again."}`) with zero leaked filesystem paths or API keys.
   - No `.env` files or service account JSON files are committed to version control.

---

## 4. Remaining Blockers & Required Environment Variables

To run the complete stack live in production, the following environment variables are required by name only:

### Root Backend (`.env`)
- `PORT` (e.g. 5000)
- `MONGO_URI` (MongoDB connection string)
- `CLOUDINARY_CLOUD_NAME` (Cloudinary cloud name)
- `CLOUDINARY_API_KEY` (Cloudinary API key)
- `CLOUDINARY_API_SECRET` (Cloudinary API secret)
- `FIREBASE_PROJECT_ID` (Firebase project ID)
- `FIREBASE_CLIENT_EMAIL` (Firebase service account client email)
- `FIREBASE_PRIVATE_KEY` (Firebase service account private key)

### ML Microservice (`ml_service/.env`)
- `GROQ_API_KEY` (Groq API key for Llama 3 / Mixtral inference)
- `GROQ_MODEL` (Optional model name override, e.g. `llama-3.1-70b-versatile`)

### React Web Frontend (`apps/web/.env.production`)
- `VITE_API_BASE_URL` (Base URL pointing to Root Backend, e.g. `https://api.yourdomain.com/api`)
- `VITE_DATA_MODE` (`api` for real backend integration, or `mock` for local prototype preview)

### Flutter Mobile App (`apps/mobile`)
- `ML_API_BASE_URL` (Passed via `--dart-define=ML_API_BASE_URL=...` pointing to the ML service)
