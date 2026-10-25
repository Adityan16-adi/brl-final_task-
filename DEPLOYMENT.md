# Unified Learning & Virtual Classroom — Production Deployment Guide

## 1. System Architecture Overview

The Unified Learning & Virtual Classroom platform comprises three core functional components:

1. **Core Backend (`apps/backend` or root `server.js`)**:
   - Runtime: Node.js (v20+ / v22+)
   - Framework: Express.js & Socket.IO
   - Responsibilities: REST APIs (Classrooms, Assignments, Submissions, Materials, Attendance, Notifications), Cryptographic JWT Authentication & RBAC, Hand-raising and participant presence signaling, LiveKit room token minting.
   - Default Port: `5000` (binds to `0.0.0.0:PORT`)

2. **ML & AI Service (`ml_service/`)**:
   - Runtime: Python 3.12 (Requires 3.12.x for `faiss-cpu` and `faster-whisper` C++ binary wheel compatibility)
   - Framework: FastAPI & Uvicorn
   - Responsibilities: Real-time spam detection, note summarization, automated quiz question generation, RAG-augmented AI mentor (`mentor/chat`), live audio transcription (`/ws/captions`), and WAV audio denoising.
   - Default Port: `8001` (binds to `0.0.0.0:8001`)

3. **Client Applications**:
   - **Flutter Mobile (`apps/mobile/`)**: Android, iOS, and Web client built with Riverpod state management, custom Claymorphism design system, and LiveKit WebRTC video room integration.
   - Note: `apps/web/` is strictly isolated and unaffected by backend deployment changes.

---

## 2. Deployment Matrix

