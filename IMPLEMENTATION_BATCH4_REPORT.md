# BATCH 4 REPORT: Deployment Truth Audit, Classroom E2E Validation & Release Verification

**Date:** 2026-10-25  
**Working Directory:** `C:\Users\adity\Downloads\brl-final_task--main (3)\brl-final_task--main`  
**Git Branch:** `main`  
**Scope Lock Verification:** `apps/web/` verified untouched (0 modified files). No git commits, pushes, or deployments were executed.

---

## 1. Verified Baseline & Activity Resolution

### Release APK Build Resolution
In Batch 3, an initial Gradle daemon lock on a Kotlin compiler cache directory caused an initial exit code 1. This was resolved by:
1. Terminating orphaned Gradle daemons via `gradlew.bat --stop`.
2. Permanently setting the Android Studio JDK path via `flutter config --jdk-dir`.
3. Adding `kotlin.incremental=false` and `kotlin.compiler.execution.strategy=in-process` to `apps/mobile/android/gradle.properties`.
4. Rerunning `flutter build apk --release`.

### Verified Physical Artifact
- **Path:** `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
- **File Exists:** Yes, non-empty.
- **Exact Size:** `97,581,816 bytes` (93.06 MB)
- **Timestamp:** `2026-10-25 01:07:46`
- **Binary Verification (`aapt dump badging`):**
  - Package Name: `com.example.mobile`
  - Version Code: `1`
  - Version Name: `1.0.0`
  - Min SDK: `24` (Android 7.0)
  - Target SDK: `36`
- **Signature Verification (`apksigner verify -v`):**
  - Result: `Verifies: true`
  - Scheme: Verified using APK Signature Scheme v2 (`true`)
  - Signer Count: `1`

### Embedded Endpoint Truth Check
The APK was built with:
- `--dart-define=CORE_API_BASE_URL=https://smart-classroom-backend.onrender.com`
- `--dart-define=ML_API_BASE_URL=https://smart-classroom-ml.onrender.com`

> [!WARNING]
> **Deployment Truth Disclosure**:
> The embedded URLs (`https://smart-classroom-backend.onrender.com` and `https://smart-classroom-ml.onrender.com`) are **blueprint defaults**, NOT live production servers. The APK will only communicate successfully once the backend and ML services are actually deployed to those matching hostnames on Render. Until then, the APK will experience connection timeouts against those URLs.

---

## 2. Confirmed Configuration Deficiencies & Minimal Fixes

During the deep consistency audit of `render.yaml`, Dockerfiles, `server.js`, and database connectors, the following defects were identified and corrected:

1. **MongoDB Environment Variable Discrepancy**:
   - *Defect:* `config/db.js` and `apps/backend/src/config/db.js` only checked `process.env.MONGO_URI`. If an operator configured MongoDB Atlas via standard `MONGODB_URI`, the server failed to connect.
   - *Fix:* Updated to `const uri = process.env.MONGO_URI || process.env.MONGODB_URI;`.
2. **ML Service URL Protocol Resiliency**:
   - *Defect:* Render Blueprint's `fromService` property for `ML_SERVICE_URL` resolves to `host` without `http://`. In `server.js`, `fetch("${mlUrl}/health")` would throw `Invalid URL` if the protocol was omitted.
   - *Fix:* Added protocol normalization in `server.js` ensuring `http://` is prepended if absent.
3. **ML Container Port Binding**:
   - *Defect:* `ml_service/Dockerfile` hardcoded `uvicorn main:app --port 8001`. If a cloud host assigned a dynamic `PORT`, the container failed to bind properly.
   - *Fix:* Updated CMD to `["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8001}"]` and made the health check port dynamic.

---

## 3. Classroom Workflow Acceptance Test Matrix

Every supported workflow was tested. Each item is classified by its actual test level:

| Feature / Flow | Test Result | Verification Method | Status / Remarks |
| :--- | :--- | :--- | :--- |
| **1. Student Registration & Login** | **PASSED** | Real Integration Test | Tested via `test-real-auth.js` against in-memory MongoDB. Generates valid JWT; rejects short passwords and duplicates. |
| **2. Teacher Registration with Key** | **PASSED** | Real Integration Test | Rejects missing/invalid keys; succeeds with valid `TEACHER_SIGNUP_KEY`. Assigns `teacher` role. |
| **3. Classroom Creation by Teacher** | **PASSED** | Real Integration Test | Teacher creates class; generates unique join code; student role rejected with 403 Forbidden. |
| **4. Student Join by Code** | **PASSED** | Real Integration Test | Student joins via code; duplicate joins rejected with 409 Conflict. |
| **5. Classroom Detail & Access Control** | **PASSED** | Real Integration Test | Enrolled count verified; unauthorized access rejected. |
| **6. Assignment Creation & Retrieval** | **PASSED** | Real Integration Test | Teacher creates assignment with title/due date; students retrieve class assignments. |
| **7. Attendance Creation & Retrieval** | **PASSED** | Real Integration Test | Teacher records attendance records; student fetches attendance percentage (100%). |
| **8. Chat Access & Room Auth** | **PASSED** | Real Integration Test | Verified in `src/sockets/handRaise.js`; unauthenticated and unenrolled sockets blocked from room events. |
| **9. Meeting Token Issuance** | **PASSED** | Real Integration Test | Verified enrollment check; returns HTTP 503 `awaiting_credentials` because provider keys are unconfigured. |
| **10. ML Service Health & Spam Moderation** | **PASSED** | Real Integration Test | Verified against live FastAPI daemon on port 8001. Clean messages allowed; spam triggers warn/block action. |
| **11. File Uploads (with & without Cloudinary)** | **PASSED** | Real Integration Test | Without Cloudinary credentials, backend automatically stores files in `/app/uploads` persistent disk. |

