# Google Sign-In — setup

The code is done (backend `/auth/google` + the app's "Continue with Google"
button). To make it actually work you create a Google OAuth client and plug the
**Web client ID** into both the backend and the app. ~10 minutes, free.

## How it works
1. The app runs Google's sign-in flow and gets an **ID token**.
2. The app POSTs it to `POST /auth/google`.
3. The backend verifies the token was issued by Google **for your client**,
   then finds-or-creates the account (+ a Personal org) and returns our JWT.

The same **Web client ID** is used everywhere so the token's audience matches:
- web → passed as `clientId`
- mobile → passed as `serverClientId`
- backend → `GOOGLE_CLIENT_ID` it verifies against

---

## 1. Create the OAuth client (Google Cloud Console)
1. Go to **https://console.cloud.google.com** → create/select a project.
2. **APIs & Services → OAuth consent screen** → External → fill app name + your
   email → add yourself as a Test user (keeps it in testing mode, which is fine).
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID →
   Web application**. Under *Authorized JavaScript origins* add where the web app
   runs, e.g. `http://localhost:PORT` (your `flutter run -d chrome` port) and your
   deployed web URL. **Copy the Client ID** — this is your `GOOGLE_CLIENT_ID`.

> For Android/iOS you'd also create Android/iOS OAuth client IDs later and add
> platform config (google-services.json / reversed client id in Info.plist). For
> web + testing, the Web client ID alone is enough.

## 2. Tell the backend (Render)
In your Render service → Environment → add:
```
GOOGLE_CLIENT_ID = <your Web client ID>.apps.googleusercontent.com
```
Redeploy. (Locally: put it in `backend/.env`.)

## 3. Tell the app
Run/build with the same id injected:
```
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://smartsprint-api.onrender.com \
  --dart-define=GOOGLE_CLIENT_ID=<your Web client ID>.apps.googleusercontent.com
```

If `GOOGLE_CLIENT_ID` is empty, the button shows a friendly "not configured"
message and email/password keeps working — nothing breaks.

---

## Notes / gotchas
- **Web** also needs this meta tag in `web/index.html` `<head>` for the People
  API / GIS to pick up the client (some setups):
  `<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID">`
  (The `clientId` param we pass usually suffices, but add this if web sign-in
  misbehaves.)
- `google_sign_in` is pinned to **^6.2.2** (stable v6 API). If you later move to
  v7, the client call in `AuthBloc._onGoogleSignIn` changes.
- SSO users have no password (empty hash) — they can only sign in with Google.
- Backend Google verification is covered by tests (`tests/test_google_auth.py`)
  using a mocked verifier, so no real Google token is needed to run `pytest`.
