# SmartSprint — Database Schema & Domain Model

How the app actually behaves, translated into tables. Everything is keyed by
UUID strings. Enum values are stored as the **exact Dart enum `.name`** strings
so JSON round-trips with the frontend with zero translation
(`todo`, `inProgress`, `inReview`, `done`; `urgent`/`high`/`normal`/`low`;
`planned`/`active`/`completed`).

## The hierarchy

```
User
 └─ Membership ──┐
                 ▼
          Organization   (type: personal | team)
                 │  every user gets ONE auto-created "Personal" org on signup.
                 ▼
            Workspace     (called "Project" in code; "Space"/"Workspace" in UI)
                 ├─ Sprint        (time-boxed; a task may belong to one or none)
                 └─ Task
                     ├─ TaskAssignee   (M:N task ↔ user)
                     ├─ SubTask         (recursive: parent_subtask_id self-FK)
                     │    └─ SubTaskAssignee (M:N subtask ↔ user)
                     ├─ Comment
                     └─ (Activity references task)
```

### Who can do what
- **Personal org** (`type=personal`): just you. You create workspaces, sprints,
  tasks, subtasks; everything is assigned to you.
- **Team org** (`type=team`): you + invited members. Any member can create
  workspaces/sprints/tasks and **assign tasks/subtasks to any other member** of
  that org. You can be assigned work by others.
- Authorization rule (enforced in every endpoint): a user may only read/write
  rows inside an organization they are a **member** of. We resolve the owning
  org by walking task → workspace → org and checking membership.

## Tables

### users
| col | type | notes |
|---|---|---|
| id | str PK | uuid |
| email | str unique | login id |
| name | str | |
| password_hash | str | bcrypt |
| role | str | display role e.g. "Product Manager" |
| created_at | datetime | |

### organizations
| col | type | notes |
|---|---|---|
| id | str PK | |
| name | str | |
| type | str | `personal` \| `team` |
| color | int | ARGB int (UI swatch) |
| icon | str | icon key (mapped to a const IconData on frontend) |
| owner_id | str FK→users | creator |
| created_at | datetime | |

### memberships  *(unique on org_id+user_id)*
| col | type | notes |
|---|---|---|
| id | str PK | |
| organization_id | str FK→organizations | cascade delete |
| user_id | str FK→users | |
| role | str | `owner` \| `admin` \| `member` |
| created_at | datetime | |

### workspaces  *("Project" in code)*
| col | type | notes |
|---|---|---|
| id | str PK | |
| organization_id | str FK→organizations | cascade |
| name | str | |
| description | str | |
| color | int | ARGB |
| icon | str | icon key |
| created_at | datetime | |

### sprints
| col | type | notes |
|---|---|---|
| id | str PK | |
| workspace_id | str FK→workspaces | cascade |
| name | str | |
| goal | str | |
| start_date | datetime | |
| end_date | datetime | |
| status | str | `planned` \| `active` \| `completed` |
| created_at | datetime | |

### tasks
| col | type | notes |
|---|---|---|
| id | str PK | |
| workspace_id | str FK→workspaces | cascade |
| sprint_id | str FK→sprints null | null = backlog |
| title | str | |
| description | str | |
| status | str | TaskStatus.name |
| priority | str | TaskPriority.name |
| due_date | datetime null | |
| created_by | str FK→users | |
| created_at | datetime | |

### task_assignees  *(M:N, PK = task_id+user_id)*
| task_id FK→tasks | user_id FK→users |

### subtasks  *(recursive)*
| col | type | notes |
|---|---|---|
| id | str PK | |
| task_id | str FK→tasks | cascade; the root task |
| parent_subtask_id | str FK→subtasks null | null = top level under task |
| title | str | |
| description | str | |
| status | str | TaskStatus.name |
| priority | str null | optional |
| due_date | datetime null | optional |
| position | int | ordering |
| created_at | datetime | |

### subtask_assignees  *(M:N, PK = subtask_id+user_id)*

### comments
| col | type | notes |
|---|---|---|
| id | str PK | |
| task_id | str FK→tasks | cascade |
| author_id | str FK→users | |
| body | str | |
| created_at | datetime | |

### activities  *(the timeline)*
| col | type | notes |
|---|---|---|
| id | str PK | |
| organization_id | str FK→organizations | cascade; scoping |
| workspace_id | str null | |
| task_id | str null | per-task timeline filter |
| actor_id | str FK→users | who did it |
| kind | str | ActivityKind.name |
| text | str | e.g. "moved to In Review" |
| task_title | str null | |
| body | str null | comment text when kind=comment |
| created_at | datetime | |

## Key endpoints
- `POST /auth/signup` → also creates the user's Personal org + owner membership.
- `GET /bootstrap` → everything the app needs on launch: my orgs (+members),
  and for each org its workspaces, sprints, tasks (+assignees+subtasks),
  activities. One round-trip cold-start friendly.
- `organizations`: create / list-mine / get / members / add-member.
- `workspaces`, `sprints`, `tasks`, `subtasks`, `comments`, `activities`:
  standard CRUD, all membership-guarded.

## Migrations
`init_db` uses `create_all` (fine while iterating). Move to Alembic before the
schema changes in production.
