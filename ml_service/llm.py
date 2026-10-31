"""Shared LLM + embedding helpers (all free: Groq free tier + local HF model)."""
import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent

# Look for the key file next to this script (not the terminal's current folder).
# Accepts the proper name ".env" plus names Windows/downloads often produce.
for _name in (".env", ".env.txt", "env.txt", "_env_example.env", ".env.example"):
    _path = HERE / _name
    if _path.is_file():
        load_dotenv(_path, override=True, encoding="utf-8-sig")
        if os.getenv("GROQ_API_KEY"):
            break

# Strip stray quotes/spaces that can sneak in on Windows
if os.getenv("GROQ_API_KEY"):
    os.environ["GROQ_API_KEY"] = os.environ["GROQ_API_KEY"].strip().strip('"').strip("'")

GROQ_MODEL = os.getenv("GROQ_MODEL", "openai/gpt-oss-20b")
LLM_TIMEOUT = float(os.getenv("LLM_TIMEOUT", "30"))        # seconds to wait for the provider
LLM_MAX_RETRIES = int(os.getenv("LLM_MAX_RETRIES", "1"))   # automatic retries on network errors


class LLMConfigError(RuntimeError):
    """The server is missing its LLM API key (a server setup problem, not a user error)."""


def llm_configured() -> bool:
    key = os.getenv("GROQ_API_KEY", "")
    return bool(key) and "your_free_key" not in key


def get_llm(temperature: float = 0.2):
    if not llm_configured():
        raise LLMConfigError(
            f"GROQ_API_KEY not found. Create a file named exactly '.env' in {HERE} "
            "containing the line: GROQ_API_KEY=gsk_your_key"
        )
    from langchain_groq import ChatGroq  # imported lazily so the server starts even without a key
    return ChatGroq(model=GROQ_MODEL, temperature=temperature, timeout=LLM_TIMEOUT, max_retries=LLM_MAX_RETRIES)


@lru_cache(maxsize=1)
def get_embeddings():
    from langchain_huggingface import HuggingFaceEmbeddings
    # loaded once, runs locally on CPU, free
    return HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")