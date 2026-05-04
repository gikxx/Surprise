"""
Shared fixtures for all backend tests.

Uses an in-memory SQLite database so tests run without a real PostgreSQL instance.
Each test gets a fresh database via function-scoped fixtures.
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import StaticPool

from app.core.db import Base, get_session
from app.main import create_app

# ---------------------------------------------------------------------------
# In-memory SQLite engine (shared across the whole test session for speed,
# but each test rolls back via the session fixture below)
# ---------------------------------------------------------------------------
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture(scope="session")
async def engine():
    _engine = create_async_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield _engine
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await _engine.dispose()


@pytest_asyncio.fixture
async def db_session(engine):
    """Fresh async session per test; rolls back after each test."""
    async_session = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session):
    """AsyncClient wired to the FastAPI app with the test DB session."""
    app = create_app()

    async def override_get_session():
        yield db_session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def register_user(client: AsyncClient, email: str = "test@example.com", password: str = "secret123") -> dict:
    """Register a user and return the JSON response."""
    resp = await client.post("/auth/register", json={
        "name": "Test User",
        "email": email,
        "password": password,
    })
    assert resp.status_code == 201, resp.text
    return resp.json()


async def auth_headers(client: AsyncClient, email: str = "test@example.com", password: str = "secret123") -> dict:
    """Register (if needed) and return Authorization headers."""
    data = await register_user(client, email, password)
    return {"Authorization": f"Bearer {data['token']}"}
