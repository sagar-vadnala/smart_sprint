"""Tests for the organization invitation flow (invite → accept)."""

from tests.conftest import signup


def _create_team_org(client, headers, name="Acme"):
    r = client.post(
        "/organizations",
        json={"name": name, "type": "team"},
        headers=headers,
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


def _token_from_url(url: str) -> str:
    return url.rsplit("/invite/", 1)[1]


def test_invite_and_accept_flow(client):
    # Admin creates a team org and invites someone who has no account yet.
    _, admin = signup(client, email="admin@acme.com", name="Admin")
    org_id = _create_team_org(client, admin)

    r = client.post(
        f"/organizations/{org_id}/invites",
        json={"email": "new@acme.com"},
        headers=admin,
    )
    assert r.status_code == 201, r.text
    body = r.json()
    # No SMTP configured in tests → email not sent, link returned instead.
    assert body["emailSent"] is False
    token = _token_from_url(body["acceptUrl"])

    # Public preview works before login.
    pr = client.get(f"/invites/{token}")
    assert pr.status_code == 200
    assert pr.json()["status"] == "pending"
    assert pr.json()["organizationName"] == "Acme"

    # Invitee signs up with the invited email, then accepts.
    _, invitee = signup(client, email="new@acme.com", name="Newbie")
    acc = client.post(f"/invites/{token}/accept", headers=invitee)
    assert acc.status_code == 200, acc.text
    assert acc.json()["id"] == org_id

    # They now see the org in their bootstrap.
    boot = client.get("/bootstrap", headers=invitee)
    org_ids = {o["id"] for o in boot.json()["organizations"]}
    assert org_id in org_ids


def test_wrong_email_cannot_accept(client):
    _, admin = signup(client, email="admin2@acme.com", name="Admin")
    org_id = _create_team_org(client, admin)
    r = client.post(
        f"/organizations/{org_id}/invites",
        json={"email": "intended@acme.com"},
        headers=admin,
    )
    token = _token_from_url(r.json()["acceptUrl"])

    # A different account opens the link.
    _, other = signup(client, email="someone-else@acme.com", name="Other")
    acc = client.post(f"/invites/{token}/accept", headers=other)
    assert acc.status_code == 403
    assert "intended@acme.com" in acc.json()["detail"]


def test_personal_org_cannot_invite(client):
    _, headers = signup(client, email="solo@acme.com", name="Solo")
    boot = client.get("/bootstrap", headers=headers)
    personal = next(o for o in boot.json()["organizations"] if o["type"] == "personal")
    r = client.post(
        f"/organizations/{personal['id']}/invites",
        json={"email": "friend@acme.com"},
        headers=headers,
    )
    assert r.status_code == 400


def test_non_admin_cannot_invite(client):
    # Owner sets up org + invites a member.
    _, owner = signup(client, email="owner@acme.com", name="Owner")
    org_id = _create_team_org(client, owner)
    r = client.post(
        f"/organizations/{org_id}/invites",
        json={"email": "member@acme.com"},
        headers=owner,
    )
    token = _token_from_url(r.json()["acceptUrl"])
    _, member = signup(client, email="member@acme.com", name="Member")
    client.post(f"/invites/{token}/accept", headers=member)

    # A plain member (role=member) tries to invite — forbidden.
    r2 = client.post(
        f"/organizations/{org_id}/invites",
        json={"email": "third@acme.com"},
        headers=member,
    )
    assert r2.status_code == 403


def test_already_member_invite_conflicts(client):
    _, admin = signup(client, email="admin3@acme.com", name="Admin")
    org_id = _create_team_org(client, admin)
    # Inviting yourself (already a member) is a conflict.
    r = client.post(
        f"/organizations/{org_id}/invites",
        json={"email": "admin3@acme.com"},
        headers=admin,
    )
    assert r.status_code == 409
