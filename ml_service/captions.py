"""Live captions with faster-whisper (free, runs locally, CPU is fine).

Client streams raw PCM: 16 kHz, mono, 16-bit little-endian. We buffer a few
seconds, transcribe with VAD (skips silence), and push text back.
Expect ~2-4 s caption delay on CPU with the 'base' model.
"""
import logging
import os
import time
from functools import lru_cache

import numpy as np
from faster_whisper import WhisperModel

log = logging.getLogger("uvicorn.error")
USE_VAD = os.getenv("WHISPER_VAD", "1") != "0"  # set WHISPER_VAD=0 in .env to debug silent-audio cases
SAMPLE_RATE = 16000
WINDOW_SECONDS = 2.5
WINDOW_BYTES = int(SAMPLE_RATE * 2 * WINDOW_SECONDS)


@lru_cache(maxsize=1)
def _model() -> WhisperModel:
    size = os.getenv("WHISPER_MODEL", "base")  # tiny = faster, small = more accurate
    return WhisperModel(size, device="cpu", compute_type="int8")


def transcribe_pcm16(pcm: bytes, language: str | None = None) -> str:
    t0 = time.time()
    audio = np.frombuffer(pcm, dtype=np.int16).astype(np.float32) / 32768.0
    rms = float(np.sqrt(np.mean(audio ** 2))) if len(audio) else 0.0
    segments, _ = _model().transcribe(
        audio, language=language, vad_filter=USE_VAD, beam_size=1, condition_on_previous_text=False
    )
    text = " ".join(s.text.strip() for s in segments).strip()
    log.info("caption chunk: %.1fs audio, volume(rms)=%.4f, took %.1fs, text=%r",
             len(audio) / SAMPLE_RATE, rms, time.time() - t0, text)
    return text