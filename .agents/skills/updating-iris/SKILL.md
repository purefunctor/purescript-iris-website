---
name: updating-iris
description: "Updates the website and playground to an Iris release. Use when asked to upgrade Iris, refresh the playground compiler, or update both to the latest stable version."
---

# Updating Iris

Use the known paths below instead of rediscovering the build. Run commands from the repository root.
Read `playground/AGENTS.md` and load `verifying-iris-website` before making changes.

## Establish the versions

```sh
git status --short
iris --version
gh api repos/purefunctor/purescript-iris/releases/latest --jq .tag_name
cat playground/language-server/Cargo.toml
cat playground/language-server/rust-toolchain.toml
```

Use the latest stable release unless the user names another revision. Record the old playground tag
and the target tag. Fetch both tags in the compiler checkout and resolve the target commit.

The website CLI is not pinned in `package.json`: `.agents/setup` and
`.github/workflows/deploy.yml` install the latest stable release through `public/install.sh`.
If the installed CLI already matches the target, leave it alone. Otherwise install the selected tag
with the reviewed installer, preserving attestation verification where available:

```sh
IRIS_VERSION="$tag" sh public/install.sh
iris --version
```

## Take the unchanged-contract path first

Compare these paths between the old and target compiler tags:

- `compiler-executable/iris-lsp-workspace/src/handlers.rs`
- `compiler-executable/iris-lsp-workspace/src/capabilities.rs`
- `install.sh` and `install.ps1`

If the LSP files are unchanged, no protocol discovery is needed. If they changed, compare them with
`playground/language-server/src/requests.rs` and
`playground/language-server/src/capabilities.rs` and carry over new requests or changed parameters.
Follow compiler errors into other APIs only when the build requires it. Reopen broader discovery
only when a named path, script, or contract no longer matches this procedure.

Compare the target installers byte-for-byte with `public/install.sh` and `public/install.ps1`.
If they match, leave them and the README provenance unchanged. Otherwise review and sync both from
the identified target revision, following the README's installer rules.

## Update the inputs

1. Set every Iris dependency tag in `playground/language-server/Cargo.toml` to the target tag.
2. Update only the affected Cargo dependencies and regenerate the package index:

   ```sh
   cargo update --manifest-path playground/language-server/Cargo.toml -p building
   pnpm playground:packages
   ```

3. Update the current `iris --version` output in
   `src/Website/Documentation/GettingStarted.purs`. Leave historical benchmarks, minimum supported
   versions, and illustrative pinned-version or packaging examples unchanged.
4. Review the diff. The package generator reads the tag from Cargo.toml and may change only the
   `iris` field when the Registry package set and compatibility presets are unchanged. Do not edit
   its output by hand or update unrelated dependencies.

## Verify the real compiler

Use the Rust toolchain and WASM target in `playground/language-server/rust-toolchain.toml`, and the
exact wasm-bindgen CLI version in Cargo.toml. Install missing tools locally only for this task;
normal website setup and builds do not need Rust.

```sh
pnpm playground:language-server
pnpm test:playground-client
pnpm test:playground-language-server -- --stress
pnpm test:playground-language-server -- --all
pnpm build
iris format --check
git diff --check
```

Build the WASM server before the site so the production output includes the new binary. Check that
`public/playground/language-server/manifest.json` and the test banner report the target tag and
commit. The published-server download command selects a committed canary, so it cannot verify an
uncommitted upgrade. Generated WASM files stay ignored.

Use the production preview from `verifying-iris-website`. Confirm that the playground loads the real
server, shows the target version, runs the Console template, displays generated JavaScript, and runs
the React counter with a working increment button. Inspect changed documentation in the development
portal. Reuse existing tests rather than adding a test that asserts a release number.

## Publish only when authorized

Pushes to `main` that change the language-server inputs start
`.github/workflows/playground-canary.yml`. It builds, tests, attests, and publishes the WASM archive.
The deploy workflow skips publishing while that archive is missing, then runs again when the canary
succeeds. A successful first deploy workflow can therefore mean that deployment was skipped.

After an authorized push, subscribe to CI for the exact pushed commit. Wait for the canary and the
subsequent deployment, and confirm that the **Deploy static assets** step succeeded rather than
skipped. Check `https://iris-lang.com/playground/language-server/manifest.json` for the target tag,
compiler revision, and canary source, then verify the live playground. Do not manually dispatch a
second deployment while the normal workflow is progressing. Report the pushed commit and the actual
deployment result separately from local validation.
