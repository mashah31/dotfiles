---
globs: "**/*.py"
---

# Python / FastAPI Rules

## Package Management
- Always `uv add` / `uv run` / `uv sync` — never `pip install`
- Docker builds use `uv sync --frozen`
- Python pinned to 3.12 via `.python-version` and `pyproject.toml`

## Architecture (router → service → crud)
- `router.py` — HTTP boundary only: parse input, call service, return response
- `service.py` — business logic, no DB access
- `crud.py` — all Tortoise queries, nothing else
- `deps.py` — FastAPI `Depends()` for this domain; `core/deps.py` for shared providers (e.g. `transaction()`)

Never put logic in routers. Never query DB from services directly.

## Database (Tortoise ORM + Aerich)
- Async-native, parameterized by default (SQL-injection safe)
- Always set explicit pool `minsize`/`maxsize` — never accept defaults in prod
- Pool sizing rule: `maxsize × replicas ≤ postgres max_connections × 0.8`
- Never `generate_schemas=True` in prod
- No raw SQL unless profiling proves ORM is the bottleneck — if needed, always parameterized
- Prefer `get_or_none()` over `get()`. Use `select_related()` / `prefetch_related()` to avoid N+1
- Transactions via `Depends(transaction)` from `core/deps.py`

## Auth (JWT)
- PyJWT + bcrypt + FastAPI OAuth2. Stateless — no sessions, no Redis needed
- `get_current_user` / `get_current_admin` live in `auth/deps.py`
- Never return `hashed_password` in any schema
- Token expires 30 min (`ACCESS_TOKEN_EXPIRE_MINUTES`); rotate `SECRET_KEY` per environment

## LLM (LiteLLM — provider-agnostic)
- Never import `google.generativeai` or `anthropic` directly in business code — use `core/llm.py`
- Switch providers via env var only: `LLM_PROVIDER=vertex_ai/gemini-2.0-flash` → `anthropic/claude-sonnet-4-6` etc.
- Always `timeout=30`. Never log prompts containing PII.

## Observability
- Log format: `log.info("event_name", user_id=..., duration_ms=...)` — never f-strings
- `/metrics` endpoint excluded from auth and Loki ingestion
- Traces: 10% sample in prod, 100% in dev
- Call `setup_observability(app)` in lifespan (`app/observability/__init__.py`)

## Type Hints & Style
- `from __future__ import annotations` in every module
- All signatures fully typed — no bare `Any`
- `mypy --strict` + `ruff check` + `ruff format` must pass
- No `print()` — use `structlog.get_logger(__name__)`
- 88-char line length

## Testing
- Integration tests hit a **real** test Postgres — never mock the DB
- Mock external HTTP/LLM via `respx` / `pytest-httpx`
- `pytest-asyncio` with `asyncio_mode = "auto"`
