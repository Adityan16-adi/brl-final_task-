"""ML service for the Meet + Classroom app.

Run:  uvicorn main:app --reload --port 8001
Docs: http://localhost:8001/docs  (try every endpoint from the browser)

Security/robustness settings are read from the environment (.env), see README.
"""
import logging
import os
import secrets
from dataclasses import asdict

from fastapi import (
    APIRouter, Depends, FastAPI, File, HTTPException, Query, Request, Response,
    UploadFile, WebSocket, WebSocketDisconnect,
)
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import APIKeyHeader
from pydantic import BaseModel, Field, field_validator

import captions
from denoise import denoise_wav_bytes
from llm import LLMConfigError, llm_configured
from mentor import Mentor
from quiz import generate_quiz
from ratelimit import SlidingWindowLimiter
from spam import SpamDetector
from summarizer import summarize_notes

log = logging.getLogger("uvicorn.error")

# ---------- settings (all optional, set in .env) ----------
API_TOKEN = os.getenv("ML_API_TOKEN", "").strip()                       # shared secret with your backend
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
MAX_NOTE_CHARS = int(os.getenv("MAX_NOTE_CHARS", "50000"))              # notes / course material
MAX_MESSAGE_CHARS = int(os.getenv("MAX_MESSAGE_CHARS", "4000"))         # one mentor chat message
MAX_CHAT_SPAM_CHARS = 20000                                             # hard cap for /spam/check input
RATE_LIMIT_PER_MIN = int(os.getenv("RATE_LIMIT_PER_MIN", "30"))         # 0 disables rate limiting

app = FastAPI(title="Meet+Classroom ML service")
# Browsers can only call this service directly from origins listed in CORS_ORIGINS.
# Default is none: your backend (server to server) does not need CORS.
app.add_middleware(CORSMiddleware, allow_origins=CORS_ORIGINS, allow_methods=["*"], allow_headers=["*"])

spam_detector = SpamDetector()
mentor = Mentor()
limiter = SlidingWindowLimiter(limit=RATE_LIMIT_PER_MIN, window=60)

if not API_TOKEN:
    log.warning("ML_API_TOKEN is not set: the API is OPEN to anyone who can reach it. Set it before deploying.")


# ---------- auth + rate limit helpers ----------
_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)  # also adds an "Authorize" button in /docs


def _token_ok(key: str | None) -> bool:
    return bool(key) and secrets.compare_digest(key.encode(), API_TOKEN.encode())


def require_token(key: str | None = Depends(_api_key_header)) -> None:
    """If ML_API_TOKEN is set, every HTTP call must send it in the X-API-Key header."""
    if API_TOKEN and not _token_ok(key):
        raise HTTPException(401, "Missing or invalid API key.")


def rate_limit(request: Request) -> None:
    """Per-caller limit for expensive endpoints. Caller = X-User-Id header, else IP address."""
    uid = request.headers.get("x-user-id", "").strip()[:200]
    who = f"user:{uid}" if uid else f"ip:{request.client.host if request.client else 'unknown'}"
    retry_after = limiter.hit(who)
    if retry_after is not None:
        raise HTTPException(
            429, "Too many requests. Please wait a moment and retry.", headers={"Retry-After": str(retry_after)}
        )


async def run_llm(fn, *args):
    """Run a blocking LLM-backed function and turn failures into clear HTTP errors."""
    try:
        return await run_in_threadpool(fn, *args)
    except ValueError as e:                      # e.g. empty note
        raise HTTPException(400, str(e))
    except LLMConfigError:
        log.error("GROQ_API_KEY is missing or invalid on the server")
        raise HTTPException(503, "The AI service is not configured on the server.")
    except RuntimeError as e:                    # quiz: model never produced valid JSON
        log.error("LLM output problem: %s", e)
        raise HTTPException(502, "The AI could not produce a valid answer. Please try again.")
    except Exception as e:                       # provider down, rate-limited, network error, timeout...
        log.exception("LLM provider call failed")
        if "timeout" in type(e).__name__.lower():
            raise HTTPException(504, "The AI provider took too long to respond. Please retry.")
        raise HTTPException(502, "The AI provider is unavailable right now. Please retry.")


