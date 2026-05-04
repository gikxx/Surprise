"""
Tests for /favorites endpoints: get, add, remove, toggle.
"""
from datetime import datetime, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Gift
from tests.conftest import auth_headers

pytestmark = pytest.mark.asyncio


async def _create_gift(session: AsyncSession, name: str = "Gift") -> Gift:
    gift = Gift(
        name=name,
        price=500.0,
        image_url="https://example.com/img.jpg",
        created_at=datetime.now(timezone.utc),
    )
    session.add(gift)
    await session.commit()
    await session.refresh(gift)
    return gift


class TestGetFavorites:
    async def test_get_favorites_empty(self, client: AsyncClient):
        # Arrange
        headers = await auth_headers(client, "fav_empty@example.com")

        # Act
        resp = await client.get("/favorites", headers=headers)

        # Assert
        assert resp.status_code == 200
        assert resp.json() == []

    async def test_get_favorites_requires_auth(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/favorites")

        # Assert
        assert resp.status_code in (401, 403)


class TestAddFavorite:
    async def test_add_favorite_success(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, "AddFav Gift")
        headers = await auth_headers(client, "add_fav@example.com")

        # Act
        resp = await client.post(f"/favorites/{gift.id}", headers=headers)

        # Assert
        assert resp.status_code == 201
        assert resp.json()["is_favorite"] is True

    async def test_add_favorite_idempotent(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, "IdempotentFav")
        headers = await auth_headers(client, "idemp_fav@example.com")
        await client.post(f"/favorites/{gift.id}", headers=headers)

        # Act — повторный запрос
        resp = await client.post(f"/favorites/{gift.id}", headers=headers)

        # Assert
        assert resp.status_code == 201

    async def test_add_favorite_nonexistent_gift_returns_404(self, client: AsyncClient):
        # Arrange
        headers = await auth_headers(client, "fav404@example.com")

        # Act
        resp = await client.post("/favorites/999999", headers=headers)

        # Assert
        assert resp.status_code == 404

    async def test_add_favorite_requires_auth(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session)

        # Act
        resp = await client.post(f"/favorites/{gift.id}")

        # Assert
        assert resp.status_code in (401, 403)

    async def test_added_gift_appears_in_favorites_list(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        # Arrange
        gift = await _create_gift(db_session, "ListedFav")
        headers = await auth_headers(client, "listed_fav@example.com")
        await client.post(f"/favorites/{gift.id}", headers=headers)

        # Act
        resp = await client.get("/favorites", headers=headers)

        # Assert
        assert resp.status_code == 200
        ids = [g["id"] for g in resp.json()]
        assert gift.id in ids


class TestRemoveFavorite:
    async def test_remove_favorite_success(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, "RemoveFav")
        headers = await auth_headers(client, "remove_fav@example.com")
        await client.post(f"/favorites/{gift.id}", headers=headers)

        # Act
        resp = await client.delete(f"/favorites/{gift.id}", headers=headers)

        # Assert
        assert resp.status_code == 200
        assert resp.json()["is_favorite"] is False

    async def test_remove_favorite_idempotent(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, "RemoveIdempotent")
        headers = await auth_headers(client, "remove_idemp@example.com")

        # Act — удаляем подарок, которого нет в избранном
        resp = await client.delete(f"/favorites/{gift.id}", headers=headers)

        # Assert
        assert resp.status_code == 200

    async def test_removed_gift_not_in_favorites_list(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        # Arrange
        gift = await _create_gift(db_session, "RemovedFromList")
        headers = await auth_headers(client, "removed_list@example.com")
        await client.post(f"/favorites/{gift.id}", headers=headers)
        await client.delete(f"/favorites/{gift.id}", headers=headers)

        # Act
        resp = await client.get("/favorites", headers=headers)

        # Assert
        ids = [g["id"] for g in resp.json()]
        assert gift.id not in ids


class TestToggleFavorite:
    async def test_toggle_adds_if_not_favorite(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, "ToggleAdd")
        headers = await auth_headers(client, "toggle_add@example.com")

        # Act
        resp = await client.post(f"/favorites/{gift.id}/toggle", headers=headers)

        # Assert
        assert resp.status_code == 200
        assert resp.json()["is_favorite"] is True

    async def test_toggle_removes_if_already_favorite(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        # Arrange
        gift = await _create_gift(db_session, "ToggleRemove")
        headers = await auth_headers(client, "toggle_remove@example.com")
        await client.post(f"/favorites/{gift.id}/toggle", headers=headers)

        # Act — второй toggle должен убрать из избранного
        resp = await client.post(f"/favorites/{gift.id}/toggle", headers=headers)

        # Assert
        assert resp.status_code == 200
        assert resp.json()["is_favorite"] is False

    async def test_toggle_nonexistent_gift_returns_404(self, client: AsyncClient):
        # Arrange
        headers = await auth_headers(client, "toggle404@example.com")

        # Act
        resp = await client.post("/favorites/999999/toggle", headers=headers)

        # Assert
        assert resp.status_code == 404
