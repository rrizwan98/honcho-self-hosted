FROM python:3.13-slim-bookworm

# System packages: redis-server (embedded queue), supervisor (multi-process), curl (debug)
RUN apt-get update && apt-get install -y --no-install-recommends \
        redis-server \
        supervisor \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.9.24 /uv /bin/uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_CACHE_DIR=/tmp/uv-cache

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-group dev

COPY uv.lock pyproject.toml /app/

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-group dev

ENV PATH="/app/.venv/bin:$PATH" \
    HOME=/app

# HF Spaces convention: non-root user with UID 1000
RUN groupadd --system --gid 1000 app \
 && useradd  --system --uid 1000 --gid 1000 --home /app --shell /bin/sh app \
 && mkdir -p /tmp/uv-cache /var/log/supervisor /var/run/supervisor /var/lib/redis-runtime \
 && chown -R app:app /app /tmp/uv-cache /var/log/supervisor /var/run/supervisor /var/lib/redis-runtime

COPY --chown=app:app src/         /app/src/
COPY --chown=app:app migrations/  /app/migrations/
COPY --chown=app:app scripts/     /app/scripts/
COPY --chown=app:app docker/      /app/docker/
COPY --chown=app:app alembic.ini  /app/alembic.ini
COPY --chown=app:app config.toml* /app/
COPY --chown=app:app supervisord.conf /app/supervisord.conf

USER app

# Embedded Redis on loopback — ephemeral queue (msgs persist in Postgres)
ENV CACHE_URL="redis://localhost:6379/0?suppress=true" \
    CACHE_ENABLED=true

EXPOSE 8000

CMD ["/usr/bin/supervisord", "-c", "/app/supervisord.conf"]
