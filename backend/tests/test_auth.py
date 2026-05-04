"""
Tests for /auth endpoints: register, login, refresh, delete account.
"""
import pytest
from httpx import AsyncClient

from tests.conftest import register_user, auth_headers

pytestmark = pytest.mark.asyncio


class TestRegister:
    async def test_register_with_email_success(self, client: AsyncClient):
        # Arrange
        payload = {"name": "Karina", "email": "karina@example.com", "password": "password123"}

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 201
        data = resp.json()
        assert data["user"]["email"] == "karina@example.com"
        assert data["user"]["name"] == "Karina"
        assert "token" in data
        assert "refresh_token" in data

    async def test_register_with_phone_success(self, client: AsyncClient):
        # Arrange
        payload = {"name": "Ivan", "phone": "+79001234567", "password": "password123"}

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 201
        assert resp.json()["user"]["phone"] == "+79001234567"

    async def test_register_duplicate_email_returns_400(self, client: AsyncClient):
        # Arrange
        payload = {"name": "User", "email": "dup@example.com", "password": "pass123"}
        await client.post("/auth/register", json=payload)

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 400
        assert "email" in resp.json()["detail"].lower()

    async def test_register_duplicate_phone_returns_400(self, client: AsyncClient):
        # Arrange
        payload = {"name": "User", "phone": "+79009999999", "password": "pass123"}
        await client.post("/auth/register", json=payload)

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 400
        assert "phone" in resp.json()["detail"].lower()

    async def test_register_without_email_or_phone_returns_422(self, client: AsyncClient):
        # Arrange
        payload = {"name": "NoContact", "password": "pass123"}

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 422

    async def test_register_short_password_returns_422(self, client: AsyncClient):
        # Arrange
        payload = {"name": "User", "email": "short@example.com", "password": "123"}

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 422

    async def test_register_invalid_phone_returns_422(self, client: AsyncClient):
        # Arrange
        payload = {"name": "User", "phone": "123", "password": "pass123"}

        # Act
        resp = await client.post("/auth/register", json=payload)

        # Assert
        assert resp.status_code == 422


class TestLogin:
    async def test_login_by_email_success(self, client: AsyncClient):
        # Arrange
        await register_user(client, "login@example.com", "mypassword")

        # Act
        resp = await client.post("/auth/login", json={
            "email_or_phone": "login@example.com",
            "password": "mypassword",
        })

        # Assert
        assert resp.status_code == 200
        data = resp.json()
        assert "token" in data
        assert data["user"]["email"] == "login@example.com"

    async def test_login_by_phone_success(self, client: AsyncClient):
        # Arrange
        await client.post("/auth/register", json={
            "name": "PhoneUser", "phone": "+79001112233", "password": "mypassword",
        })

        # Act
        resp = await client.post("/auth/login", json={
            "email_or_phone": "+79001112233",
            "password": "mypassword",
        })

        # Assert
        assert resp.status_code == 200
        assert "token" in resp.json()

    async def test_login_wrong_password_returns_401(self, client: AsyncClient):
        # Arrange
        await register_user(client, "wrongpass@example.com", "correctpass")

        # Act
        resp = await client.post("/auth/login", json={
            "email_or_phone": "wrongpass@example.com",
            "password": "wrongpass",
        })

        # Assert
        assert resp.status_code == 401

    async def test_login_nonexistent_user_returns_401(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.post("/auth/login", json={
            "email_or_phone": "ghost@example.com",
            "password": "anypass",
        })

        # Assert
        assert resp.status_code == 401


class TestRefreshToken:
    async def test_refresh_returns_new_tokens(self, client: AsyncClient):
        # Arrange
        data = await register_user(client, "refresh@example.com")

        # Act
        resp = await client.post("/auth/refresh", json={"refresh_token": data["refresh_token"]})

        # Assert
        assert resp.status_code == 200
        assert "token" in resp.json()
        assert "refresh_token" in resp.json()

    async def test_refresh_with_access_token_returns_401(self, client: AsyncClient):
        # Arrange — передаём access-токен вместо refresh
        data = await register_user(client, "badrefresh@example.com")

        # Act
        resp = await client.post("/auth/refresh", json={"refresh_token": data["token"]})

        # Assert
        assert resp.status_code == 401

    async def test_refresh_with_garbage_returns_401(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.post("/auth/refresh", json={"refresh_token": "not.a.valid.token"})

        # Assert
        assert resp.status_code == 401


class TestDeleteAccount:
    async def test_delete_account_success(self, client: AsyncClient):
        # Arrange
        headers = await auth_headers(client, "delete_me@example.com")

        # Act
        resp = await client.delete("/auth/me", headers=headers)

        # Assert
        assert resp.status_code == 204

    async def test_delete_account_without_token_returns_403(self, client: AsyncClient):
        # Arrange / Act
        resp = await client.delete("/auth/me")

        # Assert
        assert resp.status_code in (401, 403)
