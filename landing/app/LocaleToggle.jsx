"use client";

import { useEffect, useState } from "react";

const storageKey = "ypt_locale";

function applyLocale(locale) {
  document.documentElement.dataset.locale = locale;
  document.documentElement.lang = locale;
  document.querySelectorAll("[data-alt-ko][data-alt-en]").forEach((element) => {
    element.setAttribute("alt", locale === "en" ? element.dataset.altEn : element.dataset.altKo);
  });
  window.dispatchEvent(new CustomEvent("ypt-locale-change", { detail: { locale } }));
}

export default function LocaleToggle() {
  const [locale, setLocale] = useState("ko");

  useEffect(() => {
    let initialLocale = "ko";
    try {
      const savedLocale = localStorage.getItem(storageKey);
      if (savedLocale === "en" || savedLocale === "ko") {
        initialLocale = savedLocale;
      } else {
        const primaryLanguage = (
          navigator.languages && navigator.languages.length
            ? navigator.languages[0]
            : navigator.language || ""
        ).toLowerCase();
        initialLocale = primaryLanguage.startsWith("en") ? "en" : "ko";
      }
    } catch (_) {}
    setLocale(initialLocale);
    applyLocale(initialLocale);
  }, []);

  const nextLocale = locale === "ko" ? "en" : "ko";

  function handleToggle() {
    setLocale(nextLocale);
    applyLocale(nextLocale);
    try {
      localStorage.setItem(storageKey, nextLocale);
    } catch (_) {}
  }

  return (
    <button
      type="button"
      className="localeToggle"
      onClick={handleToggle}
      aria-label={locale === "ko" ? "Switch to English" : "한국어로 전환"}
    >
      {locale === "ko" ? "EN" : "KO"}
    </button>
  );
}
