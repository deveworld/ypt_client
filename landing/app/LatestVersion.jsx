"use client";

import { useEffect, useState } from "react";

// GitHub API 로 최신 릴리스 태그를 가져와 표시 (정적 export라 클라이언트 fetch).
export default function LatestVersion({ repoUrl }) {
  const [version, setVersion] = useState("");

  useEffect(() => {
    const m = repoUrl.match(/github\.com\/([^/]+)\/([^/]+)/);
    if (!m) return;
    let alive = true;
    fetch(`https://api.github.com/repos/${m[1]}/${m[2]}/releases/latest`)
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        if (alive && d && d.tag_name) setVersion(d.tag_name);
      })
      .catch(() => {});
    return () => {
      alive = false;
    };
  }, [repoUrl]);

  return <span>{version || "latest"}</span>;
}
