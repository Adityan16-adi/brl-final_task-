"""ML service for the Meet + Classroom app.

Run:  uvicorn main:app --reload --port 8001
Docs: http://localhost:8001/docs  (try every endpoint from the browser)
"""
from dataclasses import asdict
import logging
import os

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

logger = logging.getLogger("uvicorn.error")

app = FastAPI(title="Meet+Classroom ML service")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])  # restrict in prod

spam_detector = SpamDetector()
mentor = Mentor()


def _handle_llm_exception(service_name: str, e: Exception):
    err_str = str(e)
    err_type = type(e).__name__
    if isinstance(e, RuntimeError) or "GROQ_API_KEY not found" in err_str:
        logger.error(f"{service_name} configuration error: {e}")
        raise HTTPException(503, "GROQ_API_KEY not found. Set GROQ_API_KEY in ml_service/.env to enable live AI responses.")
    if "invalid_api_key" in err_str or "Invalid API Key" in err_str or "AuthenticationError" in err_type:
        logger.error(f"{service_name} authentication error: {e}")
        raise HTTPException(503, "Invalid GROQ_API_KEY: The configured Groq key was rejected by the Groq API. Please update GROQ_API_KEY in ml_service/.env.")
    if isinstance(e, ValueError):
        raise HTTPException(400, str(e))
    logger.error(f"{service_name} error: {e}")
    raise HTTPException(502, f"The {service_name} service is currently unavailable. Please try again.")


# ---------- health & status ----------
@app.get("/")
@app.get("/health")
def health():
    groq_configured = bool(os.getenv("GROQ_API_KEY") and "your_free_key" not in os.getenv("GROQ_API_KEY", ""))
    return {
        "status": "ok",
        "service": "ml_service",
        "features": {
            "spam_detection": True,
            "summarizer": True,
            "quiz_generation": True,
            "ai_mentor": True,
            "live_captions": True,
            "noise_cancellation": True,
        },
        "llm_configured": groq_configured,
    }


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
    except Exception as e:
        _handle_llm_exception("Summarizer", e)


# ---------- quiz ----------
class QuizIn(BaseModel):
    text: str
    num_questions: int = Field(5, ge=1, le=20)
    difficulty: str = Field("medium", description="easy | medium | hard")


@app.post("/quiz")
async def quiz(body: QuizIn):
    try:
        return await run_in_threadpool(generate_quiz, body.text, body.num_questions, body.difficulty)
    except Exception as e:
        _handle_llm_exception("Quiz generator", e)


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
    try:
        return {"reply": await run_in_threadpool(mentor.chat, body.session_id, body.message, body.course_id)}
    except Exception as e:
        _handle_llm_exception("AI Mentor", e)


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
