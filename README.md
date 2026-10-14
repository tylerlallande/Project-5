# tailgating

A new way to split responsibilites and cooperate to have the greatest tailgating experience.

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
