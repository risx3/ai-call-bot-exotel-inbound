# syntax=docker/dockerfile:1.7

FROM python:3.11-slim

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1

# -----------------------------
# System dependencies
# -----------------------------
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Install uv
# -----------------------------
RUN pip install --no-cache-dir uv

# -----------------------------
# Install Python dependencies
# -----------------------------
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml \
    uv sync --locked --no-install-project --no-dev

# -----------------------------
# Application files
# -----------------------------
COPY bot.py prompts.py ./

# -----------------------------
# Runtime configuration
# -----------------------------
EXPOSE 7860

# Basic container healthcheck (process-level)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pgrep -f "bot.py" || exit 1

# -----------------------------
# Start inbound bot
# -----------------------------
CMD ["uv", "run", "bot.py", "--transport", "exotel"]
