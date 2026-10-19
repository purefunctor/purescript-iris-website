# Agent guide

The repository contains the Iris website, iris-lang.com. Astro prerenders every page to static files, which Cloudflare serves as static assets. The site's React components are written in PureScript and compiled with Iris.

The site presents Iris to new users, so its claims must match the compiler. Its pages should also load and switch quickly, and its design follows the direction in [Design constraints](#design-constraints).

AGENTS.md records the project's intent and the constraints that are easy to break. Read the code for how things work. Areas with their own rules keep an `AGENTS.md` beside their code, and the sections below link to them.

## Sources of truth

- Treat `purefunctor/purescript-iris` as the source of truth for compiler behaviour, architecture, compatibility and performance claims. In Amp, read the checkout at `../repos/purescript-iris`. If it is unavailable, use Librarian to research that repository instead of inferring from website code.
- Check a claim in product copy before you weaken it. Evaluate build speed claims with the release compiler against an official `purs` release, using the [build benchmark](#build-benchmarks), and report compiler time separately from Spago and Vite overhead. `purs` cannot compile this website, because it uses Iris StyleX.
- References to existing PureScript libraries and projects describe Iris's compatibility testing against the PureScript Registry package set. The compiler repository's `tests-compatibility` crate and its CI workflows define the current scope and evidence.

## Project structure

All first-party PureScript lives in the `Website` namespace, with matching paths in `src/Website`. Shared UI belongs in `Website.Components`, and page-specific modules belong in `Website.Landing` or `Website.Documentation`. Keep each FFI companion, in `.js` or `.jsx`, beside its PureScript module. Astro pages in `src/pages` render a module's `component` as an island inside `SiteLayout` or `DocumentationLayout`.

- Documentation pages, including how readers switch between them, follow [`src/Website/Documentation/AGENTS.md`](src/Website/Documentation/AGENTS.md).
- The playground's language server, which only playground work builds, and its Registry packages follow [`playground/AGENTS.md`](playground/AGENTS.md).
- The landing page's editor trailer is recorded and rendered by `scripts/editor-demos`. Read [`scripts/editor-demos/AGENTS.md`](scripts/editor-demos/AGENTS.md) before you change the take, the trailer, or the code that the take reads and edits in `Website.Landing.Index`, `Website.Landing.Demos`, `Website.Landing.Benchmarks` and `Website.Components.CopyButton`.

## Code conventions

### Imports and dependencies

- Use the package import aliases `#src/*` and `#output/*` for imports across directories. They are defined in `package.json` and resolve in both Node and Vite. Mirror `#output/*` in `tsconfig.json` so that Astro also resolves client hydration URLs in development.
- Iris copies FFI companions into `output`, so a companion that imports a colocated JavaScript helper must use `#src/Website/...` rather than a relative path.
- Import `react-aria-components` by component subpath, such as `react-aria-components/Button`, and never from the package root. The root barrel prebundles the whole library, about 2 MB, into every development page.
- List every dependency that generated modules import, including each `react-aria-components` subpath, in `optimizeDeps.include` in `astro.config.mjs`. Vite's first dependency scan cannot see all generated PureScript, and a dependency it misses reloads the page on first navigation.

### Styles

- Write component styles in PureScript with `Iris.StyleX`. Iris emits StyleX calls that the Vite plugin can analyze, so styling needs no JavaScript FFI. Before you change styles, read `iris skills get stylex` and the upstream authoring and installation guides that it links for the installed StyleX version.
- Keep a component's styles inline in its module. Move styles into a colocated module, such as `Website.Components.IconButton.Styles`, only when several consumers share them. Use `StyleX.recordProps` instead of a separate `StyleX.props` binding for each style, and keep `StyleX.props` for compositions and conditional styles.
- Nest media queries and pseudo-classes inside property values with explicit defaults, and prefer longhands or single-value shorthands. Keep static styles in StyleX rather than in FFI DOM style assignments. Dynamic styles return inline CSS variables, so they must not be server-rendered under the site's CSP.
- Define shared viewport queries with `StyleX.defineConsts` in `Website.Breakpoints`, and use them through `StyleX.conditionalValue` and `StyleX.conditionalCase`. Preserve their exact bounds when refactoring. Preference queries, such as reduced motion, are not viewport breakpoints. `Website.SiteLayout` supplies the document's responsive styles.

### Component exports

- Name a module's single, directly consumable `ReactComponent` export `component`, and use it through the qualified module name, such as `Index.component`. Astro pages and JavaScript consumers rely on this module boundary.
- Give an effectful `Component props` constructor, which callers instantiate while constructing their own component, a descriptive name such as `header`.
- When a module exports several `ReactComponent` values and none of them is the module's main component, give each one a descriptive name instead of `component`.

### Static output and the CSP

- Production is a static Astro build served by Cloudflare Workers Static Assets without a Worker script, so no code runs per request. Every page and endpoint exports `prerender = true`. The [README](README.md#publishing) explains the hosting limits.
- Static Assets answer Range requests with the whole file, so browsers cannot seek media streamed from it, and Safari does not play it. `Website.Components.VideoPlayer` plays an in-memory copy fetched on demand; development serves ranges, so verify seeking in the [production preview](#production-preview).
- `public/_headers` owns the static security and cache headers. Astro adds the CSP from `security.csp` in `astro.config.mjs` to each page as a meta tag.
- Documentation pages use Astro's client router, which Astro documents as unsupported with `security.csp`. It works here because every page emits the same script and style hashes, and the first page's CSP stays in force after a swap. Do not add page-specific inline scripts or styles to documentation pages, and verify router changes in the [production preview](#production-preview), because development does not enforce the CSP.

## Design constraints

Apply design feedback to what it names. When it points to an existing treatment, inspect that treatment and match it rather than changing the reference. Do not carry a correction over to other components or states, and drop superseded ideas when the direction changes.

### Visual direction and composition

- Treat 2000s web and graphic design as the primary visual direction, rebuilt with contemporary responsiveness and accessibility. Lean into expressive asymmetry, compressed editorial lockups, stark contrast, hard flat color, and controlled tension rather than merely quoting the period through nostalgic effects.
- Use whitespace, negative space, and sharp, corner-led composition to separate large content regions. "Edgy" means angular, hard-edged geometry, not literal borders around sections. Keep large blocks square and avoid enclosing every section in a rounded card.

### Headings

- Avoid eyebrow or overline text for page and section headings.
- Eyebrow text is appropriate inside contained components, such as cards, when it acts as the component's label or title.

### Controls and status

- Reserve full rounding for focused interactive elements such as calls to action and status pills.
- Give transparent actions a subtle background fill so they remain identifiable beside prose, then strengthen that fill on hover. Do not add a persistent border.
- Set status pills in the sans-serif typeface with high-contrast colors. Add a border only when a light treatment needs separation from its background.
- Use macOS cursor semantics on every platform. Controls such as buttons, toggles, tabs and button-styled links use the regular arrow cursor, and only text-styled links use the pointing-hand cursor. Do not detect the platform for cursors, and keep communicating interactivity through shape, contrast, hover and focus treatments.

### Color tokens

- Define shared color tokens in `src/global.css` using OKLCH, then reference those tokens from StyleX declarations. Create related states by varying OKLCH lightness or chroma while preserving hue instead of introducing disconnected hex values.

## Development

See the [README](README.md) for prerequisites and the standard commands.

### Working on the site

- `pnpm dev` compiles the site's PureScript with `pnpm prepare:dev`, then runs `iris watch` and Astro with live updates. Both processes stop if either exits.
- Use the running development server for feature work and visual checks. Do not run `pnpm build` for UI iterations or as a default completion check.
- After editing PureScript, ask the running watcher instead of starting another compiler. Run `iris watch query wait`, then `iris watch query diagnostics`. `iris skills get watch` describes the other queries, such as signatures, references and generated JavaScript.
- Format PureScript with `iris format`, and check it with `iris format --check`. Keep workspace-wide formatting separate from refactoring commits.

### Orb setup and preview

- In an orb, `.agents/resume` starts the `website` service from `.amp/services.yaml`, which runs `pnpm dev` behind the Website and Documentation portals. Inspect it with `amp orb service status website` or `amp orb service logs website`, and restart it after configuration changes with `amp orb service restart website`. Never commit orb-specific URLs, such as the portal URLs in the gitignored `.amp/portals/`.
- `.agents/setup` and the deploy workflow both install the latest stable Iris release with the reviewed `public/install.sh`. Do not pin either installation to a release version. Setup skips GitHub attestation verification with `IRIS_SKIP_ATTESTATION=1`, and `.github/workflows/deploy.yml` requires it.
- Setup prepares development inputs only, so do not build production Astro output or start a persistent server there. Snapshots contain the installed compiler and PureScript output, so a cached orb keeps its compiler until setup runs again.
- `pnpm prepare:dev` relies on Iris's incremental cache. Do not add a preparation fingerprint, a success stamp, or a Vite warmup script.
- To recover an orb whose setup did not finish, run these from the website root before starting the service. Rerun the locked install after changing dependencies, and do not install dependencies from resume.

  ```sh
  pnpm install --frozen-lockfile
  pnpm prepare:dev
  amp orb services ensure
  ```

### Development server performance

Development page loads are bounded by portal round trips, not rendering. [`devLibraryBundle`](src/lib/devLibraryBundle.ts) serves all Registry library output as one client module, and [`devModulePreload`](src/lib/devModulePreload.ts) preloads each page's whole static module graph, so the browser fetches a page in about one round trip. Keep these guardrails when you change the Astro or Vite configuration:

- Do not add Vite `server.warmup`. StyleX loads optimized dependencies while transforming, which deadlocks the initial dependency crawl on a cold cache.
- Keep the development and production Vite caches separate, so that a build never replaces the prebundles of a running server.
- Keep Iris's `index.js.map` files chained through every development transform so that browser stack frames show `.purs` locations. A transform that changes code must return a real map or `map: null`, never `{ mappings: "" }`, which drops the chain. `@stylexjs/unplugin` requests no source map from Babel, so `astro.config.mjs` passes a Babel preset that enables `sourceMaps`. Frames in library code point into `virtual:iris-library` by design.
- Keep Astro's dev toolbar disabled. It adds about 1.3 MB of client modules to every page.

## Verification

Choose checks by what the change affects.

- For visual changes, use the running Website portal, and capture and inspect representative mobile and desktop viewports together. Do not write bespoke browser test scripts for transient design choices, and reserve new automated checks for durable behaviour.
- For generated assets, `_headers`, the CSP, the documentation router or video seeking, use the [production preview](#production-preview).
- For the Vite configuration and the development plugins, run the [development cache](#development-cache) check.
- For build speed claims, run the [build benchmark](#build-benchmarks).

### Production preview

Development runs Astro on Node.js, while production serves static assets, so check production-only behaviour in a production build. Wrangler's static asset server applies `public/_headers`, which `astro preview` does not:

```sh
pnpm build
amp orb service start website-production --command 'pnpm preview' --port 8787 --portal --title 'Website (Production)'
```

Stop it afterwards with `amp orb service stop website-production`. Do not start it for every feature or add it to the automatically started services.

### Development cache

With agent-browser installed and a dev server running, the following check runs a production build next to the dev server, then confirms that the build kept the dev server's prebundles and that the landing page still hydrates without reoptimization:

```sh
node scripts/test-dev-cache.mjs http://localhost:4321
```

### Build benchmarks

The landing page's build times come from [`scripts/benchmark-builds.ts`](scripts/benchmark-builds.ts), whose header explains what it measures. It needs Bun, Spago and network access for the first setup. Pass an official `purs` release, not a locally modified build, and the Iris release being described:

```sh
bun scripts/benchmark-builds.ts --purs node_modules/purescript/purs.bin --iris "$(command -v iris)"
```

Update the figures, versions and bar widths in `src/Website/Landing/Benchmarks.purs` from its output.

## Maintaining agent guidance

- Record intent and constraints, with the reason when it is not obvious. Do not restate how code works; link to the file instead.
- Put each rule in its owning section, and update it when the practice changes. Keep commands with their prerequisites, and link to detailed contracts rather than copying them.
- Keep guidance for a self-contained area or tool in an `AGENTS.md` beside it, as [`src/Website/Documentation/AGENTS.md`](src/Website/Documentation/AGENTS.md) and [`scripts/editor-demos/AGENTS.md`](scripts/editor-demos/AGENTS.md) do, and link it from the owning section here.
- Keep `README.md` focused on the project overview, setup, usage and documented limitations, and link to guidance rather than duplicating it.
