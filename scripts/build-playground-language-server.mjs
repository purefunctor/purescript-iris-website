// Builds the playground language server into `public/playground/language-server`, where the
// playground loads it from instead of its mock server.
//
// Only needed when changing the Rust crate: the site never builds it, and the playground can run
// against its mock server or a published canary instead, which
// `scripts/download-playground-language-server.mjs` installs. Needs rustup, which installs the
// toolchain in `rust-toolchain.toml`, and the wasm-bindgen CLI at the version `Cargo.toml` pins:
//
//   cargo binstall wasm-bindgen-cli@<version>
//
// Usage: node scripts/build-playground-language-server.mjs

import { execFileSync } from "node:child_process";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { brotliCompressSync, constants, gzipSync } from "node:zlib";

const crate = new URL("../playground/language-server/", import.meta.url).pathname;
const dist = new URL("../public/playground/language-server/", import.meta.url).pathname;

const manifest = readFileSync(join(crate, "Cargo.toml"), "utf8");
const pinned = /^wasm-bindgen = "=([^"]+)"/m.exec(manifest)[1];
let installed;
try {
  installed = execFileSync("wasm-bindgen", ["--version"], { encoding: "utf8" }).split(" ")[1].trim();
} catch {
  fail(`wasm-bindgen is not installed. Run: cargo binstall wasm-bindgen-cli@${pinned}`);
}
if (installed !== pinned) {
  fail(`wasm-bindgen ${installed} does not match the crate's ${pinned}. Run: cargo binstall wasm-bindgen-cli@${pinned}`);
}

const started = performance.now();
execFileSync("cargo", ["build", "--release", "--locked", "--target", "wasm32-unknown-unknown"], {
  cwd: crate,
  stdio: "inherit",
});
const target = process.env.CARGO_TARGET_DIR ?? join(crate, "target");
const wasm = join(target, "wasm32-unknown-unknown/release/iris_playground_language_server.wasm");
rmSync(dist, { recursive: true, force: true });
// Function names make up about half of the module and only improve panic backtraces.
execFileSync(
  "wasm-bindgen",
  ["--target", "web", "--no-typescript", "--remove-name-section", "--remove-producers-section", "--out-dir", dist, "--out-name", "language_server", wasm],
  { stdio: "inherit" },
);

// The playground reads the manifest to decide whether a built server exists. The canary workflow
// records its release tag as the source.
const lock = readFileSync(join(crate, "Cargo.lock"), "utf8");
const source = /name = "building"\nversion = "[^"]+"\nsource = "git\+[^?]+\?tag=([^#]+)#([0-9a-f]{12})/.exec(lock);
const release = process.env.PLAYGROUND_LANGUAGE_SERVER_RELEASE ?? "local";
writeFileSync(
  join(dist, "manifest.json"),
  `${JSON.stringify({ iris: source[1], revision: source[2], source: release }, null, 2)}\n`,
);

const output = readFileSync(join(dist, "language_server_bg.wasm"));
const gzip = gzipSync(output, { level: 9 }).byteLength;
const brotli = brotliCompressSync(output, {
  params: { [constants.BROTLI_PARAM_QUALITY]: 11 },
}).byteLength;
const kib = (bytes) => `${(bytes / 1024).toFixed(0)} KiB`;
console.log(
  `Built in ${((performance.now() - started) / 1000).toFixed(1)} s: ` +
    `${kib(output.byteLength)} raw, ${kib(gzip)} gzip, ${kib(brotli)} brotli.`,
);

function fail(message) {
  console.error(message);
  process.exit(1);
}
