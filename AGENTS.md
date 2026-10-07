# Agent guide

This repository is the Iris website: Astro handles routing and server rendering on Node.js; React components are implemented in PureScript and compiled with Iris.

## Sources of truth

- Treat `purefunctor/purescript-iris` as the source of truth for compiler behaviour, architecture, compatibility, and performance claims. In Amp, inspect the additional checkout at `../repos/purescript-iris`; if it is unavailable, use Librarian to research that repository instead of inferring from website-local code.
- Substantiate product copy before weakening it. Evaluate build-speed claims with the release compiler against an official `purs` release, using the [build benchmark](#build-benchmarks); this website cannot be compiled by `purs` because it uses Iris StyleX. Separate compiler time from Spago and Vite overhead.
- References to existing PureScript libraries and projects describe Iris's compatibility testing against the PureScript Registry package set. Consult `tests-compatibility` and its CI workflows in the compiler repository for the current scope and evidence.

## Implementation conventions

### Routing

- Astro server-renders routes by default. Add `export const prerender = true` to an Astro page when it can be generated as a static asset instead.

### PureScript and JavaScript boundaries

- Keep all first-party PureScript modules under `Website`, with matching paths in `src/Website`. Shared UI belongs in `Website.Components`; page-specific modules belong in `Website.Landing`. Keep FFI companions alongside their PureScript modules.
- Use the package import aliases `#src/*` and `#output/*` for cross-directory imports. FFI companions are copied into `output`, so imports of colocated JavaScript helpers must use `#src/Website/...` rather than paths relative to either the source or output directory. The aliases are defined in `package.json` and resolve in both Node and Vite. Mirror `#output/*` in `tsconfig.json` so Astro also resolves client hydration URLs in development.
- Author component StyleX declarations in PureScript using `Iris.StyleX`. Iris emits statically analyzable StyleX calls for the Vite plugin; JavaScript FFI is not required for styling.
- Keep component-local styles inline. Extract styles into colocated modules when shared by multiple consumers, such as `Website.Components.IconButton.Styles`. Use `StyleX.recordProps` instead of repetitive individual `StyleX.props` bindings; retain `StyleX.props` for compositions and conditional styles.
- Before changing StyleX, read `iris skills get stylex` and the upstream authoring and installation guides it links for the installed StyleX version. Nest media queries and pseudo-classes inside property values with explicit defaults, and prefer longhands or single-value shorthands. Keep static styles in StyleX rather than FFI DOM style assignments. Dynamic styles return inline CSS variables and must not be server-rendered under the site's current CSP.
- Define shared viewport queries with `StyleX.defineConsts` in `Website.Breakpoints` and consume them through `StyleX.conditionalValue` / `StyleX.conditionalCase`. Preserve exact bounds when refactoring; preference queries are not viewport breakpoints. The Vite StyleX plugin treats Iris's `index.js` output as theme files so cross-module constants resolve at build time. `Website.SiteLayout` supplies the document's responsive styles to Astro.

### Component exports

- Name a module's single, directly consumable `ReactComponent` export `component`, and consume it through the qualified module name, such as `Index.component`. This fluent module style is the intended boundary for Astro and JavaScript consumers.
- Use a descriptive component name, such as `header`, for an effectful `Component props` constructor that callers must instantiate during component construction.
- When a module exports multiple peer `ReactComponent` values and none is the canonical module component, give each value a descriptive name rather than using `component`.

### Deployment

- Production is a static Astro build deployed as Cloudflare Workers Static Assets without a Worker script. `public/_headers` owns the static security and cache headers.

## Design constraints

### Visual direction and composition

- Treat 2000s web and graphic design as the primary visual direction, rebuilt with contemporary responsiveness and accessibility. Lean into expressive asymmetry, compressed editorial lockups, stark contrast, hard flat color, and controlled tension rather than merely quoting the period through nostalgic effects.
- Use whitespace, negative space, and sharp, corner-led composition to separate large content regions. "Edgy" means angular, hard-edged geometry—not literal borders around sections. Keep large blocks square and avoid enclosing every section in a rounded card.

### Headings

- Avoid eyebrow or overline text for page and section headings.
- Eyebrow text is appropriate inside contained components, such as cards, when it acts as the component's label or title.

### Controls and status

- Reserve full rounding for focused interactive elements such as calls to action and status pills.
- Give transparent actions a subtle background fill so they remain identifiable beside prose, then strengthen that fill on hover. Do not add a persistent border.
- Set status pills in the sans-serif typeface with high-contrast colors. Add a border only when a light treatment needs separation from its background.
- Preserve macOS cursor semantics by using the regular arrow cursor for controls such as buttons and toggles on macOS. Button-styled navigation links also use the regular arrow cursor on every platform; inline text hyperlinks use the pointing-hand cursor. Continue to communicate interactivity through shape, contrast, hover, and focus treatments.

### Color tokens

- Define shared color tokens in `src/global.css` using OKLCH, then reference those tokens from StyleX declarations. Create related states by varying OKLCH lightness or chroma while preserving hue instead of introducing disconnected hex values.

## Local workflow

See [README.md](README.md) for installation prerequisites and standard development commands.

Use `iris format` to format the workspace's PureScript sources and `iris format --check` to verify them. Keep workspace-wide formatting separate from refactoring commits.

### Orb setup and preview

- `.agents/setup` uses fnm for the Node version in `.node-version` and bootstraps standalone pnpm, which manages the version pinned in `package.json`. It installs Iris 0.1.4 with the release-tagged official installer and `IRIS_SKIP_ATTESTATION=1`, then installs locked dependencies and runs `pnpm prepare:dev`. Keep its Iris version aligned with the SHA-256-pinned release in `.github/workflows/deploy.yml`. The tool paths are persisted for login shells. Snapshots contain the installed compiler and PureScript output. Do not build production Astro output or start a persistent server during setup.
- `pnpm prepare:dev` compiles the site's PureScript with the installed `iris` on PATH. Use Iris's incremental cache; there is no separate preparation fingerprint, success stamp, or Vite warmup script.
- `.agents/resume` runs `amp orb services ensure`. The declared `website` service checks the development inputs before starting the compiler watcher and Astro, and checks `/` before reporting ready. It generates the Website link in the gitignored `.amp/portals/website.json`; never commit orb-specific URLs.
- To recover an orb whose setup did not finish, run these from the website root before starting the service:

```sh
pnpm install --frozen-lockfile
pnpm prepare:dev
amp orb services ensure
```

- Share the returned portal URL, not localhost. Inspect with `amp orb service status website` or `amp orb service logs website`; stop with `amp orb service stop website`. Rerun locked dependency installation after changing dependencies; do not install them from resume.
- `pnpm dev` runs `prepare:dev` before starting the compiler watcher and Astro with live updates. Both processes stop if either exits. Keep dependencies discovered through generated modules in Astro's Vite prebundle list to avoid reloads on first navigation. Keep production/sync and development Vite caches separate: a build must not replace prebundles used by the running server. Restart after service configuration changes with:

```sh
amp orb service restart website
```

- Development uses Astro on Node.js; production is served as static assets. Validate production behavior with Wrangler's static asset server, not just Astro dev (`astro preview` does not exercise Cloudflare's `_headers` rules):

