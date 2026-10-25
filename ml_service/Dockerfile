# Production Dockerfile for Unified Learning ML / AI Service
FROM python:3.12-slim AS base

WORKDIR /app

# Install system dependencies required for OpenMP (torch/faiss), audio processing, and C extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy ML service application code
COPY . .

EXPOSE 8001

ENV PYTHONUNBUFFERED=1 \
    PORT=8001

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request, os, sys; port = os.environ.get('PORT', '8001'); sys.exit(0 if urllib.request.urlopen(f'http://localhost:{port}/health').getcode() == 200 else 1)"

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8001}"]
