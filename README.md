# IRIS website

The website for [IRIS](https://github.com/purefunctor/purescript-iris), a modern functional programming language. Built with Astro, React and PureScript.

The documentation starts at `/docs/getting-started` (`/docs` redirects there), which covers installing Iris and running a Node.js Hello World application. Further pages document installer options, the language server, and formatting; the compiler README links to them. Pages use the shared documentation shell, installation tabs, and code blocks.

## Quickstart

### Prerequisites

You'll need Git, [fnm](https://github.com/Schniz/fnm) for Node.js, [pnpm](https://pnpm.io/installation), and Iris 0.1.5 on PATH. fnm reads the Node version from `.node-version`; pnpm manages its own version using the `packageManager` pin. `.agents/setup` bootstraps these tools and installs Iris 0.1.5 using the [official installer](https://iris-lang.com/docs/installation), with GitHub attestation checks explicitly skipped.

**In an Amp orb:** open Website in the Portal tab. Orb preparation installs the tools and dependencies and builds the development assets; startup reuses those caches and starts the dev server. A fresh preparation takes longer than starting from a cached snapshot. See [the agent guide](AGENTS.md#orb-setup-and-preview) for lifecycle and recovery commands.

### First time

On Linux or macOS, run these from the website directory:

```sh
.agents/setup
```

Setup installs Iris 0.1.5 and prepares website components. Open a new Bash login shell to pick up the installed tools, then run `pnpm dev` to start the dev server. Later starts reuse caches. A production build is not required for development.

### Start developing

On your machine, run:

```sh
pnpm dev
```

This prepares PureScript output, then starts the compiler watcher and Astro with live updates. You don't need to repeat dependency installation unless dependencies change. For agent-specific orb startup commands, see [the agent guide](AGENTS.md#orb-setup-and-preview).

### Publishing

The site is prerendered at build time and served as [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/) without a Worker script or Node server. Static asset requests have no per-request Worker invocation charge.

Pages use `src/layouts/SiteLayout.astro` for canonical, OpenGraph, and Twitter metadata. Set `title` and `description` on each page; pass `image` (a root-relative 1200 × 630 image URL) and `imageAlt` to override the default social image. The default `/og.png` is prerendered by `src/pages/og.png.ts` using Satori and Sharp. It centres the site icon and a Geist Black wordmark over the still frame of the hero's dot field, without the hero's clearing, with colors read from the OKLCH tokens in `src/global.css`. For a distinct image on another page, add a prerendered PNG endpoint and pass its URL to the layout. The favicon (`/favicon.svg`) and Apple touch icon (`/apple-touch-icon.png`) are prerendered from `src/lib/favicon.ts` in the same way. No image-rendering service runs in production.

Generate the compiler repository's 1200 × 320 README banner from the same renderer with `node scripts/render-readme-banner.mjs /path/to/iris-readme-banner.webp`, run from this website's root after installing dependencies. It renders the dot field at banner dimensions and exports lossless WebP; no running server or production build is needed. The compiler README uses the asset at `.github/assets/iris-readme-banner.webp`.

Local builds need the installed `iris` on PATH, plus Node/pnpm. Build and inspect the production output locally:

```sh
pnpm install --frozen-lockfile
pnpm prepare:dev
pnpm build
pnpm preview
```

`pnpm preview` serves `dist/` using Wrangler's local static asset server, including `public/_headers`. Before publishing, confirm that `/` loads, unknown routes return 404, and the response headers match the policy in `_headers`. The Astro CSP in the generated HTML is a meta policy; the separate `frame-ancestors` header protects the landing page from embedding.

The landing page and documentation's installation commands fetch `/install.sh` and `/install.ps1` from this domain. These are reviewed static copies of the compiler repository's installers, currently from [`1c41ef272468466ac0bd5fd84d6ffff93444a0d4`](https://github.com/purefunctor/purescript-iris/commit/1c41ef272468466ac0bd5fd84d6ffff93444a0d4). When updating them, copy both files from an identified, tested compiler revision, review their changes, and check that the deployed responses match the copies byte-for-byte. Do not fetch moving `main` at build time or redirect these execution URLs to it. The scripts are served as plain text with `nosniff` and no caching; the website's HTTPS delivery and review of script changes are the trust boundary for the initial download. The installers separately download GitHub release archives and verify their attestations when `gh` supports that feature; without it they warn and continue, so release provenance verification is not currently mandatory. Set `IRIS_SKIP_ATTESTATION=1` (or `$env:IRIS_SKIP_ATTESTATION = "1"` in PowerShell) to skip verification explicitly, with a warning. To require verification, change and test the installers in the compiler repository before syncing these copies.

Pushes to `main` build and deploy through [GitHub Actions](.github/workflows/deploy.yml) using the repository secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. CI installs a SHA-256-pinned Iris release; update its version and digest when publishing compiler changes. To deploy manually after configuring Wrangler (`pnpm exec wrangler login` locally, or a scoped API token in CI), run `pnpm exec wrangler deploy` after the build. Do not commit credentials. Wrangler attaches the `iris-lang.com` Custom Domain on deployment; the token needs Workers Routes Write access to the active Cloudflare zone. Static assets are limited to [25 MiB per file and 20,000 files on Free / 100,000 on Paid](https://developers.cloudflare.com/workers/platform/limits/#static-assets); check the build output before publishing. Avoid adding `assets.run_worker_first` or a Worker script for static content: these can introduce billable invocations.
