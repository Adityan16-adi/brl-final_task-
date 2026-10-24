# Technical Log of Changes Applied

**Project:** Unified Learning & Virtual Classroom App  
**Target Working Directory:** `C:\Users\adity\Downloads\brl-final_task--main (3)\brl-final_task--main-production-fix-work`  
**Baseline Reference:** `C:\Users\adity\Downloads\brl-final_task--main (3)\brl-final_task--main-backup-original`  

Every change applied to the isolated working copy is detailed below, categorized by subsystem, with the problem addressed, the solution implemented, and compatibility considerations.

---

## 1. Upload & Storage Subsystem

### `apps/backend/src/utils/uploadToCloudinary.js`
- **Bug/Risk Addressed**:
  1. Fatal import error: `require('../../config/cloudinary')` pointed to a non-existent path. The real configuration file resided at `../config/cloudinary`.
  2. Fake persistence fallback: When Cloudinary credentials were missing, the function returned a fabricated local string `/uploads/upload_<timestamp>.undefined` that created broken database records.
- **Exact Changes Applied**:
  1. Corrected require path to `../config/cloudinary`.
  2. Implemented `isCloudinaryConfigured()` to validate cloud environment variables.
  3. Replaced fake path generation with an explicit rejection: `reject(new Error('Cloud storage is not configured...'))`.
  4. Added and exported `deleteFromCloudinary(publicId, resourceType)` to enable safe cloud asset deletion.
- **Compatibility**: No breaking changes to existing valid upload flows; prevents corrupted records when credentials are absent.

### `src/utils/uploadToCloudinary.js`
- **Bug/Risk Addressed**: Returned fake local URL string `/uploads/...` when Cloudinary credentials were not provided, giving a false appearance of persistence.
- **Exact Changes Applied**:
  1. Exported `isCloudinaryConfigured()` and `deleteFromCloudinary(publicId, resourceType)`.
  2. Replaced fallback with explicit rejection when Cloudinary is unconfigured.
  3. Validated incoming buffer before initiating stream.
- **Compatibility**: Prevents invalid records in MongoDB; compatible with existing stream interface.

### `src/middleware/upload.js` & `apps/backend/src/middleware/upload.js`
- **Bug/Risk Addressed**:
  1. File filter rejected video MIME types (`video/mp4`, `video/webm`, `video/quicktime`) and `image/webp` despite frontend UI allowing them.
  2. Upload size limit was low, causing silent rejections of student document packages.
- **Exact Changes Applied**:
  1. Extended `allowedTypes` array to include `video/mp4`, `video/webm`, `video/quicktime`, and `image/webp`.
  2. Standardized upload file size limit at 25MB (`limits: { fileSize: 25 * 1024 * 1024 }`).
- **Compatibility**: Backward compatible with all existing document types (`pdf`, `doc`, `docx`, `png`, `jpg`).

### `apps/backend/src/models/Submission.js` & `apps/backend/src/models/Material.js`
- **Bug/Risk Addressed**: Mongoose schemas lacked `filePublicId` and `fileResourceType` fields, preventing cloud asset tracking and deletion.
- **Exact Changes Applied**: Added `filePublicId: { type: String, default: "" }` and `fileResourceType: { type: String, default: "" }`.
- **Compatibility**: Non-breaking schema extension; matches root model definitions.

### Assignment, Submission & Material Controllers
*(Files: `src/controllers/submissionController.js`, `apps/backend/src/controllers/submissionController.js`, `src/controllers/assignmentController.js`, `apps/backend/src/controllers/assignmentController.js`, `src/controllers/materialController.js`, `apps/backend/src/controllers/materialController.js`)*
- **Bug/Risk Addressed**:
  1. Unconfigured Cloudinary uploads triggered unhandled 500 server crashes.
  2. Deleting or updating records with previous files left orphaned assets in Cloudinary.
  3. Premature deletion: Deleting old assets before the database update succeeded caused permanent data loss if the DB write failed.
  4. Text-only resubmissions accidentally wiped previously uploaded file metadata.
- **Exact Changes Applied**:
  1. Replaced unhandled 500s with `HTTP 503 Service Unavailable: Storage service not configured. Unable to upload file.` when Cloudinary is missing.
  2. Implemented deferred asset cleanup: Old files are destroyed via `deleteFromCloudinary` only *after* `findOneAndUpdate` / `findByIdAndUpdate` succeeds.
  3. Implemented rollback cleanup: If a new file is uploaded to Cloudinary but the database write fails, the newly uploaded asset is safely removed.
  4. Preserved `fileUrl`, `filePublicId`, and `fileResourceType` when students resubmit with text only.
- **Compatibility**: Preserves all existing REST API request/response contracts while establishing transactional data safety.

---

