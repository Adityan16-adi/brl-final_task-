"""Chat spam detection with a strike system.

Signals: message flooding, repeated/duplicate messages, link spam, shouting,
repeated characters/words, very long messages. Each signal adds to a score;
score >= 2 means spam. Repeated spam -> warn -> block.

State is in memory. For multiple server instances move `history`/`strikes`
to Redis (same logic, just different storage).
"""
import re
import time
from collections import defaultdict, deque
from dataclasses import dataclass, field

URL_RE = re.compile(r"(https?://|www\.)\S+", re.I)
REPEAT_CHAR_RE = re.compile(r"(.)\1{7,}")
REPEAT_WORD_RE = re.compile(r"\b(\w+)\b(?:\W+\1\b){4,}", re.I)


@dataclass
class SpamResult:
    is_spam: bool
    score: int
    action: str  # "allow" | "warn" | "block" | "blocked"
    strikes: int
    reasons: list[str] = field(default_factory=list)


def _normalize(msg: str) -> str:
    return re.sub(r"\s+", " ", msg.lower().strip())


class SpamDetector:
    def __init__(
        self,
        rate_limit: int = 5,       # max messages per rate_window
        rate_window: float = 10,   # seconds
        dup_limit: int = 3,        # same message this many times...
        dup_window: float = 30,    # ...within this many seconds
        max_links: int = 2,
        max_length: int = 500,
        block_at: int = 3,         # strikes before block
        strike_decay: float = 300, # forget strikes after 5 quiet minutes
    ):
        self.rate_limit, self.rate_window = rate_limit, rate_window
        self.dup_limit, self.dup_window = dup_limit, dup_window
        self.max_links, self.max_length = max_links, max_length
        self.block_at, self.strike_decay = block_at, strike_decay
        self.history: dict[tuple, deque] = defaultdict(deque)
        self.strikes: dict[tuple, int] = defaultdict(int)
        self.last_strike: dict[tuple, float] = {}
        self.blocked: set[tuple] = set()

    def unblock(self, meeting_id: str, user_id: str) -> None:
        key = (meeting_id, user_id)
        self.blocked.discard(key)
        self.strikes[key] = 0

    def check(self, meeting_id: str, user_id: str, message: str, now: float | None = None) -> SpamResult:
        now = now if now is not None else time.time()
        key = (meeting_id, user_id)

        if key in self.blocked:
            return SpamResult(True, 0, "blocked", self.strikes[key], ["user already blocked"])

        # forget old strikes
        if key in self.last_strike and now - self.last_strike[key] > self.strike_decay:
            self.strikes[key] = 0

        norm = _normalize(message)
        hist = self.history[key]
        hist.append((now, norm))
        while hist and now - hist[0][0] > max(self.rate_window, self.dup_window):
            hist.popleft()

        score, reasons = 0, []

        recent = [t for t, _ in hist if now - t <= self.rate_window]
        if len(recent) > self.rate_limit:
            score += 2
            reasons.append(f"flooding: {len(recent)} messages in {self.rate_window:.0f}s")

        dups = sum(1 for t, m in hist if m == norm and now - t <= self.dup_window)
        if dups >= self.dup_limit:
            score += 2
            reasons.append(f"same message sent {dups} times")

        if len(URL_RE.findall(message)) > self.max_links:
            score += 2
            reasons.append("too many links")
        elif URL_RE.search(message) and dups >= 2:
            score += 1
            reasons.append("repeated link")

        letters = [c for c in message if c.isalpha()]
        if len(letters) >= 10 and sum(c.isupper() for c in letters) / len(letters) > 0.7:
            score += 1
            reasons.append("excessive caps")

        if REPEAT_CHAR_RE.search(message) or REPEAT_WORD_RE.search(message):
            score += 1
            reasons.append("repeated characters/words")

        if len(message) > self.max_length:
            score += 1
            reasons.append("very long message")

        is_spam = score >= 2
        action = "allow"
        if is_spam:
            self.strikes[key] += 1
            self.last_strike[key] = now
            if self.strikes[key] >= self.block_at:
                self.blocked.add(key)
                action = "block"
            else:
                action = "warn"

        return SpamResult(is_spam, score, action, self.strikes[key], reasons)
