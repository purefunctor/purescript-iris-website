# IRIS website

The website for [IRIS](https://github.com/purefunctor/purescript-iris), a modern functional programming language. Built with Astro, React and PureScript.

## Quickstart

### Prerequisites

You'll need Git, [fnm](https://github.com/Schniz/fnm) for Node.js, [pnpm](https://pnpm.io/installation), and a current stable Rust toolchain to build the native compiler locally. fnm reads the Node version from `.node-version`; pnpm manages its own version using the `packageManager` pin. Building the optional playground separately also requires the `wasm32-unknown-unknown` target and `wasm-bindgen-cli` 0.2.127; see its [toolchain instructions](playground/compiler/API.md#building).

Use Git checkouts of this website and [the IRIS compiler](https://github.com/purefunctor/purescript-iris). Put the compiler at `../repos/purescript-iris`, or set `IRIS_REPOSITORY` to its path. The commands below build the native compiler from that checkout; no separate IRIS installation is needed.

**In an Amp orb:** open Website in the Portal tab. Orb preparation installs the tools and dependencies and builds the development assets; startup reuses those caches and starts the dev server. A fresh preparation takes longer than starting from a cached snapshot. See [the agent guide](AGENTS.md#orb-setup-and-preview) for lifecycle and recovery commands.

### First time

On your machine, run these from the website directory:

```sh
fnm install
fnm use
pnpm install --frozen-lockfile
pnpm dev
```

This builds the native compiler and website components, then starts the dev server. The first build can take a while; later starts reuse caches. A production build is not required for development.

### Start developing

On your machine, run:

```sh
pnpm dev
```

This prepares PureScript output, then starts the compiler watcher and Astro with live updates. You don't need to repeat dependency installation unless dependencies change. For agent-specific orb startup commands, see [the agent guide](AGENTS.md#orb-setup-and-preview).

### Publishing

The site is prerendered at build time and served as [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/) without a Worker script or Node server. Static asset requests have no per-request Worker invocation charge. The playground route is disabled, and its compiler assets are not built or published with the site.

Local builds need `iris` on PATH (or run `pnpm prepare:dev` first to build it from the sibling checkout), plus Node/pnpm. Build and inspect the production output locally:

```sh
pnpm install --frozen-lockfile
pnpm prepare:dev
pnpm build
pnpm preview
```

`pnpm preview` serves `dist/` using Wrangler's local static asset server, including `public/_headers`. Before publishing, confirm that `/` loads, unknown routes return 404, and the response headers match the policy in `_headers`. The Astro CSP in the generated HTML is a meta policy; the separate `frame-ancestors` header protects the landing page from embedding. When restoring the playground, test sandbox headers on canonical, extensionless, and encoded URLs on an actual Cloudflare deployment before enabling the route.

The landing page's installation commands fetch `/install.sh` and `/install.ps1` from this domain. These are reviewed static copies of the compiler repository's installers, currently from [`117ab317268b928dad7c6177a80532c4ab12fb70`](https://github.com/purefunctor/purescript-iris/commit/117ab317268b928dad7c6177a80532c4ab12fb70). When updating them, copy both files from an identified, tested compiler revision, review their changes, and check that the deployed responses match the copies byte-for-byte. Do not fetch moving `main` at build time or redirect these execution URLs to it. The scripts are served as plain text with `nosniff` and no caching; the website's HTTPS delivery and review of script changes are the trust boundary for the initial download. The installers separately download GitHub release archives and verify their attestations when `gh` supports that feature; without it they warn and continue, so release provenance verification is not currently mandatory. To require it, change and test the installers in the compiler repository before syncing these copies.

Pushes to `main` build and deploy through [GitHub Actions](.github/workflows/deploy.yml) using the repository secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. CI installs a SHA-256-pinned Iris release; update its version and digest when publishing compiler changes. To deploy manually after configuring Wrangler (`pnpm exec wrangler login` locally, or a scoped API token in CI), run `pnpm exec wrangler deploy` after the build. Do not commit credentials. Wrangler attaches the `iris-lang.com` Custom Domain on deployment; the token needs Workers Routes Write access to the active Cloudflare zone. Static assets are limited to [25 MiB per file and 20,000 files on Free / 100,000 on Paid](https://developers.cloudflare.com/workers/platform/limits/#static-assets); check the build output before publishing. Avoid adding `assets.run_worker_first` or a Worker script for static content: these can introduce billable invocations. If the playground becomes public, reassess its isolation boundary and traffic separately.

## Playground

The playground implementation and tests remain in the repository, but its public route and generated assets are excluded from the website build. Run `pnpm build:playground` explicitly when working on it; restoring the route requires reviewing its isolation and security policy again.

<a id="execution-boundary"></a>

When enabled, programs run in a sandboxed frame without network access. The compiler worker downloads the pinned PureScript package archives directly from the Registry, verifies their SHA-256 hashes, and caches them in the browser. Package sources are not included in the website build. The separate playground build bundles the compiler and JavaScript runtime as assets.

The playground header shows package-loading progress. The Packages sidebar links to version-specific Pursuit documentation and displays the license and notice files included in each downloaded archive. Archives without those files link to the upstream repository instead.

Repeat visits reuse verified cached archives. Browser storage can be disabled or evicted; a first visit or a cache miss requires Registry access. This is not a fully offline application. Infinite loops can still freeze the browser tab.
