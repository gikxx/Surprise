"""
Tests for /gifts endpoints: list, recommended, search, filter, detail.
"""
from datetime import datetime, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Category, Gift
from tests.conftest import auth_headers

pytestmark = pytest.mark.asyncio


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def _create_gift(
    session: AsyncSession,
    name: str = "Test Gift",
    price: float = 1000.0,
    description: str = "A great gift",
) -> Gift:
    gift = Gift(
        name=name,
        price=price,
        description=description,
        image_url="https://example.com/img.jpg",
        store_name="Store",
        store_url="https://store.com",
        created_at=datetime.now(timezone.utc),
    )
    session.add(gift)
    await session.commit()
    await session.refresh(gift)
    return gift


async def _create_category(session: AsyncSession, name: str = "Tech") -> Category:
    cat = Category(name=name)
    session.add(cat)
    await session.commit()
    await session.refresh(cat)
    return cat


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestListGifts:
    async def test_list_gifts_empty(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/gifts")

        # Assert
        assert resp.status_code == 200
        data = resp.json()
        assert "gifts" in data
        assert "total" in data

    async def test_list_gifts_returns_created_gift(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        await _create_gift(db_session, name="Unique Gift XYZ")

        # Act
        resp = await client.get("/gifts")

        # Assert
        assert resp.status_code == 200
        names = [g["name"] for g in resp.json()["gifts"]]
        assert "Unique Gift XYZ" in names

    async def test_list_gifts_filter_by_min_price(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        await _create_gift(db_session, name="Cheap", price=100.0)
        await _create_gift(db_session, name="Expensive", price=5000.0)

        # Act
        resp = await client.get("/gifts?min_price=1000")

        # Assert
        assert resp.status_code == 200
        for gift in resp.json()["gifts"]:
            assert gift["price"] >= 1000

    async def test_list_gifts_filter_by_max_price(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        await _create_gift(db_session, name="Budget", price=200.0)
        await _create_gift(db_session, name="Luxury", price=9000.0)

        # Act
        resp = await client.get("/gifts?max_price=500")

        # Assert
        assert resp.status_code == 200
        for gift in resp.json()["gifts"]:
            assert gift["price"] <= 500

    async def test_list_gifts_pagination(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        for i in range(5):
            await _create_gift(db_session, name=f"Gift {i}")

        # Act
        resp = await client.get("/gifts?page=1&per_page=2")

        # Assert
        assert resp.status_code == 200
        assert len(resp.json()["gifts"]) <= 2

    async def test_list_gifts_invalid_per_page_uses_default(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/gifts?per_page=999")

        # Assert
        assert resp.status_code == 200


class TestRecommendedGifts:
    async def test_recommended_returns_200(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/gifts/recommended")

        # Assert
        assert resp.status_code == 200
        assert "gifts" in resp.json()

    async def test_recommended_sorted_by_newest(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        g1 = await _create_gift(db_session, name="OldGift")
        g2 = await _create_gift(db_session, name="NewGift")

        # Act
        resp = await client.get("/gifts/recommended")

        # Assert
        gifts = resp.json()["gifts"]
        if len(gifts) >= 2:
            names = [g["name"] for g in gifts]
            assert names.index("NewGift") < names.index("OldGift")


class TestSearchGifts:
    async def test_search_finds_by_name(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        await _create_gift(db_session, name="Unique Surprise Watch")

        # Act
        resp = await client.get("/gifts/search?q=Watch")

        # Assert
        assert resp.status_code == 200
        names = [g["name"] for g in resp.json()["gifts"]]
        assert any("Watch" in n for n in names)

    async def test_search_finds_by_description(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        await _create_gift(db_session, name="Mystery Box", description="Perfect for gamers")

        # Act
        resp = await client.get("/gifts/search?q=gamers")

        # Assert
        assert resp.status_code == 200
        assert resp.json()["total"] >= 1

    async def test_search_empty_query_returns_422(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/gifts/search?q=")

        # Assert
        assert resp.status_code == 422

    async def test_search_no_results(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/gifts/search?q=xyznonexistentxyz")

        # Assert
        assert resp.status_code == 200
        assert resp.json()["total"] == 0

    async def test_search_case_insensitive(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        await _create_gift(db_session, name="Bluetooth Speaker")

        # Act
        resp = await client.get("/gifts/search?q=bluetooth")

        # Assert
        assert resp.status_code == 200
        assert resp.json()["total"] >= 1


class TestGiftDetail:
    async def test_get_gift_by_id(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, name="Detail Gift")

        # Act
        resp = await client.get(f"/gifts/{gift.id}")

        # Assert
        assert resp.status_code == 200
        assert resp.json()["name"] == "Detail Gift"

    async def test_get_nonexistent_gift_returns_404(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.get("/gifts/999999")

        # Assert
        assert resp.status_code == 404

    async def test_gift_is_favorite_false_for_anonymous(self, client: AsyncClient, db_session: AsyncSession):
        # Arrange
        gift = await _create_gift(db_session, name="IsFavGift")

        # Act
        resp = await client.get(f"/gifts/{gift.id}")

        # Assert
        assert resp.json()["is_favorite"] is False

    async def test_gift_is_favorite_true_for_authenticated_user(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        # Arrange
        gift = await _create_gift(db_session, name="FavGift Auth")
        headers = await auth_headers(client, "favcheck@example.com")
        await client.post(f"/favorites/{gift.id}", headers=headers)

        # Act
        resp = await client.get(f"/gifts/{gift.id}", headers=headers)

        # Assert
        assert resp.json()["is_favorite"] is True