# ---------- health (open, no token needed, so monitors/load balancers can ping it) ----------
@app.get("/health")
def health():
    return {"status": "ok", "llm_configured": llm_configured()}


api = APIRouter(dependencies=[Depends(require_token)])


# ---------- spam ----------
class SpamIn(BaseModel):
    meeting_id: str = Field(..., min_length=1, max_length=200)
    user_id: str = Field(..., min_length=1, max_length=200)
    message: str = Field(..., max_length=MAX_CHAT_SPAM_CHARS)


@api.post("/spam/check")
def spam_check(body: SpamIn):
    """Backend calls this for every chat message. If action == 'block',
    your main server should mute/remove that user from chat."""
    return asdict(spam_detector.check(body.meeting_id, body.user_id, body.message))


@api.post("/spam/unblock")
def spam_unblock(meeting_id: str, user_id: str):
    spam_detector.unblock(meeting_id, user_id)
    return {"ok": True}


# ---------- notes summariser ----------
class SummarizeIn(BaseModel):
    text: str = Field(..., max_length=MAX_NOTE_CHARS)
    style: str = Field("bullets", description="short | bullets | detailed")


@api.post("/summarize", dependencies=[Depends(rate_limit)])
async def summarize(body: SummarizeIn):
    return {"summary": await run_llm(summarize_notes, body.text, body.style)}


# ---------- quiz ----------
class QuizIn(BaseModel):
    text: str = Field(..., max_length=MAX_NOTE_CHARS)
    num_questions: int = Field(5, ge=1, le=20)
    difficulty: str = Field("medium", description="easy | medium | hard")


@api.post("/quiz", dependencies=[Depends(rate_limit)])
async def quiz(body: QuizIn):
    return await run_llm(generate_quiz, body.text, body.num_questions, body.difficulty)


# ---------- AI mentor ----------
class ChatIn(BaseModel):
    session_id: str = Field(..., min_length=1, max_length=200)
    message: str = Field(..., max_length=MAX_MESSAGE_CHARS)
    course_id: str | None = Field(None, max_length=200)

    @field_validator("message")
    @classmethod
    def message_not_blank(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("message must not be empty")
        return v


class MaterialIn(BaseModel):
    course_id: str = Field(..., min_length=1, max_length=200)
    text: str = Field(..., max_length=MAX_NOTE_CHARS)


@api.post("/mentor/chat", dependencies=[Depends(rate_limit)])
async def mentor_chat(body: ChatIn):
    return {"reply": await run_llm(mentor.chat, body.session_id, body.message, body.course_id)}


@api.post("/mentor/materials", dependencies=[Depends(rate_limit)])
async def mentor_materials(body: MaterialIn):
    n = await run_llm(mentor.add_materials, body.course_id, body.text)
    return {"chunks_indexed": n}


@api.post("/mentor/reset")
def mentor_reset(session_id: str):
    mentor.reset(session_id)
    return {"ok": True}


# ---------- noise cancellation ----------
@api.post("/denoise", dependencies=[Depends(rate_limit)])
async def denoise(file: UploadFile = File(...), strength: float = Query(0.9, ge=0.0, le=1.0)):
    data = await file.read()
    try:
        out = await run_in_threadpool(denoise_wav_bytes, data, strength)
    except Exception as e:
        raise HTTPException(400, f"Could not process audio (send a WAV file): {e}")
    return Response(out, media_type="audio/wav")


app.include_router(api)


# ---------- live captions ----------
@app.websocket("/ws/captions")
async def ws_captions(ws: WebSocket, language: str | None = Query(None)):
    """Send binary frames of PCM16 mono 16 kHz audio; receive {"text": "..."}.
    If ML_API_TOKEN is set, send it as the X-API-Key header (or ?token=... if headers are not possible)."""
    if API_TOKEN and not _token_ok(ws.headers.get("x-api-key") or ws.query_params.get("token")):
        await ws.close(code=1008)  # policy violation: unauthorized
        return
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