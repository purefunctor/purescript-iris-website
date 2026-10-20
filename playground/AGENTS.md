# Playground

The `/playground` page edits multi-file Iris projects in Monaco, with a language server built from the compiler's own crates and the whole Registry package set. These directories hold the parts that are not PureScript UI.

## Layers

The UI in `src/Website/Playground` stays a plain renderer: it draws the state that `client/playground.js` publishes and calls its actions, and never sees Monaco, LSP or the worker. Keep editor, protocol and package logic in the client, behind that state.

- `client/playground.js` is the controller. It owns the project, the editor, the language client and the runner, and creates the editor only once the packages and the server are ready, so the page shows a loading screen until then.
- `client/worker.js` hosts the server in a Web Worker and downloads the package set. `client/language-client.js` is its page side, which restarts the worker when the server panics.
- `client/mock-server.js` speaks the same protocol in JavaScript. The worker uses it when `public/playground/language-server` holds no server, and `?server=mock` forces it, so UI work never needs Rust or a download.
- `client/monaco.js` imports Monaco's features one module at a time. `astro.config.mjs` prebundles every `monaco-editor/...` import it lists, and `src/lib/monacoStyles.ts` keeps Monaco's CSS out of the site's shared stylesheet, so add new features to that list rather than importing Monaco elsewhere. Monaco assumes the browser's default box model, which `client/monaco.css` restores under the site's border-box reset; keep Monaco overrides in that file.
- `client/runner.js` and `public/playground/sandbox.html` run emitted JavaScript in a sandboxed frame without network access. Programs cannot import npm packages, except React, which the Registry's React bindings need, and `@stylexjs/stylex`, which Iris.StyleX compiles to: `src/pages/playground/modules.json.ts` bundles the site's own copies, and the runner fetches them only when a program imports one and passes them to the frame with the program's modules, so the frame's policy stays closed. A program that imports StyleX also loads the StyleX Babel plugin on `@babel/standalone`, bundled by `src/pages/playground/stylex.js.ts`, which the runner runs on the generated modules before linking them; keep its options in step with the site's in `astro.config.mjs`, and its packages at the site's StyleX version. The playground's emitter writes no `index.stylex.js` theme files, so `defineVars`, `defineConsts` and `defineMarker` do not work in programs yet. Every frame also receives `src/pages/playground/frame.json.ts`: base styles in the reset layer with the site's background, text color and font, and the Geist fonts as bytes for `FontFace`, so programs look at home without a font source in the frame's policy. It defines no CSS variables: templates write their colors out, so their code reads on its own. The frame allows forms, which otherwise never fire `submit`, and its `form-action 'none'` keeps them from submitting. The frame decides between terminal and visual output itself: it stays hidden until the program changes its body, as Halogen and React do when they mount, and then shows in the Output panel above the log. It holds output until `main` and the tasks it queued have run, so a program that prints before it mounts does not show its log alone for a frame. Browsers that run the frame in the page's process freeze the whole tab on an infinite loop, and Stop only helps where the frame runs in its own process.
- The page relaxes the style CSP for Monaco, which adds style elements and attributes at run time. Keep that relaxation in `src/pages/playground.astro`, and verify CSP or header changes in the production preview.

## Language server

`language-server` is a Rust crate compiled to WebAssembly. It runs on the single thread of a Web Worker and speaks LSP as JSON strings.

- Only work on the playground's language server builds Rust. `pnpm dev`, `pnpm build`, orb setup and the site deploy never do, and the UI must stay usable without a local build.
- Without Rust, `pnpm playground:language-server:download` installs the published canary for the current checkout, which needs full Git history. The deploy installs the same canary; see [Canaries](#canaries).
- The compiler crates come from the Iris repository at one release tag. Bump every tag in `Cargo.toml` together, rerun `pnpm playground:packages` for the same tag, and compare `src/requests.rs` and `src/capabilities.rs` with `compiler-executable/iris-lsp-workspace/src/handlers.rs` and `capabilities.rs` at that tag, carrying over new requests and changed parameters.
- Never take a `QueryEngine` snapshot. An input change waits for every snapshot to be dropped, which can never happen on one thread. Analysis borrows the engine directly.
- The server receives every package but loads a package source into the engine only once a project import reaches it. Loading parses the source and keeps its syntax tree, which for the whole package set takes about 900 MiB and four seconds. Do not load package sources eagerly, and keep the header scan in `src/workspace.rs` in agreement with the parser.
- A panic aborts the module, because `wasm32-unknown-unknown` cannot unwind. The host restarts the server and replays its documents, and the new worker reads the packages from the cache, rather than relying on `catch_unwind`.
- Diagnostics are collected outside `handle`, through `nextDiagnostics`, so that the host can drain them only while no messages wait and quick edits collect them once.

Build it with `pnpm playground:language-server`, which needs rustup and the wasm-bindgen CLI at the version `Cargo.toml` pins. Check it with `pnpm test:playground-language-server`, adding `-- --stress` after changes to document handling and `-- --all` after changes to package loading.

## Packages

The page downloads every package in `packages/index.json` on its first visit, sixteen archives at a time, and caches each archive in the Cache API, so later visits read them locally. Projects import from the whole set, so there is no dependency resolution in the page. Keep packages cached one archive per entry, so that a later playground can download them only when an import needs them.

`packages/index.json` follows the compiler's compatibility check for the pinned tag: the newest package set, limited to the `core` and `acme` presets in `tests-compatibility` and their dependencies. Regenerate it with `pnpm playground:packages` rather than editing it. `packages/registry.js` verifies and unpacks archives, and must keep working in both browsers and Node.

## Canaries

`.github/workflows/playground-canary.yml` publishes a prerelease tagged `playground-language-server-dev.<revision>` for every change to the server's inputs on `main`, where the revision is the last commit that changed them. The deploy installs that canary and skips publishing until it exists, and the canary's completion starts the deploy again. Keep the input paths in the workflow and in `scripts/download-playground-language-server.mjs` the same.
