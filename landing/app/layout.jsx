import "./globals.css";

export const metadata = {
  title: "YPT Desktop Client",
  description:
    "An unofficial desktop client for YPT study timers, stats, and group activity. 열품타 비공식 데스크톱 클라이언트."
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" data-locale="en" suppressHydrationWarning>
      <body>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (() => {
                const languages = navigator.languages && navigator.languages.length
                  ? navigator.languages
                  : [navigator.language || "en"];
                const locale = languages.some((language) =>
                  String(language).toLowerCase().startsWith("ko")
                ) ? "ko" : "en";
                document.documentElement.dataset.locale = locale;
                document.documentElement.lang = locale;
              })();
            `
          }}
        />
        {children}
      </body>
    </html>
  );
}
