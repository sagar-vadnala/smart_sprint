"""
Tests for /auth/google. We mock Google's token verification so no real network
or real Google token is needed.
"""

import app.routers.auth as auth_router
from app.core.config import settings


def _enable_google(monkeypatch, payload):
    monkeypatch.setattr(settings, "google_client_id", "test-client-id")

    def fake_verify(token, request, audience):
        if token == "good-token":
            return payload
        raise ValueError("bad token")

    monkeypatch.setattr(
        auth_router.google_id_token, "verify_oauth2_token", fake_verify
    )


def test_google_disabled_returns_503(client):
    # google_client_id defaults to "" → disabled.
    r = client.post("/auth/google", json={"id_token": "anything"})
    assert r.status_code == 503


def test_google_first_login_creates_user_and_personal_org(client, monkeypatch):
    _enable_google(
        monkeypatch,
        {"email": "g@example.com", "name": "Gina Google"},
    )
    r = client.post("/auth/google", json={"id_token": "good-token"})
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["user"]["email"] == "g@example.com"
    assert data["user"]["name"] == "Gina Google"

    headers = {"Authorization": f"Bearer {data['access_token']}"}
    boot = client.get("/bootstrap", headers=headers).json()
    assert len(boot["organizations"]) == 1
    assert boot["organizations"][0]["type"] == "personal"


def test_google_second_login_reuses_account(client, monkeypatch):
    _enable_google(monkeypatch, {"email": "same@example.com", "name": "Same"})
    first = client.post("/auth/google", json={"id_token": "good-token"}).json()
    second = client.post("/auth/google", json={"id_token": "good-token"}).json()
    assert first["user"]["id"] == second["user"]["id"]


def test_google_invalid_token_401(client, monkeypatch):
    _enable_google(monkeypatch, {"email": "x@x.com"})
    r = client.post("/auth/google", json={"id_token": "bad-token"})
    assert r.status_code == 401
