import "./globals.css";

export const metadata = {
  title: "YPT Desktop Client",
  description:
    "An unofficial desktop client for YPT study timers, stats, and group activity. 열품타 비공식 데스크톱 클라이언트."
};

export default function RootLayout({ children }) {
  return (
    <html lang="ko" data-locale="ko" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (() => {
                let locale = "ko";
                try {
                  const savedLocale = localStorage.getItem("ypt_locale");
                  if (savedLocale === "en" || savedLocale === "ko") {
                    locale = savedLocale;
                  } else {
                    const primaryLanguage = (
                      navigator.languages && navigator.languages.length
                        ? navigator.languages[0]
                        : navigator.language || ""
                    ).toLowerCase();
                    locale = primaryLanguage.startsWith("en") ? "en" : "ko";
                  }
                } catch (_) {}
                document.documentElement.dataset.locale = locale;
                document.documentElement.lang = locale;
                const applyLocalizedAttributes = () => {
                  document.querySelectorAll("[data-alt-ko][data-alt-en]").forEach((element) => {
                    element.setAttribute("alt", locale === "en" ? element.dataset.altEn : element.dataset.altKo);
                  });
                };
                if (document.readyState === "loading") {
                  document.addEventListener("DOMContentLoaded", applyLocalizedAttributes, { once: true });
                } else {
                  applyLocalizedAttributes();
                }
              })();
            `
          }}
        />
      </head>
      <body>
        {children}
      </body>
    </html>
  );
}
