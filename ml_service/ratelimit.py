"""Tiny in-memory sliding-window rate limiter (no extra dependencies).

Used by main.py on the expensive endpoints (LLM calls, denoise). The caller is
identified by the `X-User-Id` header (your backend should forward the logged-in
user's id) or, if that header is missing, by IP address.

State is in memory: it resets on restart and is per server instance. For several
instances, move `_hits` to Redis (same logic, different storage).
"""
import math
import threading
import time
from collections import defaultdict, deque


class SlidingWindowLimiter:
    def __init__(self, limit: int = 30, window: float = 60.0):
        self.limit = limit      # max requests per window; <= 0 disables the limiter
        self.window = window    # seconds
        self._hits: dict[str, deque] = defaultdict(deque)
        self._lock = threading.Lock()
        self._last_sweep = 0.0

    def hit(self, key: str, now: float | None = None) -> int | None:
        """Record one request for `key`.

        Returns None if the request is allowed, otherwise the number of seconds
        the caller should wait before retrying.
        """
        if self.limit <= 0:
            return None
        now = time.monotonic() if now is None else now
        with self._lock:
            self._sweep(now)
            q = self._hits[key]
            while q and now - q[0] >= self.window:
                q.popleft()
            if len(q) >= self.limit:
                return max(1, math.ceil(self.window - (now - q[0])))
            q.append(now)
            return None

    def _sweep(self, now: float) -> None:
        """Drop keys with no recent requests so memory does not grow forever."""
        if now - self._last_sweep < self.window:
            return
        self._last_sweep = now
        for k in [k for k, q in self._hits.items() if not q or now - q[-1] >= self.window]:
            del self._hits[k]