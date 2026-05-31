from tests.conftest import signup


def test_signup_creates_personal_org(client):
    token, headers = signup(client)
    boot = client.get("/bootstrap", headers=headers).json()
    orgs = boot["organizations"]
    assert len(orgs) == 1
    assert orgs[0]["type"] == "personal"
    assert orgs[0]["name"] == "Personal"


def test_signup_duplicate_email_conflicts(client):
    signup(client, email="dup@x.com")
    r = client.post(
        "/auth/signup",
        json={"name": "B", "email": "dup@x.com", "password": "supersecret1"},
    )
    assert r.status_code == 409


def test_login_wrong_password(client):
    signup(client, email="c@x.com")
    r = client.post(
        "/auth/login", json={"email": "c@x.com", "password": "wrongpass"}
    )
    assert r.status_code == 401
    assert "Incorrect" in r.json()["detail"]


def test_me_requires_token(client):
    assert client.get("/auth/me").status_code == 401


def test_me_returns_user(client):
    _, headers = signup(client, email="d@x.com", name="Dee")
    r = client.get("/auth/me", headers=headers)
    assert r.status_code == 200
    assert r.json()["name"] == "Dee"
