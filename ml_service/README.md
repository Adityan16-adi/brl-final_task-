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

## Notes
- Spam and mentor sessions are stored in memory; move them to Redis/DB before deploying multiple instances.
- Groq's free tier has rate limits; cache summaries/quizzes per note in your DB.
