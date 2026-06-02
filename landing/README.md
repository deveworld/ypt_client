# YPT Desktop Landing

Static Next.js landing page for the unofficial YPT Desktop Client.

The page automatically switches visible copy between English and Korean based
on the browser language list. Korean is used when any browser language starts
with `ko`; otherwise English is shown.

## Run

```bash
npm ci
npm run dev
```

## Build

```bash
npm run build
```

The build exports static files to `out/`.

The repository workflow builds the Flutter web demo from the root project and
copies it into `landing/out/demo/`, then deploys `landing/out` to GitHub Pages.

## Hero Asset

`public/hero-dashboard.png` is rendered from `tools/hero-render.html` so the
landing page shows an app-like screen that matches the Flutter desktop UI
instead of a generic generated dashboard.