## 2. Authentication & Security Subsystem

### `config/firebase.js`
- **Bug/Risk Addressed**:
  1. Crashed on startup or logged private keys to stdout if credentials were missing or invalid.
  2. Duplicate calls threw `FirebaseAppError` ("The default Firebase app already exists").
- **Exact Changes Applied**:
  1. Added explicit validation for `project_id`, `client_email`, and `private_key`.
  2. Guarded initialization with `if (getApps().length === 0)`.
  3. Replaced raw credential logging with sanitized status notices.
  4. Exported safe `initFirebase()` and `auth` instance.
- **Compatibility**: Allows testing and development without requiring fake production credentials.

### `src/middleware/authMiddleware.js` & `src/sockets/handRaise.js`
- **Bug/Risk Addressed**: Threw unhandled runtime exceptions when Firebase failed to initialize, resulting in 500 errors or uncaught socket crashes.
- **Exact Changes Applied**:
  1. Middleware checks `if (!auth)` and returns `HTTP 503 Service Unavailable: Authentication service unavailable. Firebase credentials not configured.`.
  2. Socket hand-raise listener checks auth status and rejects the socket handshake cleanly if auth is offline.
  3. Unauthorized requests without tokens return clean `HTTP 401 Unauthorized`.
- **Compatibility**: Fails closed strictly without bypassing authentication.

---

## 3. Server Startup & Dynamic Health

### `server.js` & `apps/backend/src/server.js`
- **Bug/Risk Addressed**:
  1. `/api/health` returned a static `{ success: true }` even if MongoDB was completely down.
  2. Uncaught errors (such as Multer file filter rejections) caused Express to hang or return HTML error pages.
  3. Both backends defaulted to port 5000, causing `EADDRINUSE` port collision.
- **Exact Changes Applied**:
  1. Updated `/api/health` to dynamically query `mongoose.connection.readyState === 1`. Returns `HTTP 200` with `{ status: "ok", database: "connected" }` or `HTTP 503` with `{ status: "degraded", database: "disconnected" }`.
  2. Added Express error-handling middleware: `(err, req, res, next) => res.status(err.status || 400).json({ success: false, message: err.message })`.
  3. Configured `apps/backend/src/server.js` and `apps/backend/.env.example` to default to `PORT=5001`.
  4. Ensured servers only listen when run directly via `if (require.main === module)`, allowing clean imports by test runners without port contention.
- **Compatibility**: Fully compatible with existing routing; eliminates port conflicts.

---

## 4. Machine Learning Microservice

### `ml_service/main.py`
- **Bug/Risk Addressed**:
  1. `/mentor/chat`, `/quiz`, and `/summarize` leaked internal filesystem paths and raw upstream exception JSON directly in HTTP 502 responses.
  2. Missing API keys exposed environment paths to clients.
- **Exact Changes Applied**:
  1. Imported `logging` and configured `logger = logging.getLogger("uvicorn.error")`.
  2. Caught upstream LLM exceptions, logged diagnostic details internally on the server, and returned clean client-safe errors:
     - AI Mentor: `HTTP 502` with `{"detail": "The AI Mentor service is currently unavailable. Please try again."}`.
     - Quiz: `HTTP 502` with `{"detail": "The quiz generation service is currently unavailable. Please try again."}`.
     - Summarizer: `HTTP 502` with `{"detail": "The summarizer service is currently unavailable. Please try again."}`.
- **Compatibility**: Matches mobile app exception handling in `mentor_screen.dart` which expects HTTP 500 or 502.

---

## 5. Automated Integration Test Suites

### `test-backend-integration.js` (Root Backend)
- **Purpose**: Exercises all 19 root backend features against an in-memory MongoDB replica via `mongodb-memory-server`.
- **Key Checks**: Health checks, fail-closed auth, classroom creation/membership, assignment CRUD, text submission, upsert resubmissions, unconfigured storage 503 rejection, grading, notifications, materials, and calendar deadlining.
- **Clean Shutdown**: Closes HTTP server, disconnects Mongoose, and stops `MongoMemoryServer` without open handles or `process.exit(0)`.

### `test-apps-backend-integration.js` (`apps/backend`)
- **Purpose**: Validates all mounted routes in the `apps/backend` sub-api.
- **Key Checks**: Health status, assignment CRUD, text submission, resubmission, unconfigured storage rejection, materials, calendar. Cleanly disconnects the isolated `apps/backend` Mongoose instance.

### `test-frontend-adapter.js` (Web Contract Verification)
- **Purpose**: Validates the contract between `apps/web/src/services/api/backendAdapter.js` and the live Node.js REST API.
- **Key Checks**: Assignment creation, student class listing, multipart FormData submissions, status mapping, and calendar deadline retrieval.
