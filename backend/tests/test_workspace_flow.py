from datetime import datetime, timedelta, timezone

from tests.conftest import signup


def _org_id(client, headers, kind="personal"):
    orgs = client.get("/organizations", headers=headers).json()
    return next(o["id"] for o in orgs if o["type"] == kind)


def test_full_create_flow_and_colors(client):
    _, headers = signup(client)
    personal = _org_id(client, headers)

    # Big ARGB colour must round-trip (regression test for the BigInteger fix).
    big_color = 0xFF6C47FF  # 4285286399 — overflows signed INT32
    ws = client.post(
        "/workspaces",
        headers=headers,
        json={
            "organizationId": personal,
            "name": "Mobile App",
            "description": "client",
            "color": big_color,
            "icon": "phone",
        },
    ).json()
    assert ws["color"] == big_color
    assert ws["icon"] == "phone"

    now = datetime.now(timezone.utc)
    sprint = client.post(
        "/sprints",
        headers=headers,
        json={
            "projectId": ws["id"],
            "name": "Sprint 1",
            "goal": "ship",
            "startDate": now.isoformat(),
            "endDate": (now + timedelta(days=14)).isoformat(),
        },
    ).json()
    assert sprint["status"] == "planned"

    me = client.get("/auth/me", headers=headers).json()["id"]
    task = client.post(
        "/tasks",
        headers=headers,
        json={
            "projectId": ws["id"],
            "sprintId": sprint["id"],
            "title": "Build login",
            "priority": "high",
            "assigneeIds": [me],
        },
    ).json()
    assert task["assigneeIds"] == [me]
    assert task["sprintId"] == sprint["id"]


def test_nested_subtasks_and_status(client):
    _, headers = signup(client)
    personal = _org_id(client, headers)
    ws = client.post(
        "/workspaces",
        headers=headers,
        json={"organizationId": personal, "name": "W"},
    ).json()
    task = client.post(
        "/tasks", headers=headers, json={"projectId": ws["id"], "title": "T"}
    ).json()

    t = client.post(
        f"/tasks/{task['id']}/subtasks", headers=headers, json={"title": "Parent"}
    ).json()
    parent_id = t["subtasks"][0]["id"]
    t = client.post(
        f"/tasks/{task['id']}/subtasks",
        headers=headers,
        json={"title": "Child", "parentSubTaskId": parent_id},
    ).json()
    assert t["subtasks"][0]["subtasks"][0]["title"] == "Child"

    # Mark the parent done.
    t = client.patch(
        f"/tasks/{task['id']}/subtasks/{parent_id}",
        headers=headers,
        json={"status": "done"},
    ).json()
    assert t["subtasks"][0]["status"] == "done"


def test_move_and_duplicate(client):
    _, headers = signup(client)
    personal = _org_id(client, headers)
    ws = client.post(
        "/workspaces", headers=headers,
        json={"organizationId": personal, "name": "W"},
    ).json()
    sprint = _make_sprint(client, headers, ws["id"])
    task = client.post(
        "/tasks", headers=headers,
        json={"projectId": ws["id"], "sprintId": sprint["id"], "title": "T"},
    ).json()

    # Move to backlog.
    moved = client.patch(
        f"/tasks/{task['id']}", headers=headers, json={"clearSprint": True}
    ).json()
    assert moved["sprintId"] is None

    # Duplicate.
    dup = client.post(f"/tasks/{task['id']}/duplicate", headers=headers).json()
    assert dup["title"].endswith("(copy)")
    assert dup["id"] != task["id"]


def _make_sprint(client, headers, ws_id):
    now = datetime.now(timezone.utc)
    return client.post(
        "/sprints",
        headers=headers,
        json={
            "projectId": ws_id,
            "name": "S",
            "startDate": now.isoformat(),
            "endDate": (now + timedelta(days=7)).isoformat(),
        },
    ).json()


def test_comment_appears_in_activity(client):
    _, headers = signup(client)
    personal = _org_id(client, headers)
    ws = client.post(
        "/workspaces", headers=headers,
        json={"organizationId": personal, "name": "W"},
    ).json()
    task = client.post(
        "/tasks", headers=headers, json={"projectId": ws["id"], "title": "T"}
    ).json()
    client.post(
        f"/tasks/{task['id']}/comments", headers=headers, json={"body": "Nice"}
    )
    boot = client.get("/bootstrap", headers=headers).json()
    comments = [a for a in boot["activities"] if a["kind"] == "comment"]
    assert any(c["body"] == "Nice" for c in comments)
