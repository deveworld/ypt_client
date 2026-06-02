import {
  BarChart3,
  Clock3,
  ExternalLink,
  Monitor,
  ShieldCheck,
  Terminal,
  UsersRound
} from "lucide-react";

const basePath = process.env.NEXT_PUBLIC_BASE_PATH || "";
const repoUrl = process.env.NEXT_PUBLIC_REPOSITORY_URL || "https://github.com";

const features = [
  {
    icon: Clock3,
    title: "Subject timers",
    body: "Start and stop study sessions per subject from a desktop-first interface."
  },
  {
    icon: BarChart3,
    title: "Daily stats",
    body: "Review today's study time, subject totals, and category ranking without opening the mobile app."
  },
  {
    icon: UsersRound,
    title: "Group activity",
    body: "Browse joined groups and check member study status in a compact desktop view."
  }
];

const stack = [
  "Flutter Linux desktop",
  "Provider state management",
  "JWT stored locally",
  "Static Next.js landing page"
];

export default function Page() {
  const heroImage = `${basePath}/hero-dashboard.png`;

  return (
    <main>
      <section
        className="hero"
        style={{ "--hero-image": `url("${heroImage}")` }}
      >
        <nav className="nav" aria-label="Primary">
          <a className="brand" href="#top" aria-label="YPT Desktop Client">
            <span className="brandMark" aria-hidden="true">
              <Clock3 size={18} />
            </span>
            YPT Desktop
          </a>
          <div className="navLinks">
            <a href="#features">Features</a>
            <a href="#build">Build</a>
            <a href="#notice">Notice</a>
          </div>
        </nav>

        <div id="top" className="heroContent">
          <p className="eyebrow">Unofficial interop client</p>
          <h1>YPT Desktop Client</h1>
          <p className="heroCopy">
            열품타 공부 타이머, 오늘의 통계, 그룹 현황을 Linux 데스크톱에서
            확인하고 조작하는 비공식 Flutter 클라이언트입니다.
          </p>
          <div className="heroActions">
            <a className="button primary" href="#build">
              <Terminal size={18} />
              Build locally
            </a>
            <a className="button secondary" href={repoUrl}>
              <ExternalLink size={18} />
              GitHub
            </a>
          </div>
          <div className="statusRail" aria-label="Project status">
            <span>Linux desktop</span>
            <span>Local JWT storage</span>
            <span>Use at your own risk</span>
          </div>
        </div>
      </section>

      <section id="features" className="section">
        <div className="sectionHeader">
          <p className="eyebrow">Desktop workflow</p>
          <h2>Focused timer control without the mobile window</h2>
        </div>
        <div className="featureGrid">
          {features.map(({ icon: Icon, title, body }) => (
            <article className="featureCard" key={title}>
              <Icon size={22} aria-hidden="true" />
              <h3>{title}</h3>
              <p>{body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section split">
        <div>
          <p className="eyebrow">Implementation</p>
          <h2>Small app, clear boundaries</h2>
          <p>
            The desktop client keeps API access, response models, application
            state, and screens separated so the undocumented API surface can be
            adjusted without reshaping the whole app.
          </p>
        </div>
        <div className="stackList">
          {stack.map((item) => (
            <div className="stackItem" key={item}>
              <Monitor size={18} aria-hidden="true" />
              <span>{item}</span>
            </div>
          ))}
        </div>
      </section>

      <section id="build" className="section build">
        <div className="sectionHeader">
          <p className="eyebrow">Run locally</p>
          <h2>Build the desktop app or this landing page</h2>
        </div>
        <div className="commandGrid">
          <article>
            <h3>Flutter client</h3>
            <pre><code>{`flutter pub get
flutter run -d linux
flutter build linux`}</code></pre>
          </article>
          <article>
            <h3>Web landing</h3>
            <pre><code>{`cd web
npm ci
npm run dev
npm run build`}</code></pre>
          </article>
        </div>
      </section>

      <section id="notice" className="section notice">
        <ShieldCheck size={28} aria-hidden="true" />
        <div>
          <p className="eyebrow">Important notice</p>
          <h2>Unofficial, personal-account interop only</h2>
          <p>
            This project is not affiliated with, sponsored by, or endorsed by
            YPT or Pallo Inc. It talks to an undocumented API that can change
            without warning and may conflict with service terms.
          </p>
        </div>
      </section>
    </main>
  );
}
