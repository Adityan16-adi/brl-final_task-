"""ML service for the Meet + Classroom app.

Run:  uvicorn main:app --reload --port 8001
Docs: http://localhost:8001/docs  (try every endpoint from the browser)
"""
from dataclasses import asdict

from fastapi import FastAPI, File, HTTPException, Query, Response, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import captions
from denoise import denoise_wav_bytes
from mentor import Mentor
from quiz import generate_quiz
from spam import SpamDetector
from summarizer import summarize_notes

app = FastAPI(title="Meet+Classroom ML service")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])  # restrict in prod

spam_detector = SpamDetector()
mentor = Mentor()


# ---------- spam ----------
class SpamIn(BaseModel):
    meeting_id: str
    user_id: str
    message: str


@app.post("/spam/check")
def spam_check(body: SpamIn):
    """Backend calls this for every chat message. If action == 'block',
    your main server should mute/remove that user from chat."""
    return asdict(spam_detector.check(body.meeting_id, body.user_id, body.message))


@app.post("/spam/unblock")
def spam_unblock(meeting_id: str, user_id: str):
    spam_detector.unblock(meeting_id, user_id)
    return {"ok": True}


# ---------- notes summariser ----------
class SummarizeIn(BaseModel):
    text: str
    style: str = Field("bullets", description="short | bullets | detailed")


@app.post("/summarize")
async def summarize(body: SummarizeIn):
    try:
        return {"summary": await run_in_threadpool(summarize_notes, body.text, body.style)}
    except ValueError as e:
        raise HTTPException(400, str(e))


# ---------- quiz ----------
class QuizIn(BaseModel):
    text: str
    num_questions: int = Field(5, ge=1, le=20)
    difficulty: str = Field("medium", description="easy | medium | hard")


@app.post("/quiz")
async def quiz(body: QuizIn):
    try:
        return await run_in_threadpool(generate_quiz, body.text, body.num_questions, body.difficulty)
    except ValueError as e:
        raise HTTPException(400, str(e))
    except RuntimeError as e:
        raise HTTPException(502, str(e))


# ---------- AI mentor ----------
class ChatIn(BaseModel):
    session_id: str
    message: str
    course_id: str | None = None


class MaterialIn(BaseModel):
    course_id: str
    text: str


@app.post("/mentor/chat")
async def mentor_chat(body: ChatIn):
    return {"reply": await run_in_threadpool(mentor.chat, body.session_id, body.message, body.course_id)}


@app.post("/mentor/materials")
async def mentor_materials(body: MaterialIn):
    n = await run_in_threadpool(mentor.add_materials, body.course_id, body.text)
    return {"chunks_indexed": n}


@app.post("/mentor/reset")
def mentor_reset(session_id: str):
    mentor.reset(session_id)
    return {"ok": True}


# ---------- live captions ----------
@app.websocket("/ws/captions")
async def ws_captions(ws: WebSocket, language: str | None = Query(None)):
    """Send binary frames of PCM16 mono 16 kHz audio; receive {"text": "..."}."""
    await ws.accept()
    buf = bytearray()
    try:
        while True:
            buf += await ws.receive_bytes()
            if len(buf) >= captions.WINDOW_BYTES:
                chunk, buf = bytes(buf), bytearray()
                try:
                    text = await run_in_threadpool(captions.transcribe_pcm16, chunk, language)
                except Exception as e:
                    captions.log.exception("caption transcription failed")
                    await ws.send_json({"error": f"{type(e).__name__}: {e}"})
                    continue
                if text:
                    await ws.send_json({"text": text})
    except WebSocketDisconnect:
        pass


# ---------- noise cancellation ----------
@app.post("/denoise")
async def denoise(file: UploadFile = File(...), strength: float = 0.9):
    data = await file.read()
    try:
        out = await run_in_threadpool(denoise_wav_bytes, data, strength)
    except Exception as e:
        raise HTTPException(400, f"Could not process audio (send a WAV file): {e}")
    return Response(out, media_type="audio/wav")