| Service | Working Directory | Build Command | Start Command | Required Environment Variables | Health & Readiness Endpoints | Database / Infrastructure Dependencies | External Account Requirements |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Core Backend** | `.` (or `apps/backend`) | `npm install --omit=dev` | `npm start` (`node server.js`) | `PORT`, `NODE_ENV`, `MONGO_URI`, `JWT_SECRET`, `TEACHER_SIGNUP_KEY`, `ML_SERVICE_URL`, `LIVEKIT_*` (optional), `CLOUDINARY_*` (optional), `FIREBASE_*` (optional) | `GET /api/health`<br>`GET /health`<br>`GET /api/ready` | MongoDB 6.0+ (Mongoose)<br>Persistent storage volume (`./uploads` fallback) | MongoDB Atlas (if managed), Cloudinary (for cloud media), LiveKit Cloud (for video calls), Firebase (for social login) |
| **ML & AI Service** | `ml_service/` | `pip install -r requirements.txt` | `uvicorn main:app --host 0.0.0.0 --port 8001` | `PORT`, `GROQ_API_KEY`, `GROQ_MODEL`, `WHISPER_MODEL` | `GET /health`<br>`GET /docs`<br>`GET /` | CPU/RAM (Min 2GB for FAISS & MiniLM embedding model) | Groq Cloud account (Free tier at https://console.groq.com) |
| **Flutter Mobile** | `apps/mobile/` | `flutter build apk --release` (or `flutter build appbundle`) | `flutter run` | `--dart-define` parameters:<br>`CORE_API_BASE_URL`<br>`ML_API_BASE_URL` | N/A (Client application) | Network access to ports 5000 and 8001 | Google Play Console / Apple Developer (for store releases) |

---

## 3. Deep-Dive Architectural & Security Determinations

### A. Production Security & Teacher Privilege Escalation
- **Strict JWT Secret Enforcement**: In production mode (`NODE_ENV=production`), `server.js` startup and `/api/ready` safely fail closed if `JWT_SECRET` is missing, default, or shorter than 32 characters.
- **Teacher Self-Registration Protection**: In production mode, the default code `TEACHER_INVITE_2026` is **explicitly forbidden**. An administrator MUST supply a strong `TEACHER_SIGNUP_KEY` (minimum 16 characters). If missing or unconfigured, teacher registration returns HTTP 403 Forbidden, closing all unauthorized privilege escalation vectors.
- **Production Mock Token Rejection**: When `NODE_ENV=production`, all development mock tokens (`mock-jwt-token-`) are rejected with HTTP 401 Unauthorized across both REST endpoints and Socket.IO handshakes.
- **Password Hash Security**: User model uses `passwordHash: { select: false }`, ensuring hashes are never returned in queries or API payloads.

### B. LiveKit WebRTC Video Meetings
- **Architecture**: `livekit-server-sdk` is integrated on the backend to mint short-lived (4-hour) room tokens (`POST /api/classrooms/:id/meeting/token`).
- **Access Control**: Only verified teachers and enrolled students can request tokens for a classroom.
- **Mobile Client**: Flutter application includes `livekit_client` and `LiveMeetingScreen` rendering video tracks, local/remote participants, and media toggles.
- **Awaiting Credentials State**: When `LIVEKIT_API_KEY` is not set, the endpoint safely returns HTTP 503 with `"status": "awaiting_credentials"`, and the mobile app displays an informational setup modal.

### C. Socket.IO & Realtime Hand-Raising
- **Sticky Sessions**: Socket.IO connections negotiate via HTTP long-polling before upgrading to WebSockets. When deploying behind a load balancer (such as AWS ALB, GCP Load Balancer, or Nginx) across multiple backend instances:
  - **Sticky sessions (session affinity)** MUST be enabled so the handshake and subsequent polling packets hit the same instance.
  - Alternatively, force WebSockets only in the client options: `io(url, { transports: ['websocket'] })`.
- **Multi-Instance Pub/Sub**: If the backend is horizontally scaled across two or more instances:
  - Socket rooms (`classroom:<id>`) reside in Node.js process memory.
  - To broadcast hand-raise and classroom events across instances, attach a Redis Pub/Sub adapter (`@socket.io/redis-adapter`) and a Redis service (included in `docker-compose.yml`).

### D. Local Filesystem Persistence vs Cloud Storage
- **Local Fallback**: When Cloudinary credentials are not provided, `uploadToCloudinary.js` writes uploaded files to `./uploads` and serves them statically via `/uploads/...`.
- **Deployment Warning**: In ephemeral container environments (e.g., AWS ECS, Render, Fly.io, Heroku, or GCP Cloud Run), local files are destroyed whenever the container restarts or redeploys!
- **Recommendation**:
  1. For single-instance Docker: Mount a persistent named volume to `/app/uploads` (already configured in `docker-compose.yml` and `render.yaml`).
  2. For serverless/multi-instance cloud: Provide valid `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and `CLOUDINARY_API_SECRET` so all assets reside safely in cloud object storage.

### E. Python Runtime Selection
- **Selected Version**: **Python 3.12 (3.12.x)**.
- **Compatibility Constraint**: Do not use Python 3.13 or 3.14 on Linux or Windows. Key dependencies (`faiss-cpu`, `ctranslate2`, and `faster-whisper`) lack precompiled binary wheels for Python >= 3.13.

---

## 4. Production Deployment Methods

### Option 1: Render Deployment via Blueprint (`render.yaml`) (Recommended)

The repository includes a ready-to-use [`render.yaml`](file:///C:/Users/adity/Downloads/brl-final_task--main%20(3)/brl-final_task--main/render.yaml) blueprint:

1. Push your repository to GitHub / GitLab.
2. In the [Render Dashboard](https://dashboard.render.com), click **New** -> **Blueprint**.
3. Connect your repository. Render automatically discovers both services:
   - `smart-classroom-backend` (Docker, Node.js 22, persistent disk `/app/uploads`, healthcheck `/api/ready`)
   - `smart-classroom-ml` (Docker, Python 3.12, healthcheck `/health`)
4. Fill in the environment prompts:
   - `MONGO_URI`: Enter your MongoDB Atlas connection string (see Section 5 below).
   - `JWT_SECRET`: Auto-generated by Render (32+ chars).
   - `TEACHER_SIGNUP_KEY`: Auto-generated by Render (32+ chars).
   - `GROQ_API_KEY`: Enter your Groq API key (starts with `gsk_...`).
   - `CLOUDINARY_*` and `LIVEKIT_*` (optional, for cloud media and video calls).
5. Click **Apply**. Render builds the Docker containers and deploys with zero downtime.

---

### Option 2: Full-Stack Docker Compose (Recommended for VPS / Cloud VM)

1. Clone repository to your production server:
   ```bash
   git clone <repo-url>
   cd brl-final_task--main
   ```
2. Create production environment file:
   ```bash
   cp .env.production.example .env
   ```
3. Edit `.env` with your secure production values (`JWT_SECRET`, `TEACHER_SIGNUP_KEY`, `GROQ_API_KEY`, etc.).
4. Launch the stack:
   ```bash
   docker compose up -d --build
   ```
5. Verify health:
   ```bash
   curl http://localhost:5000/api/ready
   curl http://localhost:8001/health
   ```

---

## 5. Exact Manual Setup Steps Required From You

### 1. MongoDB Atlas Managed Database Setup
1. Create a free account at [MongoDB Atlas](https://www.mongodb.com/atlas).
2. Create a new cluster (Shared M0 is free).
3. **Database Access**: Click **Database Access** -> **Add New Database User**:
   - Authentication Method: Password.
   - User Privileges: `Read and write to any database` (or `readWrite` on `unified_learn`).
   - Copy the username and strong password.
4. **Network Access**: Click **Network Access** -> **Add IP Address**:
   - For Render or dynamic cloud hosts: Select **Allow Access from Anywhere** (`0.0.0.0/0`).
5. **Connection String**: Click **Database** -> **Connect** -> **Drivers** (Node.js):
   - Copy the connection string format:
     `mongodb+srv://<username>:<password>@cluster0.mongodb.net/unified_learn?retryWrites=true&w=majority`
   - Replace `<username>` and `<password>` with your database user credentials.
   - Set as `MONGO_URI` in Render or `.env`.

### 2. LiveKit Cloud (Video Meetings)
1. Sign up for a free project at [LiveKit Cloud](https://cloud.livekit.io).
2. Under **Project Settings** -> **Keys**:
   - Copy `LIVEKIT_URL` (e.g., `wss://your-project.livekit.cloud`).
   - Copy `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET`.
3. Add these 3 variables to your backend `.env` or Render environment settings.

### 3. Groq Cloud (AI Mentor, Quiz, Summarization)
1. Sign up at [Groq Console](https://console.groq.com) (free).
2. Create an API key starting with `gsk_...`.
3. Add `GROQ_API_KEY=gsk_...` to `ml_service/.env` or Render environment settings.

### 4. Cloudinary (Permanent File Storage)
1. Sign up at [Cloudinary](https://cloudinary.com).
2. In Dashboard, copy Cloud Name, API Key, and API Secret.
3. Add `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and `CLOUDINARY_API_SECRET` to backend `.env`.

### 5. Compile Flutter Mobile App for Production
Run the build command with `--dart-define` targeting your deployed backend and ML service:
```bash
cd apps/mobile
flutter build apk --release \
  --dart-define=CORE_API_BASE_URL=https://smart-classroom-backend.onrender.com \
  --dart-define=ML_API_BASE_URL=https://smart-classroom-ml.onrender.com
```
