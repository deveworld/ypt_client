import {
  BarChart3,
  Clock3,
  Monitor,
  PlayCircle,
  ShieldCheck,
  UsersRound
} from "lucide-react";
import DownloadButton from "./DownloadButton";
import LocaleToggle from "./LocaleToggle";

const basePath = process.env.NEXT_PUBLIC_BASE_PATH || "";
const repoUrl = process.env.NEXT_PUBLIC_REPOSITORY_URL || "https://github.com/deveworld/ypt_client";

const text = {
  navFeatures: { en: "Features", ko: "기능" },
  navDemo: { en: "Demo", ko: "데모" },
  navReleases: { en: "Releases", ko: "다운로드" },
  navBuild: { en: "Build", ko: "빌드" },
  navNotice: { en: "Notice", ko: "안내" },
  primaryNavigation: { en: "Primary navigation", ko: "주요 탐색" },
  eyebrowHero: { en: "Unofficial YPT desktop app", ko: "비공식 열품타 데스크톱" },
  heroTitle: { en: "YPT for\nDesktop", ko: "열품타\n데스크톱" },
  heroCopy: {
    en: "Start subject timers, check today's study time, compare rankings, and browse group activity without opening the mobile app.",
    ko: "과목별 타이머를 켜고, 오늘 공부 시간과 랭킹, 그룹 현황을 데스크톱에서 바로 확인하세요."
  },
  openDemo: { en: "Open web demo", ko: "웹에서 보기" },
  visualLabel: { en: "Actual Flutter app screen", ko: "앱 화면 미리보기" },
  visualAlt: {
    en: "YPT Desktop Client timer dashboard",
    ko: "열품타 데스크톱 클라이언트 타이머 대시보드"
  },
  statusLinux: { en: "Desktop release assets", ko: "데스크톱 빌드 제공" },
  statusDemo: { en: "Flutter web demo", ko: "웹 데모 제공" },
  statusJwt: { en: "JWT stored locally", ko: "JWT 로컬 저장" },
  statusRisk: { en: "Undocumented API", ko: "비공식 API 연동" },
  projectStatus: { en: "Project status", ko: "프로젝트 상태" },
  desktopWorkflow: { en: "Core surfaces", ko: "주요 기능" },
  featureHeading: {
    en: "Timer, study stats, and groups stay in one desktop window",
    ko: "공부 타이머와 기록을 데스크톱에서 가볍게 확인하세요"
  },
  implementation: { en: "API boundary", ko: "설계 메모" },
  implementationHeading: {
    en: "Built for an API that can change without warning",
    ko: "API 변화에 대응하기 쉽게 나눴습니다"
  },
  implementationBody: {
    en: "The client separates API calls, response parsing, app state, and screens so undocumented response changes can be fixed near the edge.",
    ko: "API 호출과 응답 처리, 앱 상태, 화면 구성을 분리해 갑작스러운 응답 변경도 작은 범위에서 고칠 수 있게 했습니다."
  },
  runLocally: { en: "Run locally", ko: "직접 실행" },
  buildHeading: {
    en: "Build the desktop app, web demo, or landing page",
    ko: "데스크톱 앱과 웹 데모를 직접 빌드할 수 있습니다"
  },
  flutterClient: { en: "Flutter client", ko: "Flutter 클라이언트" },
  flutterDemo: { en: "Flutter web demo", ko: "Flutter 웹 데모" },
  webLanding: { en: "Web landing", ko: "웹 랜딩" },
  importantNotice: { en: "Important notice", ko: "안내" },
  noticeHeading: {
    en: "Unofficial, personal-account interop only",
    ko: "비공식 개인 프로젝트입니다"
  },
  noticeBody: {
    en: "This project is not affiliated with, sponsored by, or endorsed by YPT or Pallo Inc. It talks to an undocumented API that can change without warning and may conflict with service terms.",
    ko: "YPT 또는 Pallo Inc.와 관련 없는 개인 프로젝트입니다. 문서화되지 않은 API를 사용하므로 언제든 동작이 바뀔 수 있고, 서비스 약관과 맞지 않을 수 있습니다."
  }
};

const features = [
  {
    icon: Clock3,
    title: { en: "Subject timers", ko: "과목 타이머" },
    body: {
      en: "Start and stop study sessions per subject from a desktop-first interface.",
      ko: "과목을 고르고 공부 시간을 시작하거나 멈춥니다."
    }
  },
  {
    icon: BarChart3,
    title: { en: "Daily stats", ko: "오늘 기록" },
    body: {
      en: "Review today's study time, subject totals, and category ranking without opening the mobile app.",
      ko: "오늘 공부 시간, 과목별 누적 시간, 카테고리 랭킹을 한눈에 봅니다."
    }
  },
  {
    icon: UsersRound,
    title: { en: "Group activity", ko: "그룹 현황" },
    body: {
      en: "Browse joined groups and check member study status in a compact desktop view.",
      ko: "참여 중인 그룹과 멤버들의 공부 현황을 빠르게 살펴봅니다."
    }
  }
];

const stack = [
  { en: "Flutter desktop and web targets", ko: "Flutter 데스크톱 / 웹 빌드" },
  { en: "Provider state management", ko: "Provider 상태 관리" },
  { en: "JWT stored locally", ko: "JWT 로컬 저장" },
  { en: "Static Next.js landing page", ko: "정적 Next.js 랜딩" }
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
      <section className="hero">
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
          <div className="navControls">
            <div className="navLinks">
              <a href="#features"><I18n value={text.navFeatures} /></a>
              <a href={demoUrl}><I18n value={text.navDemo} /></a>
              <a href={releasesUrl}><I18n value={text.navReleases} /></a>
              <a href="#build"><I18n value={text.navBuild} /></a>
              <a href="#notice"><I18n value={text.navNotice} /></a>
            </div>
            <LocaleToggle />
          </div>
        </nav>

        <div id="top" className="heroContent">
          <div className="heroText">
            <p className="eyebrow"><I18n value={text.eyebrowHero} /></p>
            <h1><I18n value={text.heroTitle} /></h1>
            <p className="heroCopy"><I18n value={text.heroCopy} /></p>
            <div className="heroActions">
              <DownloadButton repoUrl={normalizedRepoUrl} />
              <a className="button secondary" href={demoUrl}>
                <PlayCircle size={18} />
                <I18n value={text.openDemo} />
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
              alt={text.visualAlt.ko}
              data-alt-en={text.visualAlt.en}
              data-alt-ko={text.visualAlt.ko}
            />
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
