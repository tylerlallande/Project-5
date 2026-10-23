# Tgate

Ugh, as if! Where is everyone? That’s where Tgate comes in. Tgate is an interactive app that helps you meet up with friends, family, and others at a set location—making tailgating more enjoyable and less like you’re in The Maze Runner in real life.

Project lead | Abdul Mutaal

Flutter UI developer | Tyler Lallande

Backend Developer | David Zhong

QA lead | Brandon Avila

## Persistent tailgate server

### Run locally

Run the API in one terminal (Python 3.10 or newer, no extra packages). The
explicit host makes it reachable from an Android emulator as well as desktop:

```sh
python server/server.py --host 0.0.0.0
```

To populate the game picker and live score alerts, keep a College Football Data
API key on the server:

```sh
CFBD_API_KEY=your_server_side_key python server/server.py --host 0.0.0.0
```

Never pass this key through `--dart-define` or commit it to the Flutter app.
Weather forecasts come through the server from Open-Meteo and need no API key.

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
docker build -t tgate-api .
docker run --name tgate-api -p 8080:8080 \
  -e ALLOWED_ORIGINS=https://tailgates.example.com \
  -v tgate-data:/data tgate-api
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

The app uses `http://127.0.0.1:8080` on desktop/web and
`http://10.0.2.2:8080` on an Android emulator. To point it at a different API,
use `--dart-define=TAILGATE_API_URL=https://api.example.com` when running or building.
For a physical phone or cloud APK runner, that value must be an HTTPS URL the
device can reach; neither `127.0.0.1` nor `10.0.2.2` points to your Mac there.
Local HTTP browser origins remain allowed for development; hosted browser origins
must be listed in the API's `ALLOWED_ORIGINS`. Android emulators can use
`http://10.0.2.2:8080` for a local development server where networking and the
app's HTTP policy allow it.

Tailgates, invite codes, memberships, waitlists, join requests, reports, blocks,
photo recap links, and anonymous device sessions are stored in
`server/data/tailgates.sqlite3` (ignored by Git). Back up that database; deleting it
deletes the saved data. The server starts empty, with no demo memberships.
The device's anonymous session token is stored in app/browser preferences, so
refreshing, signing out, or restarting the API does not remove memberships.
Different browsers/devices get different guest identities. Clearing app/browser
storage loses access to that identity. Guest display names are saved locally, and
a guest can upgrade the profile without losing memberships or claimed items.

Hosts join their tailgate when creating it. Public tailgates are discoverable;
private tailgates require an invite code. Hosts can set capacity, require join
approval, complete or archive an event, and delete completed events. Full events
place guests on a waitlist and promote the next guest when space opens. If a host
leaves while members remain,
the server transfers hosting to a remaining member. The last member must confirm
permanent deletion. Membership removal and deletion happen in one SQLite
transaction, including rechecking whether the member is now the last person.
Deleted tailgates and their invite codes cannot be rejoined.

Use Refresh in the Tailgates tab to see changes made by another device. The app
caches the latest tailgate list and game schedule for read-only offline use.
Device-local notifications provide one-hour tailgate reminders after permission
is granted. Live score, kickoff-change, and weather alerts refresh while the app
is connected. Production push delivery while the app is fully closed requires a
hosted worker plus APNs/FCM credentials.

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
`tgate-web-<commit>` artifact. Artifacts are retained for 14 days.
The artifact contains the contents of `build/web`, ready to serve with a
static web server. This workflow builds the app; it does not deploy it.

To run the same checks locally:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web --release
```

## QA and testing

### Automated tests

Run both suites before opening or merging a pull request:

```sh
python -m unittest discover -s server -v   # backend (17 tests)
flutter test                               # Flutter app (32 tests)
```

CI runs `flutter analyze`, `flutter test`, and a release web build on every push
and pull request. Don't merge a PR with a failing check.

### Manual smoke test

Run the server and the web app locally (see above), then check:

1. Create a public tailgate. The host is joined automatically.
2. In a second browser, find the tailgate and join it. Tap Refresh on the
   first browser and confirm the new member shows up.
3. Create a private tailgate and join it using only the invite code.
4. Add items to the bring list, claim one from the other browser, and confirm
   the claim persists after a refresh.
5. Set a capacity of 1, join from a second browser, and confirm the guest lands
   on the waitlist.
6. Have the host leave while members remain and confirm hosting transfers.
7. Leave as the last member and confirm the app asks before deleting.
8. Open the Map tab and confirm the meetup spot loads.

### Reporting a bug

Open a GitHub issue with the steps to reproduce, what you expected, what
happened, and the browser or device you used.
