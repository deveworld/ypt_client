import "./globals.css";

export const metadata = {
  title: "YPT Desktop Client",
  description:
    "An unofficial desktop client for YPT study timers, stats, and group activity."
};

export default function RootLayout({ children }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
