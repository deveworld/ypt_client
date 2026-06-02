# YPT Desktop Client

> Unofficial desktop client and web landing page for YPT / 열품타.

YPT Desktop Client는 본인 계정의 공부 타이머, 오늘의 통계, 그룹 현황을
Linux 데스크톱에서 확인하고 조작하기 위한 Flutter 앱입니다. YPT 모바일 앱이
사용하는 공개 HTTPS API(`pi.tgclab.com`)와 직접 통신합니다.

![YPT Desktop landing hero](web/public/hero-dashboard.png)

## Important Notice

- 이 프로젝트는 **비공식**이며 YPT, Pallo Inc. 또는 관련 권리자와 제휴,
  후원, 승인 관계가 없습니다.
- 본인 계정 interop 용도로만 의도되었습니다. 타인 계정 조작, 자동화 악용,
  공부시간 조작은 의도된 사용이 아닙니다.
- 문서화되지 않은 API를 사용하므로 예고 없이 동작하지 않을 수 있고, 서비스
  약관에 저촉될 수 있습니다. 모든 사용 책임은 사용자 본인에게 있습니다.
- 이메일/비밀번호는 YPT API 로그인 요청에만 사용됩니다. 로그인 JWT는 로컬
  `shared_preferences`에 저장됩니다.

## Features

- Email sign-in with local JWT auto-login
- Per-subject study timer start and stop
- Daily study time and subject breakdown
- Category ranking view
- Joined/browsable groups and group member activity
- Dark desktop UI with YPT-inspired orange-red accents

## Project Layout

```text
lib/
  main.dart                 Flutter entry point and theme
  app_state.dart            Provider state for auth, timer, stats, groups
  ypt_api.dart              YPT API client
  models.dart               API response models
  screens/                  Login, home, timer, stats, group screens

linux/                      Flutter Linux desktop target
macos/                      Flutter macOS desktop target
windows/                    Flutter Windows desktop target
web/                        Flutter web demo target
landing/                    Next.js static landing page
.github/workflows/          GitHub Pages and release build workflows
```

## Desktop Build

The Flutter app is configured for Linux, Windows, and macOS desktop. Flutter
desktop builds should be produced on the matching host OS; local development on
Linux can build the Linux target directly.

```bash
flutter doctor
flutter pub get
flutter run -d linux
```

Linux release build:

```bash
flutter build linux
```

The release executable is generated under:

```text
build/linux/x64/release/bundle/ypt_client
```

## Desktop Release Assets

`.github/workflows/release-desktop.yml` builds prebuilt desktop release assets
for:

- Linux x64 (`.tar.gz`)
- Windows x64 (`.zip`)
- macOS x64 (`.zip`)

Run the workflow manually with an existing release tag such as `v0.1.2`. Each
job uploads the packaged app and a `.sha256` checksum file to that GitHub
Release.

The release build runs on OS-specific GitHub Actions runners. Flutter desktop
does not support producing Windows or macOS desktop apps from a Linux host with
only an extra compiler installed.

## Web Landing Page

The landing page lives in `landing/` and is built as a static Next.js export.
The Flutter web demo uses the root Flutter app's `web/` target and is mounted
under `/demo/` during the GitHub Pages build.

```bash
cd landing
npm ci
npm run dev
```

Static build:

```bash
npm run build
```

The exported site is written to `landing/out/`.

Flutter web demo build:

```bash
flutter build web --release --base-href /demo/
```

## GitHub Pages Deployment

`.github/workflows/deploy-web.yml` deploys the web landing page to GitHub Pages
when files under `landing/`, `web/`, `lib/`, or Flutter dependency manifests
change on the `main` branch. The workflow also runs on manual
`workflow_dispatch`.

Before first deployment, configure the repository Pages source to **GitHub
Actions** in GitHub repository settings. For project Pages repositories, the
workflow automatically builds with the repository name as the Next.js base path
and mounts the Flutter web demo at `/demo/`. For `*.github.io` repositories,
it builds at the domain root.

## Development Notes

- Keep API behavior isolated in `lib/ypt_api.dart`; the YPT API is
  undocumented and may change.
- Keep response parsing defensive. The API uses compact keys and may return
  numeric fields as different JSON primitive types.
- Run `flutter analyze` before shipping Flutter changes when the Flutter SDK is
  available.
- Run `npm run build` inside `landing/` before shipping landing page changes.
- Run `flutter build web --release --base-href /demo/` before shipping web demo
  changes when the Flutter SDK is available.

## License

[MIT](LICENSE)
