# tailgating

A new way to split responsibilites and cooperate to have the greatest tailgating experience.

## Persistent tailgate server

### Run locally

Run the API in one terminal (Python 3.10 or newer, no extra packages):

```sh
python server/server.py
```

The server listens on port 8080 and stores data in `server/data/tailgates.sqlite3`.
The default address is intended for a local app on the same computer.

### Host it for multiple people

The API can run in Docker on any host that supports containers. Configure a
persistent disk mounted at `/data`; otherwise a container restart or redeploy may
erase tailgates and device sessions. Set `ALLOWED_ORIGINS` to the exact HTTPS
origin where the Flutter web app is hosted (for example,
`https://tailgates.example.com`). For multiple app domains, separate origins with
commas. Then build and run:

```sh
docker build -t bayoublitz-api .
docker run --name bayoublitz-api -p 8080:8080 \
  -e ALLOWED_ORIGINS=https://tailgates.example.com \
  -v bayoublitz-data:/data bayoublitz-api
```

Set the Flutter app's API URL to the public HTTPS API address when building it:

```sh
flutter build web --release \
  --dart-define=TAILGATE_API_URL=https://api.example.com
```

The host must expose that address over HTTPS and keep `/data` on persistent
storage. Configure the host's TLS/domain and persistent volume in its dashboard.
The current app uses anonymous device sessions, so each browser/device remains a
distinct member identity; clearing its local storage loses access to that identity.

Run Flutter in another terminal:

```sh
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173
```

The app uses `http://127.0.0.1:8080` by default. To point it at another API,
use `--dart-define=TAILGATE_API_URL=https://api.example.com` when running or building.
Local HTTP browser origins remain allowed for development; hosted browser origins
must be listed in the API's `ALLOWED_ORIGINS`. Android emulators can use
`http://10.0.2.2:8080` for a local development server where networking and the
app's HTTP policy allow it.

Tailgates, invite codes, memberships, and anonymous device sessions are stored in
`server/data/tailgates.sqlite3` (ignored by Git). Back up that database; deleting it
deletes the saved data. The server starts empty, with no demo memberships.
The device's anonymous session token is stored in app/browser preferences, so
refreshing, signing out, or restarting the API does not remove memberships.
Different browsers/devices get different guest identities. Clearing app/browser
storage loses access to that identity. Username/password sign-in remains a demo;
it is not an account recovery mechanism.

Hosts join their tailgate when creating it. Public tailgates are discoverable;
private tailgates require an invite code. If a host leaves while members remain,
the server transfers hosting to a remaining member. The last member must confirm
permanent deletion. Membership removal and deletion happen in one SQLite
transaction, including rechecking whether the member is now the last person.
Deleted tailgates and their invite codes cannot be rejoined.

Use Refresh in the Tailgates tab to see changes made by another device. Home's
My tailgates list uses the same saved memberships. Other demo features, such as
profile preferences, checklist edits, and the game-day preview, are not persisted
by this API.

Run backend tests with:

```sh
python -m unittest discover -s server -v
```

## Automated web builds

The `Flutter web build` GitHub Actions workflow runs on every push and pull
request. It can also be started manually from the repository's Actions tab.
It uses Flutter 3.47.7, installs the locked dependencies, runs static analysis
and tests, and builds the release web app.

After a successful run, open that run in the Actions tab and download the
`bayou-blitz-web-<commit>` artifact. Artifacts are retained for 14 days.
The artifact contains the contents of `build/web`, ready to serve with a
static web server. This workflow builds the app; it does not deploy it.

To run the same checks locally:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web --release
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
