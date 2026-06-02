import {
  BarChart3,
  Clock3,
  Download,
  ExternalLink,
  Monitor,
  PlayCircle,
  ShieldCheck,
  Terminal,
  UsersRound
} from "lucide-react";

const basePath = process.env.NEXT_PUBLIC_BASE_PATH || "";
const repoUrl = process.env.NEXT_PUBLIC_REPOSITORY_URL || "https://github.com/deveworld/ypt_client";

const text = {
  navFeatures: { en: "Features", ko: "기능" },
  navDemo: { en: "Demo", ko: "데모" },
  navReleases: { en: "Releases", ko: "릴리스" },
  navBuild: { en: "Build", ko: "빌드" },
  navNotice: { en: "Notice", ko: "고지" },
  primaryNavigation: { en: "Primary navigation", ko: "주요 탐색" },
  eyebrowHero: { en: "Unofficial YPT desktop app", ko: "비공식 열품타 데스크톱 앱" },
  heroTitle: { en: "YPT for\nDesktop", ko: "열품타\n데스크톱" },
  heroCopy: {
    en: "Start subject timers, check today's study time, compare rankings, and browse group activity without opening the mobile app.",
    ko: "모바일 앱을 열지 않고 과목별 타이머를 시작하고, 오늘 공부시간과 랭킹, 그룹 현황을 확인합니다."
  },
  downloadBuilds: { en: "Download builds", ko: "빌드 다운로드" },
  openDemo: { en: "Open web demo", ko: "웹 데모 실행" },
  buildFromSource: { en: "Build from source", ko: "소스에서 빌드" },
  visualLabel: { en: "Actual Flutter app screen", ko: "실제 Flutter 앱 화면" },
  visualFooter: { en: "Timer / stats / groups", ko: "타이머 / 통계 / 그룹" },
  statusLinux: { en: "Desktop release assets", ko: "데스크톱 릴리스 파일" },
  statusDemo: { en: "Flutter web demo", ko: "Flutter 웹 데모" },
  statusJwt: { en: "JWT stored locally", ko: "JWT 로컬 저장" },
  statusRisk: { en: "Undocumented API", ko: "문서화되지 않은 API" },
  projectStatus: { en: "Project status", ko: "프로젝트 상태" },
  desktopWorkflow: { en: "Core surfaces", ko: "핵심 화면" },
  featureHeading: {
    en: "Timer, study stats, and groups stay in one desktop window",
    ko: "타이머, 공부 통계, 그룹 현황을 한 데스크톱 창에 모았습니다"
  },
  implementation: { en: "API boundary", ko: "API 경계" },
  implementationHeading: {
    en: "Built for an API that can change without warning",
    ko: "예고 없이 바뀔 수 있는 API를 전제로 구성"
  },
  implementationBody: {
    en: "The client separates API calls, response parsing, app state, and screens so undocumented response changes can be fixed near the edge.",
    ko: "API 호출, 응답 파싱, 앱 상태, 화면을 분리해 문서화되지 않은 응답 변경을 경계 부근에서 고칠 수 있게 했습니다."
  },
  runLocally: { en: "Run locally", ko: "로컬 실행" },
  buildHeading: {
    en: "Build the desktop app, web demo, or landing page",
    ko: "데스크톱 앱, 웹 데모, 랜딩 페이지 빌드"
  },
  flutterClient: { en: "Flutter client", ko: "Flutter 클라이언트" },
  flutterDemo: { en: "Flutter web demo", ko: "Flutter 웹 데모" },
  webLanding: { en: "Web landing", ko: "웹 랜딩" },
  importantNotice: { en: "Important notice", ko: "중요 고지" },
  noticeHeading: {
    en: "Unofficial, personal-account interop only",
    ko: "비공식, 본인 계정 연동 전용"
  },
  noticeBody: {
    en: "This project is not affiliated with, sponsored by, or endorsed by YPT or Pallo Inc. It talks to an undocumented API that can change without warning and may conflict with service terms.",
    ko: "이 프로젝트는 YPT 또는 Pallo Inc.와 제휴, 후원, 승인 관계가 없습니다. 문서화되지 않은 API와 통신하므로 예고 없이 동작하지 않을 수 있고 서비스 약관과 충돌할 수 있습니다."
  }
};

const features = [
  {
    icon: Clock3,
    title: { en: "Subject timers", ko: "과목별 타이머" },
    body: {
      en: "Start and stop study sessions per subject from a desktop-first interface.",
      ko: "데스크톱에 맞춘 화면에서 과목별 공부 세션을 시작하고 정지합니다."
    }
  },
  {
    icon: BarChart3,
    title: { en: "Daily stats", ko: "오늘 통계" },
    body: {
      en: "Review today's study time, subject totals, and category ranking without opening the mobile app.",
      ko: "모바일 앱을 열지 않고 오늘 공부시간, 과목별 누적 시간, 카테고리 랭킹을 확인합니다."
    }
  },
  {
    icon: UsersRound,
    title: { en: "Group activity", ko: "그룹 현황" },
    body: {
      en: "Browse joined groups and check member study status in a compact desktop view.",
      ko: "내 그룹과 둘러보기 그룹을 확인하고 멤버 공부 현황을 한 화면에서 봅니다."
    }
  }
];

const stack = [
  { en: "Flutter desktop and web targets", ko: "Flutter 데스크톱 및 웹 타깃" },
  { en: "Provider state management", ko: "Provider 상태 관리" },
  { en: "JWT stored locally", ko: "JWT 로컬 저장" },
  { en: "Static Next.js landing page", ko: "정적 Next.js 랜딩 페이지" }
];

