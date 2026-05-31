"""Authorization isolation — the most important guarantees to lock down."""

from tests.conftest import signup


def _personal(client, headers):
    orgs = client.get("/organizations", headers=headers).json()
    return next(o["id"] for o in orgs if o["type"] == "personal")


def test_other_user_cannot_see_or_touch_my_task(client):
    _, alice = signup(client, email="alice@x.com")
    ws = client.post(
        "/workspaces", headers=alice,
        json={"organizationId": _personal(client, alice), "name": "W"},
    ).json()
    task = client.post(
        "/tasks", headers=alice, json={"projectId": ws["id"], "title": "Secret"}
    ).json()

    _, bob = signup(client, email="bob@x.com", name="Bob")

    # Bob can't read it.
    assert client.get(f"/tasks/{task['id']}", headers=bob).status_code == 403
    # Bob can't patch it.
    assert (
        client.patch(
            f"/tasks/{task['id']}", headers=bob, json={"title": "Hacked"}
        ).status_code
        == 403
    )
    # Bob can't delete it.
    assert client.delete(f"/tasks/{task['id']}", headers=bob).status_code == 403
    # Bob's bootstrap shows none of Alice's data.
    boot = client.get("/bootstrap", headers=bob).json()
    assert boot["tasks"] == []
    assert boot["workspaces"] == []


def test_cannot_create_workspace_in_foreign_org(client):
    _, alice = signup(client, email="a2@x.com")
    alice_org = _personal(client, alice)
    _, bob = signup(client, email="b2@x.com")
    r = client.post(
        "/workspaces", headers=bob,
        json={"organizationId": alice_org, "name": "Intruder"},
    )
    assert r.status_code == 403


def test_team_org_member_management_requires_privilege(client):
    # Owner creates a team org and can invite.
    _, owner = signup(client, email="owner@x.com")
    team = client.post(
        "/organizations", headers=owner,
        json={"name": "Hikigai", "type": "team"},
    ).json()
    # The invitee must exist first.
    signup(client, email="member@x.com", name="Mem")
    r = client.post(
        f"/organizations/{team['id']}/members",
        headers=owner,
        json={"email": "member@x.com"},
    )
    assert r.status_code == 201
    assert len(r.json()) == 2  # owner + new member

    # A plain member cannot invite others.
    _, member = signup(client, email="member2@x.com")
    # member2 isn't even in the org → 403 (require_org first).
    r2 = client.post(
        f"/organizations/{team['id']}/members",
        headers=member,
        json={"email": "owner@x.com"},
    )
    assert r2.status_code == 403


def test_personal_org_cannot_add_members(client):
    _, owner = signup(client, email="solo@x.com")
    personal = _personal(client, owner)
    signup(client, email="x@x.com")
    r = client.post(
        f"/organizations/{personal}/members",
        headers=owner,
        json={"email": "x@x.com"},
    )
    assert r.status_code == 400
