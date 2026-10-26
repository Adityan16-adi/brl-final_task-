# Backend and web development setup

## Services

- `apps/backend` is the API currently targeted by `apps/web` on port 5000. It owns assignment, submission, materials, notification, calendar, and the Node-to-ML study proxy routes.
- `ml_service` is the Python inference service on port 8001. The browser should call the Node API for mentor/quiz operations; it does not need provider credentials or an ML host address.
- The repository-root `server.js` is a separate Firebase/classroom service on port 3000. Its user sync and classroom management routes remain legacy-only; duplicate data route mounts have been removed.

## Configure and start

Copy `apps/backend/.env.example` to `apps/backend/.env` and supply a rotated MongoDB URI and Cloudinary account credentials. Start the canonical API from any working directory with:

```sh
cd apps/backend && npm ci && npm start
```

The server reads `apps/backend/.env` by absolute path, validates required configuration, connects to MongoDB, and only then listens on port 5000. `/api/health` returns 503 until MongoDB is connected. Cloudinary settings and `FIREBASE_PROJECT_ID` are required. Firebase Admin uses Application Default Credentials or the local untracked path in `GOOGLE_APPLICATION_CREDENTIALS`. CORS defaults to `http://localhost:5173`; set `WEB_ORIGIN` to a comma-separated list of trusted web origins when needed. The root Firebase/classroom service reads root `.env` and defaults to port 3000.

Set up Python with `python -m venv .venv`, activate it, install `pip install -r requirements.txt` from `ml_service/`, copy `.env.example` to `.env`, and set `GROQ_API_KEY` for actual LLM inference. Run `uvicorn main:app --host 127.0.0.1 --port 8001` from `ml_service/`. `ML_SERVICE_URL` on the Node service selects the Python service address. `/health` is a process health check; it does not prove provider credentials or model inference are available.

## Web API mode

Copy `apps/web/.env.example` to `apps/web/.env.local`, use `VITE_DATA_MODE=api` and `VITE_API_BASE_URL=http://localhost:5000/api`, then run `npm run dev` from `apps/web/`. `VITE_DEMO_CLASS_ID` selects a class, while teacher/student ObjectId values and the browser role are not authorization. Protected calls require a verified Firebase ID token in local storage key `unified-learn-firebase-id-token`. The current demo login does not provide one; full Firebase web login remains to be integrated.

Mentor requests call `/api/study/mentor` and use the real Python `/mentor/chat` implementation. Quiz generation calls `/api/study/quiz`; it requires lesson text, but the current quiz UI only collects a topic and does not provide lesson notes, so API mode returns a visible validation error instead of inventing quiz content. `checkMessage` remains a deterministic mock; the Python spam detector requires a trusted meeting and user identity contract that the web app does not yet have.

## Current integration boundary

The canonical API verifies Firebase identities and enforces MongoDB role, class membership, and teacher ownership for data operations. Supported routes are assignment list/detail/create, submission upload/read, material list/add, notification list/read, calendar-by-month, and mentor. File uploads use Cloudinary and persist secure URLs. Web Firebase login, classroom management UI, attendance, announcements, delivered chat, and profile operations remain mock or legacy-only and are not integrated into the canonical API. Browser-provided user IDs are ignored for authorization.
