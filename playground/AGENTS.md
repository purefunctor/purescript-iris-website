# Playground

The `/playground` page edits multi-file Iris projects in Monaco, with a language server built from the compiler's own crates and packages from the Registry. These directories hold the parts that are not PureScript UI.

## Language server

`language-server` is a Rust crate compiled to WebAssembly. It runs on the single thread of a Web Worker and speaks LSP as JSON strings.

- Only work on the playground's language server builds Rust. `pnpm dev`, `pnpm build`, orb setup and the site deploy never do, and the UI must stay usable without a local build.
- The compiler crates come from the Iris repository at one release tag. Bump every tag in `Cargo.toml` together, rerun `pnpm playground:packages` for the same tag, and compare `src/requests.rs` and `src/capabilities.rs` with `compiler-executable/iris-lsp-workspace/src/handlers.rs` and `capabilities.rs` at that tag, carrying over new requests and changed parameters.
- Never take a `QueryEngine` snapshot. An input change waits for every snapshot to be dropped, which can never happen on one thread. Analysis borrows the engine directly.
- A panic aborts the module, because `wasm32-unknown-unknown` cannot unwind. The host restarts the server and replays its documents and packages rather than relying on `catch_unwind`.
- Diagnostics are collected outside `handle`, through `nextDiagnostics`, so that the host can drain them only while no messages wait and quick edits collect them once.

Build it with `pnpm playground:language-server`, which needs rustup and the wasm-bindgen CLI at the version `Cargo.toml` pins. Check it with `pnpm test:playground-language-server`, adding `-- --stress` after changes to document handling.

## Packages

`packages/index.json` lists the packages users can install. It follows the compiler's compatibility check for the pinned tag: the newest package set, limited to the `core` and `acme` presets in `tests-compatibility` and their dependencies. Regenerate it with `pnpm playground:packages` rather than editing it. `packages/registry.js` resolves, verifies and unpacks archives, and must keep working in both browsers and Node.
