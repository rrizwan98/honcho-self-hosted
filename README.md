---
title: Honcho API
emoji: 🧠
colorFrom: purple
colorTo: blue
sdk: docker
app_port: 8000
pinned: false
license: agpl-3.0
short_description: Self-hosted Honcho memory server for AI agents
---

# Honcho — Self-Hosted (Hugging Face Spaces)

Self-hosted instance of [Honcho](https://github.com/plastic-labs/honcho), an open-source memory and conversation analysis platform for AI agents.

## Architecture

This Space runs a single Docker container that wraps three processes via `supervisord`:

| Process    | Purpose                                | Source                |
|------------|----------------------------------------|------------------------|
| `redis`    | Embedded queue + cache (ephemeral)     | apt `redis-server`     |
| `api`      | FastAPI server on port `8000`          | `src/main.py`          |
| `deriver`  | Background worker (memory formation)   | `src/deriver/__main__` |

**Postgres (with pgvector)** is **external** — provided via Neon serverless Postgres. This keeps memory data persistent across Space restarts.

**Redis** is **embedded** in this container. Redis stores in-flight derivation tasks only; messages persist in Postgres, so a restart causes at most a re-queue, never data loss.

## Required Space secrets

Set these in **Settings → Variables and secrets** of the HF Space:

| Secret                | Required | Notes                                                                 |
|-----------------------|----------|-----------------------------------------------------------------------|
| `DB_CONNECTION_URI`   | yes      | Neon URL — must use `postgresql+psycopg://` prefix                    |
| `LLM_OPENAI_API_KEY`  | yes      | OpenAI key for embeddings (`text-embedding-3-small`) + dialectic LLM  |
| `AUTH_USE_AUTH`       | no       | `false` (default)                                                     |
| `LOG_LEVEL`           | no       | `INFO` (default)                                                      |

## Endpoints

- `GET /health` — liveness probe → `{"status":"ok"}`
- `GET /docs` — interactive API documentation (Swagger UI)
- `POST /v1/workspaces` — create a workspace
- `POST /v1/workspaces/{id}/peers/{peer_id}/chat` — dialectic API

## Auto-deploy

This Space is mirrored from [github.com/rrizwan98/honcho-self-hosted](https://github.com/rrizwan98/honcho-self-hosted) via a GitHub Actions workflow on every push to `main`.

## License

AGPL-3.0 (matches upstream Honcho)
