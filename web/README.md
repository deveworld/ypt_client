# YPT Desktop Web Landing

Static Next.js landing page for the unofficial YPT Desktop Client.

## Run

```bash
npm ci
npm run dev
```

## Build

```bash
npm run build
```

The build exports static files to `out/`. The repository workflow deploys that
folder to GitHub Pages when files under `web/` change on `main`.

## Hero Asset

`public/hero-dashboard.png` is rendered from `tools/hero-render.html` so the
landing page shows an app-like screen that matches the Flutter desktop UI
instead of a generic generated dashboard.
