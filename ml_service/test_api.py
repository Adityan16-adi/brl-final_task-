"""API behaviour tests. No GROQ key or internet needed: LLM functions are replaced with fakes.

Run:  pip install -r requirements-dev.txt && pytest -v
"""
import pytest
from fastapi.testclient import TestClient

import main
from llm import LLMConfigError
from ratelimit import SlidingWindowLimiter


@pytest.fixture(autouse=True)
def clean_state(monkeypatch):
    monkeypatch.setattr(main, "API_TOKEN", "")
    monkeypatch.setattr(main, "limiter", SlidingWindowLimiter(limit=100, window=60))


@pytest.fixture
def client():
    return TestClient(main.app)


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200 and r.json()["status"] == "ok"


# ----- validation -----
def test_empty_mentor_message_rejected(client):
    for msg in ("", "   "):
        r = client.post("/mentor/chat", json={"session_id": "s", "message": msg})
        assert r.status_code == 422


def test_too_long_mentor_message_rejected(client):
    r = client.post("/mentor/chat", json={"session_id": "s", "message": "x" * (main.MAX_MESSAGE_CHARS + 1)})
    assert r.status_code == 422


def test_too_long_note_rejected(client):
    r = client.post("/summarize", json={"text": "x" * (main.MAX_NOTE_CHARS + 1)})
    assert r.status_code == 422


def test_invalid_payload_rejected(client):
    assert client.post("/mentor/chat", json={"message": "hi"}).status_code == 422   # no session_id
    assert client.post("/quiz", json={"text": "x", "num_questions": 0}).status_code == 422


def test_blank_summary_text_is_400(client):
    assert client.post("/summarize", json={"text": "   "}).status_code == 400


# ----- provider failures become honest errors -----
def test_provider_failure_is_502(client, monkeypatch):
    def boom(*a, **k):
        raise Exception("provider exploded")
    monkeypatch.setattr(main, "summarize_notes", boom)
    r = client.post("/summarize", json={"text": "hello world"})
    assert r.status_code == 502 and "retry" in r.json()["detail"].lower()
    assert "exploded" not in r.json()["detail"]          # internal detail is not leaked


def test_provider_timeout_is_504(client, monkeypatch):
    class APITimeoutError(Exception):
        pass
    def slow(*a, **k):
        raise APITimeoutError()
    monkeypatch.setattr(main.mentor, "chat", slow)
    r = client.post("/mentor/chat", json={"session_id": "s", "message": "hi"})
    assert r.status_code == 504


def test_missing_key_is_503(client, monkeypatch):
    def nokey(*a, **k):
        raise LLMConfigError("no key")
    monkeypatch.setattr(main, "generate_quiz", nokey)
    r = client.post("/quiz", json={"text": "some notes"})
    assert r.status_code == 503


def test_happy_path_returns_reply(client, monkeypatch):
    monkeypatch.setattr(main.mentor, "chat", lambda sid, msg, cid=None: "hello student")
    r = client.post("/mentor/chat", json={"session_id": "s", "message": "hi"})
    assert r.status_code == 200 and r.json() == {"reply": "hello student"}


# ----- auth -----
def test_token_required_when_set(client, monkeypatch):
    monkeypatch.setattr(main, "API_TOKEN", "secret")
    body = {"meeting_id": "m", "user_id": "u", "message": "hello"}
    assert client.post("/spam/check", json=body).status_code == 401
    assert client.post("/spam/check", json=body, headers={"X-API-Key": "wrong"}).status_code == 401
    assert client.post("/spam/check", json=body, headers={"X-API-Key": "secret"}).status_code == 200
    assert client.get("/health").status_code == 200       # health stays open


def test_websocket_requires_token(client, monkeypatch):
    monkeypatch.setattr(main, "API_TOKEN", "secret")
    with pytest.raises(Exception):
        with client.websocket_connect("/ws/captions"):
            pass
    with client.websocket_connect("/ws/captions", headers={"X-API-Key": "secret"}):
        pass  # accepted


# ----- rate limiting -----
def test_rate_limit_returns_429(client, monkeypatch):
    monkeypatch.setattr(main, "limiter", SlidingWindowLimiter(limit=2, window=60))
    monkeypatch.setattr(main, "summarize_notes", lambda text, style="bullets": "ok")
    codes = [client.post("/summarize", json={"text": "notes"}).status_code for _ in range(3)]
    assert codes == [200, 200, 429]
    r = client.post("/summarize", json={"text": "notes"})
    assert "retry-after" in r.headers


def test_rate_limit_is_per_user(client, monkeypatch):
    monkeypatch.setattr(main, "limiter", SlidingWindowLimiter(limit=1, window=60))
    monkeypatch.setattr(main, "summarize_notes", lambda text, style="bullets": "ok")
    a = {"X-User-Id": "alice"}
    b = {"X-User-Id": "bob"}
    assert client.post("/summarize", json={"text": "n"}, headers=a).status_code == 200
    assert client.post("/summarize", json={"text": "n"}, headers=a).status_code == 429
    assert client.post("/summarize", json={"text": "n"}, headers=b).status_code == 200


def test_spam_check_is_not_rate_limited(client, monkeypatch):
    monkeypatch.setattr(main, "limiter", SlidingWindowLimiter(limit=1, window=60))
    body = {"meeting_id": "m", "user_id": "u", "message": "hi"}
    assert all(client.post("/spam/check", json=body).status_code == 200 for _ in range(3))