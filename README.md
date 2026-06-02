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
web/                        Next.js static landing page
.github/workflows/          GitHub Pages deployment workflow
```

## Desktop Build

The Flutter app is currently configured for Linux desktop.

```bash
flutter doctor
flutter pub get
flutter run -d linux
```

Release build:

```bash
flutter build linux
```

The release executable is generated under:

```text
build/linux/x64/release/bundle/ypt_client
```

## Web Landing Page

The landing page lives in `web/` and is built as a static Next.js export.

```bash
cd web
npm ci
npm run dev
```

Static build:

```bash
npm run build
```

The exported site is written to `web/out/`.

## GitHub Pages Deployment

`.github/workflows/deploy-web.yml` deploys the web landing page to GitHub Pages
when files under `web/` change on the `main` branch. The workflow also runs on
manual `workflow_dispatch`.

Before first deployment, configure the repository Pages source to **GitHub
Actions** in GitHub repository settings. For project Pages repositories, the
workflow automatically builds with the repository name as the Next.js base path.
For `*.github.io` repositories, it builds at the domain root.

## Development Notes

- Keep API behavior isolated in `lib/ypt_api.dart`; the YPT API is
  undocumented and may change.
- Keep response parsing defensive. The API uses compact keys and may return
  numeric fields as different JSON primitive types.
- Run `flutter analyze` before shipping Flutter changes when the Flutter SDK is
  available.
- Run `npm run build` inside `web/` before shipping landing page changes.

## License

[MIT](LICENSE)
