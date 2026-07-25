---
name: python
description: Python best practices — typing, project structure, packaging, FastAPI patterns, async, testing, and idiomatic Python. Use when writing Python code, structuring a Python project, or whenever the user mentions "Python," "FastAPI," "Django," "pytest," "PEP 8," "type hints," "Pydantic," "asyncio," "pip," "poetry," or "uv."
---

# Python Best Practices

## Type Hints

Python 3.10+ type hints are the standard. Enable via `pyproject.toml`.

```toml
[tool.pyright]
typeCheckingMode = "strict"
```

```python
from collections.abc import Sequence
from dataclasses import dataclass
from typing import assert_never

@dataclass
class User:
    id: str
    email: str
    name: str | None  # Optional[str] in 3.8-3.9

def create_user(
    email: str,
    name: str | None = None,
    tags: Sequence[str] = (),
) -> User: ...
```

**Rules:**
- Annotate all function signatures (params + return). No `def f(x, y):`.
- Use `|` union syntax (3.10+) over `Optional[Union[...]]`.
- Use `Sequence` over `List` for parameters (accepts tuples/lists/sets).
- Use `TypeVar` for generics.
- Avoid `Any`. Use `object` or `Unknown` (pyright) if truly untyped.

## Project Structure

```
project/
├── src/
│   └── app/
│       ├── __init__.py
│       ├── domain/           # Pure business logic
│       ├── application/      # Use cases
│       ├── infrastructure/   # DB, external APIs
│       └── presentation/     # API routes, CLI
├── tests/
│   ├── unit/
│   └── integration/
├── pyproject.toml
├── uv.lock                   # or poetry.lock
└── README.md
```

**Packaging:** Always use `src/` layout — prevents importing from project root by accident.

## Modern Tooling

| Tool | Purpose | Overrides |
|------|---------|-----------|
| **uv** | Package manager, venv, runner | pip, poetry, pipenv |
| **pytest** | Testing | unittest |
| **ruff** | Linter + formatter | flake8, black, isort |
| **pyright** | Type checker | mypy |
| **Pydantic** | Validation + serialization | dataclasses (for complex validation) |

```toml
[tool.ruff]
target-version = "py312"
line-length = 100
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM", "ARG", "RUF"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```

## FastAPI Patterns

```python
from pydantic import BaseModel, EmailStr
from fastapi import FastAPI, HTTPException

app = FastAPI()

# Pydantic models at the boundary
class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str | None = None

class UserResponse(BaseModel):
    id: str
    email: str
    name: str | None

@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(body: CreateUserRequest):
    # Use case or service layer — not raw ORM here
    user = await user_service.create(body.email, body.name)
    if not user:
        raise HTTPException(409, "Email already exists")
    return UserResponse.model_validate(user)
```

- **Dependency injection** — FastAPI `Depends()` for shared deps (DB session, auth).
- **Pydantic v2** — `model_validate()` not `from_orm()`.
- **Path operations** — thin controllers. Business logic in use cases.

## Async Best Practices

- **Only async when you need IO** — DB, HTTP, file, network. CPU work should stay sync.
- **Use `asyncio.run()`** for entry point, `asyncio.gather()` for concurrent IO.
- **Never mix blocking with async** — no `time.sleep()`, no `requests` in async code.
- **Prefer `httpx.AsyncClient`** over `requests` for async APIs.
- **Database:** `asyncpg` (Postgres), `redis.asyncio`, `motor` (Mongo).

```python
import asyncio
import httpx

async def fetch_all(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
    return [r.json() for r in results if isinstance(r, httpx.Response)]
```

## Testing (pytest)

```python
# tests/unit/test_order.py
from app.domain.order import Order, OrderItem
from datetime import datetime

def test_order_total_calculates_correctly():
    order = Order(items=[
        OrderItem(price=10.0, quantity=2),
        OrderItem(price=5.0, quantity=1),
    ])
    assert order.total == 25.0  # 10*2 + 5*1

def test_order_rejects_empty_items():
    with pytest.raises(ValueError, match="at least one item"):
        Order(items=[])

@pytest.mark.asyncio
async def test_create_user_duplicate_email():
    repo = InMemoryUserRepo()  # fake
    service = UserService(repo)
    await service.create("a@x.com")
    with pytest.raises(DuplicateEmailError):
        await service.create("a@x.com")
```

- **Fixtures over setup/teardown.**
- **Parametrize** for multiple cases — `@pytest.mark.parametrize`.
- **Fakes over mocks** — in-memory DB, fake HTTP client.

## Anti-patterns

- ❌ `from module import *` — pollutes namespace
- ❌ Mutable default args — `def f(x=[]):` — shared across calls
- ❌ Bare `except:` — catches `KeyboardInterrupt`, `SystemExit`, everything
- ❌ Type hints at wrong level — only annotate public API, not every internal variable
- ❌ `print()` for debugging — use `logging` or `loguru`
- ❌ `requirements.txt` without lock — use `uv.lock` / `poetry.lock`
- ❌ Try-except-pass — swallows errors silently
