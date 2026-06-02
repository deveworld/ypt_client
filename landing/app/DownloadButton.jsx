"use client";

import { useEffect, useMemo, useState } from "react";
import { Download } from "lucide-react";

const releaseTag = "v0.1.2";

const targets = {
  windows: {
    asset: "ypt_client-windows-x64-v0.1.2.zip",
    label: { en: "Download for Windows", ko: "Windows 다운로드" }
  },
  macos: {
    asset: "ypt_client-macos-x64-v0.1.2.zip",
    label: { en: "Download for macOS", ko: "macOS 다운로드" }
  },
  linux: {
    asset: "ypt_client-linux-x64-v0.1.2.tar.gz",
    label: { en: "Download for Linux", ko: "Linux 다운로드" }
  },
  unknown: {
    asset: null,
    label: { en: "Choose download", ko: "다운로드 선택" }
  }
};

function detectPlatform() {
  const userAgentDataPlatform = navigator.userAgentData?.platform || "";
  const value = `${userAgentDataPlatform} ${navigator.platform || ""} ${navigator.userAgent || ""}`.toLowerCase();

  if (value.includes("win")) return "windows";
  if (value.includes("mac")) return "macos";
  if (value.includes("linux") || value.includes("x11")) return "linux";
  return "unknown";
}

export default function DownloadButton({ repoUrl }) {
  const [platform, setPlatform] = useState("unknown");
  const [locale, setLocale] = useState("ko");
  const normalizedRepoUrl = repoUrl.replace(/\/$/, "");

  useEffect(() => {
    setPlatform(detectPlatform());
    setLocale(document.documentElement.dataset.locale === "en" ? "en" : "ko");

    function handleLocaleChange(event) {
      setLocale(event.detail?.locale === "en" ? "en" : "ko");
    }

    window.addEventListener("ypt-locale-change", handleLocaleChange);
    return () => window.removeEventListener("ypt-locale-change", handleLocaleChange);
  }, []);

  const target = targets[platform] || targets.unknown;
  const href = useMemo(() => {
    if (!target.asset) return `${normalizedRepoUrl}/releases`;
    return `${normalizedRepoUrl}/releases/download/${releaseTag}/${target.asset}`;
  }, [normalizedRepoUrl, target.asset]);

  const label = target.label[locale];

  return (
    <a
      className="button primary"
      href={href}
      aria-label={label}
    >
      <Download size={18} />
      {label}
    </a>
  );
}
