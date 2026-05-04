"""
Unit tests for app/core/security.py — no DB required.
"""
from jose import jwt

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.core.settings import get_settings

class TestPasswordHashing:
    def test_hash_is_not_plain_text(self):
        hashed = get_password_hash("mypassword")
        assert hashed != "mypassword"

    def test_verify_correct_password(self):
        hashed = get_password_hash("correctpassword")
        assert verify_password("correctpassword", hashed) is True

    def test_verify_wrong_password(self):
        hashed = get_password_hash("correctpassword")
        assert verify_password("wrongpassword", hashed) is False

    def test_same_password_produces_different_hashes(self):
        h1 = get_password_hash("samepassword")
        h2 = get_password_hash("samepassword")
        assert h1 != h2  # different salts each time

    def test_long_password_is_hashed_without_error(self):
        long_pass = "a" * 200
        hashed = get_password_hash(long_pass)
        assert verify_password(long_pass, hashed) is True


import pytest


class TestTokenCreation:
    def test_access_token_contains_sub(self):
        token = create_access_token({"sub": "42"})
        settings = get_settings()
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        assert payload["sub"] == "42"

    def test_access_token_type_is_access(self):
        token = create_access_token({"sub": "1"})
        payload = decode_token(token)
        assert payload["type"] == "access"

    def test_refresh_token_type_is_refresh(self):
        token = create_refresh_token({"sub": "1"})
        payload = decode_token(token)
        assert payload["type"] == "refresh"

    def test_access_and_refresh_tokens_are_different(self):
        access = create_access_token({"sub": "1"})
        refresh = create_refresh_token({"sub": "1"})
        assert access != refresh

    def test_token_contains_exp_claim(self):
        token = create_access_token({"sub": "1"})
        payload = decode_token(token)
        assert "exp" in payload

    def test_decode_invalid_token_raises(self):
        from jose import JWTError
        with pytest.raises(JWTError):
            decode_token("this.is.not.valid")