```sh
pnpm build
amp orb service start production-preview --command 'pnpm preview' --port 8787 --portal
```

### Editor demo recordings

`scripts/editor-demos/` reproduces the native VS Code workflow from the [original recording thread](https://ampcode.com/threads/T-01a0cf38-55ca-765a-a413-2e7de30fe101). It seeds a disposable `iris-website` workspace from this checkout's `src`, `spago.yaml`, and `spago.lock`, using its installed dependencies and Iris on PATH. Never perform recording edits in the website checkout itself.

The Linux recording environment needs `agent-browser`, FFmpeg, curl, unzip, fontconfig, Xvfb, Openbox, xdotool and the native Electron libraries. On Debian:

```sh
sudo apt-get install -y xvfb openbox xdotool bibata-cursor-theme \
  libnss3 libxss1 libasound2 libgtk-3-0 libgbm1 libxkbfile1 libsecret-1-0 xauth
bash scripts/editor-demos/setup.sh
amp orb service start iris-demo-code --command 'bash scripts/editor-demos/launch.sh'
agent-browser --session iriscode --cdp 9223 press F11
node scripts/editor-demos/record.mjs all
```

- Setup pins VS Code 1.139.0, Iris extension 0.1.0, PureScript syntax extension 0.2.10, Catppuccin 3.19.0 and Geist 1.7.2. The current takes use Iris 0.1.3. It selects Catppuccin Macchiato, Geist for the workbench and Geist Mono for code, and enables opt-in on-change diagnostics.
- Capture is native 1920×1080 at 60 fps with the real pointer, encoded as H.264/yuv420p MP4 with fast start and no audio. Electron's scale factor is 150% by default; this scales the whole application, not just the editor font. Use VS Code's F11 fullscreen, not the window manager's fullscreen, to avoid window borders. Do not apply browser viewport emulation to the Electron session.
- The export runs at 75% of captured speed and adds a one-second final-frame hold: `setpts=(PTS-STARTPTS)/0.75,fps=60,tpad=stop_mode=clone:stop_duration=1`. Apply this once to a normal-speed take, never to an already slowed export.
- For a quick 200% comparison, stop the service and start it with `--command 'IRIS_DEMO_SCALE=200 bash scripts/editor-demos/launch.sh'`, enter F11 fullscreen again, then run `IRIS_DEMO_OUTPUT=/tmp/iris-editor-tools/recordings-200 node scripts/editor-demos/record.mjs inferred-types`. Return to the default launch command for production takes. Text targets are resolved from the live DOM at either scale.
- `record.mjs` accepts one or more clip slugs instead of `all`. It asserts actual editor results before exporting each take. Source locations follow the current seed; update the scenarios when those components move. Setup and capture use `/tmp/iris-editor-tools` by default (`IRIS_DEMO_HOME` can override it). Setup resets only that disposable workspace and profile; stop VS Code before rerunning setup.
- Review all exported MP4s in `/tmp/iris-editor-tools/recordings`, then copy them to `public/editor-demos/`. Refresh the first poster with `ffmpeg -y -ss 3.5 -i public/editor-demos/inferred-types.mp4 -frames:v 1 -c:v libwebp -quality 85 public/editor-demos/inferred-types.webp`. Check each video's dimensions, frame rate and decode with ffprobe/FFmpeg, and inspect playback on the landing page at desktop and mobile widths. Keep raw takes and diagnostic snapshots out of Git.

## Verification

### Visual changes

- When visually reviewing a change with screenshots, capture and inspect representative mobile and desktop viewports so responsive regressions are considered together.

### Build benchmarks

The landing page's build times come from `scripts/benchmark-builds.ts`, which needs Bun, Spago and network access for the first setup. It creates acme, a project depending on every package in a pinned Registry package set, then compares `spago build`, `purs compile` and `iris build`, plus `iris watch` rebuilds. Pass an official `purs` release, not a locally modified build, and the Iris release being described:

```sh
bun scripts/benchmark-builds.ts --purs node_modules/purescript/purs.bin --iris "$(command -v iris)"
```

Update the figures, versions and bar widths in `src/Website/Landing/Benchmarks.purs` from its output.

### Development cache

Production builds must not replace the prebundles of a running dev server. With agent-browser installed and a dev server running, this builds production concurrently and checks that the landing page still hydrates without reoptimization:

```sh
node scripts/test-dev-cache.mjs http://localhost:4321
```

## Maintaining this guide

- Keep agent-facing implementation conventions, verification commands and orb workflows in `AGENTS.md`, and update them when those practices change. Keep `README.md` focused on the project overview, setup, usage and documented limitations; link to guidance rather than duplicating it.
- Put each rule in its owning section. Keep commands with their prerequisites, and link to detailed contracts rather than copying them into this guide.
