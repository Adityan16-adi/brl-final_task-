# ML service (Meet + Classroom app)

## Setup
```bash
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env        # add your free Groq key
uvicorn main:app --reload --port 8001
```
Open http://localhost:8001/docs to test every endpoint.

## Endpoints
| Feature | Endpoint |
|---|---|
| Health check | `GET /health` -> `{status, llm_configured}` (no token needed) |
| Spam check | `POST /spam/check` `{meeting_id, user_id, message}` -> `action`: allow / warn / block / blocked |
| Summariser | `POST /summarize` `{text, style}` |
| Quiz | `POST /quiz` `{text, num_questions, difficulty}` -> JSON questions |
| Mentor | `POST /mentor/chat` `{session_id, message, course_id?}`; `POST /mentor/materials` to add course notes |
| Captions | `WS /ws/captions` send PCM16 / 16 kHz / mono binary frames, receive `{text}` |
| Denoise (files) | `POST /denoise` upload WAV, get cleaned WAV |

## Live noise cancellation in the browser (free, real time)
Do this on the client; a server round trip adds too much delay for a live call.

```js
const stream = await navigator.mediaDevices.getUserMedia({
  audio: { noiseSuppression: true, echoCancellation: true, autoGainControl: true }
});
```
This uses the browser's built-in suppression (what Meet-style apps use by default). If you want
RNNoise specifically, run it in the browser via WebAssembly with the free npm package
`@sapphi-red/web-noise-suppressor` (an AudioWorklet that wraps RNNoise) on the mic stream
before sending it to WebRTC.

## Captions, fastest option
If server-side Whisper feels slow, the browser's Web Speech API (`webkitSpeechRecognition`) gives
near-instant captions for free in Chrome/Edge, but it is browser dependent. Keep the Whisper
WebSocket as the fallback / for other browsers.

## Configuration (`.env`, all optional)
| Variable | Default | What it does |
|---|---|---|
| `GROQ_API_KEY` | none | Your Groq key. Server side only, never put it in the mobile/web app. |
| `ML_API_TOKEN` | empty (API open) | Shared secret. When set, every HTTP call must send header `X-API-Key: <token>` (WebSocket: same header, or `?token=`). Generate one with `python -c "import secrets; print(secrets.token_urlsafe(32))"`. |
| `CORS_ORIGINS` | empty (no browser origins) | Comma-separated origins allowed to call this service from a browser. Your backend does not need it. |
| `RATE_LIMIT_PER_MIN` | 30 | Requests per minute per caller on `/summarize`, `/quiz`, `/mentor/chat`, `/mentor/materials`, `/denoise`. `0` turns it off. |
| `LLM_TIMEOUT` | 30 | Seconds to wait for the AI provider. |
| `LLM_MAX_RETRIES` | 1 | Automatic retries on network errors. |
| `MAX_NOTE_CHARS` | 50000 | Longest note / course material accepted. |
| `MAX_MESSAGE_CHARS` | 4000 | Longest mentor chat message accepted. |

## How the backend should call this service
- Send `X-API-Key` on every request (when `ML_API_TOKEN` is set).
- Send `X-User-Id: <logged-in user id>` so rate limits are per user instead of per server IP.
- Build `session_id` on the backend from the verified user (for example `userId:courseId:conversationId`) and only pass a `course_id` the user is enrolled in. This service does not know who the user is.
- Keep this service on a private network; the mobile and web apps talk to your backend, not to this service.

## Error responses
| Code | Meaning | What the app should do |
|---|---|---|
| 400 | Empty note, or unreadable audio | Show the message |
| 401 | Missing/invalid `X-API-Key` | Backend configuration problem |
| 422 | Invalid payload (empty message, too long, wrong types) | Fix the request |
| 429 | Rate limited (`Retry-After` header says how many seconds) | Wait, then retry |
| 502 | AI provider failed or returned unusable output | Show "try again" with a retry button |
| 503 | `GROQ_API_KEY` missing on the server | Server setup problem |
| 504 | AI provider timed out | Show "try again" with a retry button |

## Tests
```bash
pip install -r requirements-dev.txt
pytest -v
```
The tests use fake LLM functions, so they need no Groq key or internet.

## Notes
- Spam and mentor sessions are stored in memory; move them to Redis/DB before deploying multiple instances.
- Groq's free tier has rate limits; cache summaries/quizzes per note in your DB.