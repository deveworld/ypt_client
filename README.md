# YPT Desktop Client (비공식)

> 열품타(YPT) PC 데스크톱 클라이언트 — **비공식** interop 클라이언트.
> An **unofficial** desktop client for the YPT (열품타) study-timer app.

본인 계정의 공부 타이머·통계·그룹 현황을 데스크톱에서 확인하고 조작하기 위한
Flutter 데스크톱 앱입니다. YPT의 공개 모바일 앱이 사용하는 동일한 HTTPS API
(`pi.tgclab.com`)와 통신합니다.

A Flutter desktop app to run your study timer and view your stats / group
activity from a PC. It talks to the same public HTTPS API (`pi.tgclab.com`)
that the official YPT mobile app uses.

---

## ⚠️ 고지 / Disclaimer

- 이 프로젝트는 **비공식**이며, YPT 및 운영사(Pallo Inc.)와 **아무런 제휴·후원·승인 관계가 없습니다.**
  "열품타", "YPT" 및 관련 상표는 각 권리자의 자산입니다.
- **본인 계정 interop 용도**로만 의도되었습니다. 타인 계정 조작, 자동화 악용,
  공부시간 조작 등은 의도된 사용이 아닙니다.
- 비공식 API를 사용하므로 **예고 없이 동작하지 않을 수 있고**, 서비스 약관(ToS)에
  저촉될 수 있습니다. **모든 사용 책임은 사용자 본인에게 있습니다 (use at your own risk).**
- 자격증명/토큰은 외부로 전송하지 않으며, 로그인 JWT는 로컬 `shared_preferences`에만 저장됩니다.

<sub>This is an **unofficial** project, **not affiliated with, sponsored by, or
endorsed by** YPT or Pallo Inc. Trademarks belong to their respective owners.
Intended for **interoperating with your own account only**. It relies on an
undocumented API that may break at any time and may conflict with the service's
Terms of Service — **use at your own risk.** Credentials are never sent
anywhere except the YPT API; the login JWT is stored only in local
`shared_preferences`.</sub>

---

## 기능 / Features

- 🔑 이메일 로그인 + 자동 로그인 (JWT 로컬 저장) / Email sign-in with auto-login
- ⏱️ 과목별 공부 타이머 시작·정지 / Per-subject study timer (start/stop)
- 📊 오늘 공부시간·카테고리 랭킹 / Daily study time & category ranking
- 👥 내 그룹 목록 + 그룹 멤버 실시간 현황 / My groups & live member activity
- 🌙 다크 테마 (YPT 브랜드 컬러) / Dark theme

## 기술 스택 / Stack

Flutter (Dart 3.3+) · `provider` 상태관리 · `http` · `shared_preferences` · `intl`

## 빌드 & 실행 / Build & Run

> 현재 **Linux 데스크톱**만 구성되어 있습니다. / Only the **Linux desktop**
> target is configured at the moment.

```bash
# 사전 요구: Flutter SDK (stable), Linux 데스크톱 빌드 의존성 (GTK 등)
# Prereqs: Flutter SDK (stable) + Linux desktop build deps (GTK, etc.)
flutter doctor

flutter pub get
flutter run -d linux        # 개발 실행 / dev run
flutter build linux         # 릴리스 빌드 / release build
```

빌드 산출물: `build/linux/x64/release/bundle/` 안의 `ypt_client` 실행 파일.
The built binary lives at `build/linux/x64/release/bundle/ypt_client`.

## 사용법 / Usage

1. 앱 실행 후 YPT 계정 **이메일/비밀번호로 로그인**합니다.
2. 홈에서 과목을 선택해 타이머를 시작/정지하고, 통계·그룹 탭에서 현황을 확인합니다.

1. Launch the app and **sign in** with your YPT account email/password.
2. Pick a subject to start/stop the timer; check the Stats / Groups tabs.

## 프로젝트 구조 / Layout

```
lib/
├─ main.dart            # 앱 진입점·테마 / entry point & theme
├─ app_state.dart       # Provider 상태관리 / app state (auth, timer, data)
├─ ypt_api.dart         # YPT API 클라이언트 / API client
├─ models.dart          # 응답 모델 / response models
└─ screens/             # 로그인·홈·타이머·통계·그룹 화면 / UI screens
```

## 라이선스 / License

[MIT](LICENSE)
