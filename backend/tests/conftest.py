"""
Pytest fixtures. Each test run gets a fresh in-memory SQLite database and a
TestClient, so tests are isolated and never touch a real DB.
"""

import os

# Force SQLite BEFORE importing the app (the engine is built at import time).
# This guarantees tests never connect to a real/Neon database, even if a
# developer has a .env with DATABASE_URL set.
os.environ["DATABASE_URL"] = "sqlite://"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.core.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    # Shared in-memory DB across the app's connections within one test.
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    # Importing `app.main` (above) already registered every model on
    # Base.metadata via the routers, so the schema is complete here.
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)


def signup(client, email="a@x.com", name="Alice", password="supersecret1"):
    r = client.post(
        "/auth/signup",
        json={"name": name, "email": email, "password": password},
    )
    assert r.status_code == 201, r.text
    token = r.json()["access_token"]
    return token, {"Authorization": f"Bearer {token}"}
