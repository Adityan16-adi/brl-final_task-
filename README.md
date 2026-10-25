# Pragti — Learn · Connect · Grow

Pragti is a unified education platform merging Google Classroom (coursework, assignments with grading, attendance, announcements, study materials, chat with ML spam filtering) and Google Meet (live interactive video classrooms, lobby readiness checks, WebRTC streaming, and zero-config Jitsi Meet / Google Meet fallback).

Built with a tactile **Claymorphism** design system on Flutter, backed by a robust Node.js/Express API, and powered by a Python FastAPI machine learning microservice.

---

## 🏗️ Architecture & Component Overview

| Service | Technology | Port / Platform | Description |
| :--- | :--- | :--- | :--- |
| **Core Backend** | Node.js (v18+), Express, Socket.IO, Mongoose | `http://localhost:5000` | REST API, classroom management, attendance, coursework, JWT auth, WebRTC signaling |
| **ML Microservice** | Python 3.10+, FastAPI, Uvicorn | `http://localhost:8001` | Content moderation, ML spam detection, AI tutor summaries |
| **Mobile App** | Flutter 3.13+, Riverpod, Dio | Android APK, Web, iOS | Soft-clay responsive mobile application with teacher/student workspaces |
| **Database** | MongoDB Atlas / In-Memory MongoDB | Port 27017 or in-memory | Automatic fallback to local in-memory MongoDB in development (zero external DB required to demo) |

---

## ⚡ Quick Demo Launch (PowerShell)

Follow these simple steps in three separate PowerShell windows to launch the full system locally.

### Step 1: Start the Core Backend (Port 5000)

```powershell
# From the repository root:
npm install
node server.js
```

*Note: In development, if an external MongoDB connection is not provided, the backend automatically boots a local in-memory MongoDB instance and seeds demo teacher, student, and classroom accounts automatically.*

### Step 2: Start the ML Microservice (Port 8001)

```powershell
# In a new PowerShell window, from repository root:
cd ml_service

# Activate the virtual environment
.\.venv\Scripts\Activate.ps1

# Start the FastAPI service
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### Step 3: Run the Flutter Mobile Application

```powershell
# In a third PowerShell window, from repository root:
cd apps/mobile

# Run on an available Android device or emulator
flutter run

# Or run on Chrome / Web server:
flutter run -d chrome
```

---

## 👤 Instant Evaluation Accounts

The backend and mobile application include pre-configured demonstration accounts for immediate feature review:

| Role | Email | Password | Pre-seeded Classroom |
| :--- | :--- | :--- | :--- |
| **Instructor / Teacher** | `teacher@demo.com` | `demo1234` | Physics 101 (`PHY101`) |
| **Student / Learner** | `student@demo.com` | `demo1234` | Enrolled in Physics 101 |

*Tip: On the mobile welcome and login screens, you can also tap **"Explore in Demo Mode (Offline)"** or the quick-login pills for zero-network instantaneous evaluation.*

---

## ⚙️ Custom Configuration via `--dart-define`

When deploying or testing on physical devices, override service endpoints without modifying code:

```powershell
flutter run `
  --dart-define=CORE_API_BASE_URL=http://192.168.1.100:5000 `
  --dart-define=ML_API_BASE_URL=http://192.168.1.100:8001
```

Default endpoint resolutions:
- **Android Emulator**: Automatically routes to `http://10.0.2.2:5000` and `http://10.0.2.2:8001`.
- **Web / Desktop / Simulators**: Automatically routes to `http://localhost:5000` and `http://localhost:8001`.

---

## 🧪 Test Suites & Verification

All test suites can be executed independently:

```powershell
# 1. Backend integration test suite (34 checks)
node test-backend-integration.js

# 2. Authentication, RBAC & LiveKit security test suite (31 checks)
node test-real-auth.js

# 3. Full classroom & assignment end-to-end flow
node test-e2e-classroom-assignment-flow.js

# 4. Flutter unit and widget test suites (71 tests across 12 suites)
cd apps/mobile
flutter test
```
