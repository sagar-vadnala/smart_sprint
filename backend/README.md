# SmartSprint API (FastAPI)

The Python backend for the SmartSprint app. Email/password auth with JWT,
SQLAlchemy ORM, Postgres in production (SQLite locally for zero-setup dev).

```
backend/
  app/
    main.py            # FastAPI app + CORS + router wiring
    core/
      config.py        # env-driven settings (DATABASE_URL, JWT_SECRET, ...)
      database.py      # SQLAlchemy engine/session, table creation
      security.py      # bcrypt password hashing + JWT create/verify
      deps.py          # get_current_user (Bearer auth) dependency
    models/user.py     # User table
    schemas/auth.py    # request/response shapes (Pydantic)
    routers/auth.py    # /auth/signup, /auth/login, /auth/me
  requirements.txt
  render.yaml          # one-click-ish Render deploy
  .env.example
```

---

## 1. Run locally (optional, to test before deploying)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

- API: http://127.0.0.1:8000
- **Interactive docs (try the endpoints here):** http://127.0.0.1:8000/docs

With no `.env`, it uses a local `smart_sprint.db` SQLite file — nothing to set up.

---

## 2. Deploy for free (Neon Postgres + Render) — ~10 minutes

You do this once; afterwards the Flutter app talks to a real `https://` URL.

### A. Create a free Postgres database (Neon)
1. Sign up at **https://neon.tech** (free tier).
2. Create a project → it gives you a **connection string** like:
   `postgresql://user:pass@ep-xxx.neon.tech/dbname?sslmode=require`
3. Change the scheme from `postgresql://` to **`postgresql+psycopg://`**
   (this tells SQLAlchemy to use the psycopg v3 driver). Keep it for step C.

### B. Push this repo to GitHub
Render deploys from a Git repo. Make sure `backend/` is committed.

### C. Deploy the API (Render)
1. Sign up at **https://render.com** (free).
2. **New → Blueprint** → connect your GitHub repo. Render reads `backend/render.yaml`.
3. When prompted, set env vars:
   - `DATABASE_URL` = the Neon string from step A (with `+psycopg`).
   - `JWT_SECRET` = leave it (Render auto-generates a strong one), or paste your own.
4. Create. First build takes a few minutes; you get a URL like
   `https://smartsprint-api.onrender.com`.
5. Visit `https://<your-url>/docs` to confirm it's live.

> ⚠️ **Free tier cold start:** Render free services sleep after ~15 min idle and
> take ~50s to wake on the next request. Normal for $0. Upgrade later if it bugs you.

### D. Point the Flutter app at it
Run / build the app with the URL injected (no hard-coded localhost):

```bash
flutter run --dart-define=API_BASE_URL=https://smartsprint-api.onrender.com
# web build:
flutter build web --dart-define=API_BASE_URL=https://smartsprint-api.onrender.com
```

That's it — signup/login now hit your deployed API.

---

## Endpoints

| Method | Path           | Body                                  | Returns                         |
|--------|----------------|---------------------------------------|---------------------------------|
| POST   | `/auth/signup` | `{ name, email, password }`           | `{ access_token, user }`        |
| POST   | `/auth/login`  | `{ email, password }`                 | `{ access_token, user }`        |
| GET    | `/auth/me`     | — (Bearer token in `Authorization`)   | `{ id, name, email, role, ... }`|

Send the token on protected requests as: `Authorization: Bearer <access_token>`.

---

## Next phase
Auth is the foundation. The same pattern (model → schema → router) extends to
organizations, workspaces, sprints, tasks, comments — each becomes a table and a
router, all guarded by `get_current_user`.