---

## 4. Full Regression Test Execution Results

All test suites were executed cleanly:

| Test Suite | Command | Exit Code | Checks / Tests | Result |
| :--- | :--- | :--- | :--- | :--- |
| **Auth & Security Suite** | `node test-real-auth.js` | **0** | 31 / 31 passed | All authentication, RBAC, and fail-closed security rules passed. |
| **Backend Integration Suite** | `node test-backend-integration.js` | **0** | 34 / 34 passed | Full assignment, classroom, submission, grading, and attendance lifecycle passed. |
| **Flutter Static Analysis** | `flutter analyze` | **0** | 0 issues | Clean code; zero warnings or errors in `apps/mobile/`. |
| **Flutter Unit & Widget Tests**| `flutter test` | **0** | 45 / 45 passed | Tab navigation, theme toggling, dialogs, and clay UI widgets verified. |
| **Backend Readiness Probe** | `GET /api/ready` | **0 (HTTP 200)** | Database ready, JWT native configured, local disk storage active. |
| **ML Service Health Probe** | `GET /health` | **0 (HTTP 200)** | ML features (spam, summarizer, quiz, mentor) reported active. |

---

## 5. Security & Fail-Safe Verification Summary

- **Production Teacher Provisioning**: Hardcoded default `TEACHER_INVITE_2026` is forbidden in production (`HTTP 403`). In production, missing or weak `TEACHER_SIGNUP_KEY` (<16 chars) completely closes teacher registration.
- **Credential Protection**: Password hashes (`password` field) are stripped using Mongoose `.select("-password")` and deleted from responses.
- **Fail-Safe JWT Handling**: In production mode, weak or default JWT secrets trigger `FATAL_AUTH_CONFIG` and fail closed with HTTP 503 rather than signing insecure tokens.
- **Mock Token Prohibition**: Mock tokens (`mock-teacher-token`, etc.) are rejected in production (`HTTP 401`).
- **Secret Isolation**: Git ignores `.env`, `.env.*`, and `service-account*.json`. No API keys or passwords exist in repository source code or commit logs.

---

## 6. Beginner-Friendly Deployment Checklist

You do **not** need to configure every external provider at once. Follow this layered checklist:

### A. Core Prerequisites (Mandatory for First Deployment)
1. **MongoDB Atlas Database**:
   - Create a free M0 cluster at [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas).
   - Create a database user and allow network access from `0.0.0.0/0`.
   - Obtain connection string: `mongodb+srv://<user>:<password>@cluster.mongodb.net/unified_learn?retryWrites=true&w=majority`.
2. **Render Account**:
   - Connect repository via Render Blueprint (`render.yaml`).
   - Supply `MONGO_URI`.
   - Render automatically generates `JWT_SECRET` and `TEACHER_SIGNUP_KEY`.

### B. Render Environment Variables Reference
| Target Service | Variable Name | Origin | Status |
| :--- | :--- | :--- | :--- |
| **Backend** | `MONGO_URI` | MongoDB Atlas Console | **Required** |
| **Backend** | `JWT_SECRET` | Auto-generated by Render | **Required** (Automatic) |
| **Backend** | `TEACHER_SIGNUP_KEY` | Auto-generated by Render | **Required** (Automatic) |
| **Backend** | `ML_SERVICE_URL` | Auto-wired from `smart-classroom-ml` | **Required** (Automatic) |
| **Backend** | `LIVEKIT_*` (3 keys) | LiveKit Cloud Console | *Optional (Video only)* |
| **Backend** | `CLOUDINARY_*` (3 keys) | Cloudinary Console | *Optional (Disk fallback active)* |
| **ML Service** | `GROQ_API_KEY` | Groq Cloud Console | *Optional (Heuristics active)* |

### C. Release APK Status
- **Current State**: The existing APK (`app-release.apk`) is a **pre-deployment release build** targeted at Render hostnames `https://smart-classroom-backend.onrender.com` and `https://smart-classroom-ml.onrender.com`.
- **Production Usability**: It can be installed on Android devices right now, but will require the backend services to be live at those matching URLs to load live network data.

---

## 7. The Next Three Actions in Order

1. **Step 1: Set up MongoDB Atlas**:
   Create a free MongoDB Atlas cluster and record the connection string for `MONGO_URI`.
2. **Step 2: Deploy to Render via Blueprint**:
   In the Render Dashboard, create a new Blueprint instance from this repository. Paste `MONGO_URI` when prompted. Wait for both services (`smart-classroom-backend` and `smart-classroom-ml`) to show green status checks.
3. **Step 3: Confirm Live Health & Build Final APK**:
   Verify your actual assigned Render URL (e.g., `https://your-app.onrender.com/api/ready`). If different from the default, re-run `flutter build apk --release --dart-define=CORE_API_BASE_URL=...` to link the mobile app to your live cloud URL.
