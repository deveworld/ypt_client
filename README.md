# YPT Desktop Client

Unofficial Flutter desktop client, Flutter web demo, and Next.js landing page
for YPT / 열품타.

![YPT Desktop Client landing hero](landing/public/hero-dashboard.png)

## Important Notice

- This project is **unofficial** and is not affiliated with, sponsored by, or
  endorsed by YPT, Pallo Inc., or related rights holders.
- It is intended only for personal-account interop. It is not intended for
  manipulating another account, automation abuse, or study-time fabrication.
- The client talks to YPT's undocumented HTTPS API at `pi.tgclab.com`.
  Behavior can break without warning and may conflict with service terms.
- Email and password are used for the YPT login request. The login JWT is stored
  locally through `shared_preferences`.
- Also, I used Codex (GPT 5.5) for the document part, and got some advice from Claude AI on APK reverse engineering.

## What It Does

YPT Desktop Client lets you use core YPT study flows from a desktop-shaped
interface:

- Email login with local JWT auto-login
- Per-subject study timer start and stop
- Daily study time, subject totals, and category ranking
- Joined groups, browsable groups, and group member activity
- Flutter desktop build targets for Linux, Windows, and macOS
- Flutter web build mounted under the landing page at `/demo/`

## Download From GitHub Releases

Prebuilt desktop assets are attached to
[GitHub Releases](https://github.com/deveworld/ypt_client/releases):

- Linux x64 `.tar.gz` plus `.sha256`
- Windows x64 `.zip` plus `.sha256`
- macOS x64 `.zip` plus `.sha256`

These are packaged Flutter build outputs. The current workflow does not sign or
notarize installers.

## Build From Source

Run a Linux desktop development build:

```bash
flutter doctor
flutter pub get
flutter run -d linux
```

Build a Linux release locally:

```bash
flutter build linux --release
```

The Linux executable bundle is generated under:

```text
build/linux/x64/release/bundle/
```

Desktop builds should be produced on the matching host OS. For cross-platform
release assets, use the GitHub Actions workflow described below.

## Web Demo And Landing

The project has two web surfaces:

- `web/`: Flutter web target for the app demo
- `landing/`: static Next.js landing page

Run the landing page locally:

```bash
cd landing
npm ci
npm run dev
```

Build the static landing page:

```bash
cd landing
npm run build
```

Build the Flutter web demo manually:

```bash
flutter pub get
flutter build web --release --base-href /demo/
```

The GitHub Pages workflow builds both surfaces, copies `build/web/` into
`landing/out/demo/`, and deploys `landing/out`.

## GitHub Actions

### Pages Deploy

`.github/workflows/deploy-web.yml` runs on `main` when these areas change:

- `landing/**`
- `web/**`
- `lib/**`
- `pubspec.yaml`
- `pubspec.lock`
- the deploy workflow itself

The workflow builds `landing/` as a static Next.js export, builds the Flutter
web demo from the root `web/` target, copies `build/web/` into
`landing/out/demo/`, and deploys `landing/out/`.

For project Pages repositories, the workflow uses `/<repo>` as the Next.js base
path and `/<repo>/demo/` as the Flutter web base href. For `*.github.io`
repositories, it uses the domain root and `/demo/`.

### Prebuilt Desktop Release Assets

`.github/workflows/release-desktop.yml` is a manual `workflow_dispatch`
workflow. Give it an existing GitHub Release tag, and it builds/uploads:

- Linux x64 `.tar.gz` plus `.sha256`
- Windows x64 `.zip` plus `.sha256`
- macOS x64 `.zip` plus `.sha256`

The workflow uses OS-specific GitHub-hosted runners. Flutter desktop does not
support building Windows and macOS desktop apps from a Linux host just by
installing another compiler toolchain.

## Project Layout

```text
lib/                       Flutter app source
  app_state.dart           Provider state for auth, timer, stats, groups
  ypt_api.dart             YPT API client
  models.dart              API response models
  screens/                 Login, home, timer, stats, group screens

linux/                     Flutter Linux desktop target
macos/                     Flutter macOS desktop target
windows/                   Flutter Windows desktop target
web/                       Flutter web demo target
landing/                   Next.js static landing page
.github/workflows/         Pages deploy and desktop release workflows
```

## Development Checklist

- Keep undocumented API behavior isolated in `lib/ypt_api.dart`.
- Keep response parsing defensive; the API may change field names or value
  types.
- Run `flutter analyze` before shipping Flutter changes when the Flutter SDK is
  available.
- Run `npm run build` inside `landing/` before shipping landing page changes.
- Run `flutter build web --release --base-href /demo/` before shipping web demo
  changes.

## License

[MIT](LICENSE)
