"""Server-side noise reduction for WAV audio (recordings, uploaded clips, and
audio fed to captions to improve accuracy) using the free `noisereduce` library.

For the LIVE microphone in a meeting, do noise suppression in the browser
instead (see README notes): sending audio to a server and back adds latency.
"""
import io

import noisereduce as nr
import numpy as np
from scipy.io import wavfile


def denoise_wav_bytes(data: bytes, strength: float = 0.9) -> bytes:
    sr, audio = wavfile.read(io.BytesIO(data))
    dtype = audio.dtype
    x = audio.astype(np.float32)

    if x.ndim == 2:  # (samples, channels) -> (channels, samples)
        y = nr.reduce_noise(y=x.T, sr=sr, stationary=False, prop_decrease=strength).T
    else:
        y = nr.reduce_noise(y=x, sr=sr, stationary=False, prop_decrease=strength)

    if np.issubdtype(dtype, np.integer):
        info = np.iinfo(dtype)
        y = np.clip(y, info.min, info.max)
    y = y.astype(dtype)

    out = io.BytesIO()
    wavfile.write(out, sr, y)
    return out.getvalue()
