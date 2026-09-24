# Agent guide

This repository is the Iris website: Astro handles routing and server rendering on Node.js; React components are implemented in PureScript and compiled with Iris.

## Sources of truth

- Treat `purefunctor/purescript-iris` as the source of truth for compiler behaviour, architecture, compatibility, and performance claims. In Amp, inspect the additional checkout at `../repos/purescript-iris`; if it is unavailable, use Librarian to research that repository instead of inferring from website-local code.
- Substantiate product copy before weakening it. Benchmark this website with the release compiler when evaluating build-speed claims, and separate compiler time from Spago and Vite overhead.
- References to existing PureScript libraries and projects describe Iris's compatibility testing against the PureScript Registry package set. Consult `tests-compatibility` and its CI workflows in the compiler repository for the current scope and evidence.

## Implementation conventions

### Routing

- Astro server-renders routes by default. Add `export const prerender = true` to an Astro page when it can be generated as a static asset instead.

### PureScript and JavaScript boundaries

- Keep all first-party PureScript modules under `Website`, with matching paths in `src/Website`. Shared UI belongs in `Website.Components`; page-specific modules belong in `Website.Landing` or `Website.Playground`. Keep FFI companions alongside their PureScript modules.
- Use the package import aliases `#src/*`, `#output/*`, `#build/*` and `#playground/*` for cross-directory imports. FFI companions are copied into `output`, so imports of colocated JavaScript helpers must use `#src/Website/...` rather than paths relative to either the source or output directory. The aliases are defined in `package.json` and resolve in both Node and Vite. Mirror `#output/*` in `tsconfig.json` so Astro also resolves client hydration URLs in development.
- Keep playground UI and React hooks in `src/Website/Playground/Index.purs` and `src/Website/Playground/Result.purs`. Their JavaScript FFI companions implement browser effects: Monaco and compiler workers, focus, runtime loading and sandbox messaging. PureScript hooks own state and cleanup.
- Playground dialog animations use only `motion/mini` through `dialog.js`. PureScript owns visibility and controller lifetime; browser controllers own interruption, native modal closing and focus. Cancel backdrop effects explicitly (Mini's `stop()` does not), restore owned inline styles, and keep trivial CSS transitions and React Aria presence unchanged.
- Author component StyleX declarations in PureScript using `Iris.StyleX`. Iris emits statically analyzable StyleX calls for the Vite plugin; JavaScript FFI is not required for styling.
- Keep component-local styles inline. Extract styles into colocated modules when shared by multiple consumers, such as `Website.Components.Header.Styles`. Use `StyleX.recordProps` instead of repetitive individual `StyleX.props` bindings; retain `StyleX.props` for compositions and conditional styles.

### Component exports

- Name a module's single, directly consumable `ReactComponent` export `component`, and consume it through the qualified module name, such as `Index.component`. This fluent module style is the intended boundary for Astro and JavaScript consumers.
- Use a descriptive component name, such as `header`, for an effectful `Component props` constructor that callers must instantiate during component construction.
- When a module exports multiple peer `ReactComponent` values and none is the canonical module component, give each value a descriptive name rather than using `component`.

### Playground security

- Before adding network access, persistence, sharing or arbitrary npm dependencies, revisit the playground isolation policy described in [README.md](README.md#execution-boundary). The absence of accounts does not remove XSS risk; hostile public execution warrants a separate origin and stronger resource isolation.
- Production is a static Astro build deployed as Cloudflare Workers Static Assets without a Worker script. `public/_headers` owns the static security and cache headers. When restoring the playground sandbox, verify its policy on canonical, extensionless, and encoded URLs on Cloudflare before enabling the route.

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

### Orb setup and preview

- `.agents/setup` uses fnm for the Node version in `.node-version` and bootstraps standalone pnpm, which manages the version pinned in `package.json`. Their environment is persisted for login shells without manually linking tool binaries. Setup also installs stable Rust, locked dependencies, and runs `pnpm prepare:dev`. Snapshots contain the native compiler and PureScript output. Do not build production Astro output or start a persistent server during setup.
- `pnpm prepare:dev` builds the native compiler through `.amp/with-iris`, then prepares PureScript. The playground build is separate and does not run during site development or publishing. Use the build tools' incremental caches; there is no separate preparation fingerprint, success stamp, or Vite warmup script.
- `.amp/with-iris` builds the native release compiler from `IRIS_REPOSITORY` (default: the additional checkout at `../repos/purescript-iris`) and puts it on PATH for the supplied command. Cargo and Iris reuse existing build caches. If memory is constrained, set `CARGO_BUILD_JOBS=2` rather than assuming a default job limit.
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
amp orb service start production-preview --command 'pnpm preview' --portal
```

## Verification

### Visual changes

- When visually reviewing a change with screenshots, capture and inspect representative mobile and desktop viewports so responsive regressions are considered together.

### Playground checks

The public playground route and assets are excluded from the website build. The browser checks that target `/playground` apply after its Astro page, sandbox asset, and playground build are restored; the non-browser checks require the separate playground toolchain.

```sh
pnpm test:playground
node scripts/build-playground-wasm.mjs --test-native
node scripts/build-playground-packages.mjs --fixture
PLAYGROUND_PACKAGES="$PWD/build/playground-packages.json" node scripts/build-playground-wasm.mjs --test-wasm
# Requires installed agent-browser; starts and closes its own React/WAAPI fixture server:
node scripts/test-dialog-animations-browser.mjs
# Requires installed agent-browser and a running dev/preview server:
node scripts/test-playground-browser.mjs http://localhost:4321/playground
# Requires installed agent-browser and a running dev server; builds production
# concurrently and checks that both routes still hydrate without reoptimization:
node scripts/test-dev-cache.mjs http://localhost:4321
# Requires a production preview (pnpm build, then pnpm preview) for HTTP cache checks:
node scripts/test-playground-packages-browser.mjs http://localhost:4321/playground
```

## Maintaining this guide

- Keep agent-facing implementation conventions, verification commands and orb workflows in `AGENTS.md`, and update them when those practices change. Keep `README.md` focused on the project overview, setup, usage and documented limitations; link to guidance rather than duplicating it.
- Put each rule in its owning section. Keep commands with their prerequisites, and link to detailed contracts rather than copying them into this guide.