function I18n({ value }) {
  return (
    <>
      <span className="i18n i18n-en">{value.en}</span>
      <span className="i18n i18n-ko">{value.ko}</span>
    </>
  );
}

export default function Page() {
  const heroImage = `${basePath}/hero-dashboard.png`;
  const demoUrl = `${basePath}/demo/`;
  const normalizedRepoUrl = repoUrl.replace(/\/$/, "");
  const releasesUrl = `${normalizedRepoUrl}/releases`;

  return (
    <main>
      <section
        className="hero"
        style={{ "--hero-image": `url("${heroImage}")` }}
      >
        <nav className="nav" aria-labelledby="primary-nav-label">
          <span id="primary-nav-label" className="srOnly">
            <I18n value={text.primaryNavigation} />
          </span>
          <a className="brand" href="#top" aria-label="YPT Desktop Client">
            <span className="brandMark" aria-hidden="true">
              <Clock3 size={18} />
            </span>
            YPT Desktop
          </a>
          <div className="navLinks">
            <a href="#features"><I18n value={text.navFeatures} /></a>
            <a href={demoUrl}><I18n value={text.navDemo} /></a>
            <a href={releasesUrl}><I18n value={text.navReleases} /></a>
            <a href="#build"><I18n value={text.navBuild} /></a>
            <a href="#notice"><I18n value={text.navNotice} /></a>
          </div>
        </nav>

        <div id="top" className="heroContent">
          <div className="heroText">
            <p className="eyebrow"><I18n value={text.eyebrowHero} /></p>
            <h1><I18n value={text.heroTitle} /></h1>
            <p className="heroCopy"><I18n value={text.heroCopy} /></p>
            <div className="heroActions">
              <a className="button primary" href={releasesUrl}>
                <Download size={18} />
                <I18n value={text.downloadBuilds} />
              </a>
              <a className="button secondary" href={demoUrl}>
                <PlayCircle size={18} />
                <I18n value={text.openDemo} />
              </a>
              <a className="button secondary" href="#build">
                <Terminal size={18} />
                <I18n value={text.buildFromSource} />
              </a>
              <a className="button secondary" href={repoUrl}>
                <ExternalLink size={18} />
                GitHub
              </a>
            </div>
          </div>
          <div className="heroVisual">
            <div className="visualHeader">
              <span><I18n value={text.visualLabel} /></span>
              <span>v0.1.2</span>
            </div>
            <img
              className="heroScreenshot"
              src={heroImage}
              alt="YPT Desktop Client timer dashboard"
            />
            <div className="visualFooter">
              <span><I18n value={text.visualFooter} /></span>
              <span>Flutter</span>
            </div>
          </div>
        </div>
        <div className="heroMeta">
          <div className="statusRail">
            <span className="srOnly"><I18n value={text.projectStatus} /></span>
            <span><I18n value={text.statusLinux} /></span>
            <span><I18n value={text.statusDemo} /></span>
            <span><I18n value={text.statusJwt} /></span>
            <span><I18n value={text.statusRisk} /></span>
          </div>
        </div>
      </section>

      <section id="features" className="section">
        <div className="sectionHeader">
          <p className="eyebrow"><I18n value={text.desktopWorkflow} /></p>
          <h2><I18n value={text.featureHeading} /></h2>
        </div>
        <div className="featureGrid">
          {features.map(({ icon: Icon, title, body }, index) => (
            <article className="featureCard" key={title.en}>
              <span className="featureIndex">{String(index + 1).padStart(2, "0")}</span>
              <Icon size={24} aria-hidden="true" />
              <div>
                <h3><I18n value={title} /></h3>
                <p><I18n value={body} /></p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="section split">
        <div>
          <p className="eyebrow"><I18n value={text.implementation} /></p>
          <h2><I18n value={text.implementationHeading} /></h2>
          <p><I18n value={text.implementationBody} /></p>
        </div>
        <div className="stackList">
          {stack.map((item) => (
            <div className="stackItem" key={item.en}>
              <Monitor size={18} aria-hidden="true" />
              <span><I18n value={item} /></span>
            </div>
          ))}
        </div>
      </section>

      <section id="build" className="section build">
        <div className="sectionHeader">
          <p className="eyebrow"><I18n value={text.runLocally} /></p>
          <h2><I18n value={text.buildHeading} /></h2>
        </div>
        <div className="commandGrid">
          <article>
            <h3><I18n value={text.flutterClient} /></h3>
            <pre><code>{`flutter pub get
flutter run -d linux
flutter build linux`}</code></pre>
          </article>
          <article>
            <h3><I18n value={text.flutterDemo} /></h3>
            <pre><code>{`flutter pub get
flutter build web --release --base-href /demo/`}</code></pre>
          </article>
          <article>
            <h3><I18n value={text.webLanding} /></h3>
            <pre><code>{`cd landing
npm ci
npm run dev
npm run build`}</code></pre>
          </article>
        </div>
      </section>

      <section id="notice" className="section notice">
        <ShieldCheck size={28} aria-hidden="true" />
        <div>
          <p className="eyebrow"><I18n value={text.importantNotice} /></p>
          <h2><I18n value={text.noticeHeading} /></h2>
          <p><I18n value={text.noticeBody} /></p>
        </div>
      </section>
    </main>
  );
}
