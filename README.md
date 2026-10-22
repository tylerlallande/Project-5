# tailgating

A new way to split responsibilites and cooperate to have the greatest tailgating experience.

## Persistent tailgate server

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

Run Flutter in another terminal:

```sh
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173
```

The app uses `http://127.0.0.1:8080` on desktop/web and
`http://10.0.2.2:8080` on an Android emulator. To point it at a different API,
use `--dart-define=TAILGATE_API_URL=http://your-server:8080` when running or building.
For a physical phone or cloud APK runner, that value must be an HTTPS URL the
device can reach; neither `127.0.0.1` nor `10.0.2.2` points to your Mac there.
The included server is for development and is not a hosted service. For a hosted
deployment, place it behind HTTPS and
set `TAILGATE_ALLOWED_ORIGINS=https://your-app.example` to the exact web origin.

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
