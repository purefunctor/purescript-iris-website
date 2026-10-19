// Runs the built playground language server in Node against real Registry packages, checks the
// main editor features, and reports timings, memory and the module's size.
//
// `--stress` also replays typing a module one character at a time, requesting diagnostics, hover
// and completion along the way, so that incomplete code at every step goes through the analyzer.
//
// Usage: node scripts/test-playground-language-server.mjs [--stress]
// Build the server first with `node scripts/build-playground-language-server.mjs`.

import assert from "node:assert/strict";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { join } from "node:path";
import { archiveUrl, resolveClosure, unpackPackage } from "../playground/packages/registry.js";

const root = new URL("..", import.meta.url).pathname;
const dist = join(root, "public/playground/language-server");
const archives = join(root, "playground/.cache/archives");
const stress = process.argv.includes("--stress");

const ROOTS = ["prelude", "effect", "console", "arrays", "maybe", "either", "strings", "foldable-traversable", "aff"];
const PROJECT = "file:///project/";

const UTIL = `module Util (double, answer) where

import Prelude

double :: Int -> Int
double x = x * 2

foreign import answer :: Int
`;

const UTIL_JS = `export const answer = 42;
`;

const MAIN = `module Main where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff (delay, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Util (answer, double)

total :: Int
total = Array.foldl (+) 0 (Array.range 1 10)

firstEven :: Maybe Int
firstEven = Array.find (\\x -> x \`mod\` 2 == 0) [ 1, 3, 4, 5 ]

main :: Effect Unit
main = launchAff_ do
  delay (Milliseconds 1.0)
  liftEffect $ log $ String.toUpper "sum: " <> show (double total + answer)
  liftEffect $ log $ show (fromMaybe 0 firstEven)
`;

const timings = [];
const time = async (label, action) => {
  const started = performance.now();
  const result = await action();
  timings.push([label, performance.now() - started]);
  return result;
};

// Load the server.
const { default: _init, initSync, LanguageServer } = await import(join(dist, "language_server.js"));
const module = readFileSync(join(dist, "language_server_bg.wasm"));
const exports = await time("Instantiate", () => initSync({ module }));
const server = new LanguageServer();

let nextId = 1;
const request = (method, params) => {
  const id = nextId++;
  const outgoing = JSON.parse(server.handle(JSON.stringify({ jsonrpc: "2.0", id, method, params })));
  const response = outgoing.find((message) => message.id === id);
  if (response.error) throw new Error(`${method}: ${response.error.message}`);
  return response.result;
};
const notify = (method, params) =>
  JSON.parse(server.handle(JSON.stringify({ jsonrpc: "2.0", method, params })));
const drainDiagnostics = () => {
  const published = new Map();
  for (let next = server.nextDiagnostics(); next; next = server.nextDiagnostics()) {
    const { params } = JSON.parse(next);
    published.set(params.uri, params.diagnostics);
  }
  return published;
};
const errors = (diagnostics) => (diagnostics ?? []).filter((diagnostic) => diagnostic.severity === 1);

const initialized = request("initialize", {
  capabilities: { textDocument: { hover: { contentFormat: ["markdown", "plaintext"] } } },
});
console.log(`Server: ${initialized.serverInfo.name} ${initialized.serverInfo.version}`);
notify("initialized", {});

// Load the starter packages from the Registry, caching archives on disk.
const index = JSON.parse(readFileSync(join(root, "playground/packages/index.json"), "utf8"));
const closure = resolveClosure(index, ROOTS);
const packages = await time(`Fetch and unpack ${closure.length} packages`, () =>
  Promise.all(
    closure.map(async (entry) => {
      const cached = join(archives, `${entry.name}-${entry.version}.tar.gz`);
      let archive;
      if (existsSync(cached)) {
        archive = readFileSync(cached);
      } else {
        const response = await fetch(archiveUrl(entry));
        if (!response.ok) throw new Error(`${archiveUrl(entry)}: ${response.status}`);
        archive = new Uint8Array(await response.arrayBuffer());
        mkdirSync(archives, { recursive: true });
        writeFileSync(cached, archive);
      }
      return { name: entry.name, files: await unpackPackage(entry, archive) };
    }),
  ),
);
const files = packages.flatMap((pkg) => pkg.files);
const sourceBytes = files.reduce((total, file) => total + file.text.length, 0);
console.log(
  `Packages: ${closure.length} from package set ${index.packageSet.version}, ` +
    `${files.length} files, ${(sourceBytes / 1024).toFixed(0)} KiB of source`,
);
const loaded = await time("iris/setPackages", () => request("iris/setPackages", { packages }));
assert.ok(loaded.sources > 200, `expected package sources, got ${loaded.sources}`);

// Open the project and collect its first diagnostics, which checks everything Main imports.
const open = (path, text, languageId = "purescript") =>
  notify("textDocument/didOpen", { textDocument: { uri: PROJECT + path, languageId, version: 1, text } });
open("src/Util.js", UTIL_JS, "javascript");
open("src/Util.purs", UTIL);
open("src/Main.purs", MAIN);
const first = await time("First diagnostics (cold)", drainDiagnostics);
for (const path of ["src/Main.purs", "src/Util.purs"]) {
  assert.ok(first.has(PROJECT + path), `no diagnostics published for ${path}`);
  assert.deepEqual(errors(first.get(PROJECT + path)), [], `unexpected errors in ${path}`);
}

const main = PROJECT + "src/Main.purs";
const at = (text, needle, offset = 0) => {
  const index = text.indexOf(needle) + offset;
  const before = text.slice(0, index).split("\n");
  return { line: before.length - 1, character: before.at(-1).length };
};
const position = (needle, offset) => ({ textDocument: { uri: main }, position: at(MAIN, needle, offset) });

const hover = await time("Hover", () => request("textDocument/hover", position("log $ String", 1)));
assert.match(JSON.stringify(hover), /String -> Effect Unit/);

const completion = await time("Completion (cold)", () =>
  request("textDocument/completion", position("Array.range", 6)),
);
const labels = (completion.items ?? completion).map((item) => item.label);
assert.ok(labels.includes("range"), "completion after Array. should offer range");
await time("Completion (warm)", () => request("textDocument/completion", position("Array.range", 6)));

const definition = await time("Definition", () =>
  request("textDocument/definition", position("launchAff_ do", 1)),
);
assert.match(JSON.stringify(definition), /file:\/\/\/packages\/aff\/src\/Effect\/Aff\.purs/);

// From the definition in Util, references reach the use in Main.
const references = await time("References", () =>
  request("textDocument/references", {
    textDocument: { uri: PROJECT + "src/Util.purs" },
    position: at(UTIL, "double x", 1),
    context: { includeDeclaration: true },
  }),
);
assert.ok(references.some((location) => location.uri === main), "references should reach Main");

await time("Semantic tokens", () => request("textDocument/semanticTokens/full", { textDocument: { uri: main } }));
await time("Document symbols", () => request("textDocument/documentSymbol", { textDocument: { uri: main } }));
const formatted = await time("Formatting", () =>
  request("textDocument/formatting", { textDocument: { uri: main }, options: { tabSize: 2, insertSpaces: true } }),
);
assert.ok(Array.isArray(formatted));

// An edit that breaks a definition, then one that fixes it again.
const change = (version, needle, replacement) => {
  const start = at(MAIN, needle);
  const end = at(MAIN, needle, needle.length);
  notify("textDocument/didChange", {
    textDocument: { uri: main, version },
    contentChanges: [{ range: { start, end }, text: replacement }],
  });
};
change(2, "Array.foldl (+) 0 (Array.range 1 10)", '"ten"');
const broken = await time("Diagnostics after an edit", drainDiagnostics);
assert.ok(errors(broken.get(main)).length > 0, "a String total should not type check");
notify("textDocument/didChange", { textDocument: { uri: main, version: 3 }, contentChanges: [{ text: MAIN }] });
assert.deepEqual(errors(drainDiagnostics().get(main)), []);

// The emitted JavaScript runs: write it out, import Main and capture what main logs.
const emitted = await time("iris/emit", () => request("iris/emit", {}));
assert.equal(emitted.status, "emitted");
assert.deepEqual(emitted.modules.map((module) => module.name), ["Main", "Util"]);
const output = join(root, "playground/.cache/emit");
rmSync(output, { recursive: true, force: true });
for (const file of emitted.files) {
  mkdirSync(dirname(join(output, file.path)), { recursive: true });
  writeFileSync(join(output, file.path), file.text);
}
writeFileSync(join(output, "package.json"), '{ "type": "module" }\n');
const logged = [];
const log = console.log;
console.log = (...values) => logged.push(values.join(" "));
try {
  (await import(join(output, "Main/index.js"))).main();
  await new Promise((resolve) => setTimeout(resolve, 100));
} finally {
  console.log = log;
}
assert.deepEqual(logged, ["SUM: 152", "4"]);

// Removing Util breaks Main's import.
notify("textDocument/didClose", { textDocument: { uri: PROJECT + "src/Util.purs" } });
const removed = drainDiagnostics();
assert.ok(errors(removed.get(main)).length > 0, "Main should report the missing Util module");
const failed = request("iris/emit", {});
assert.equal(failed.status, "failed");
assert.ok(failed.errors.some((error) => error.uri === main));
open("src/Util.purs", UTIL);
assert.deepEqual(errors(drainDiagnostics().get(main)), []);

if (stress) {
  const uri = PROJECT + "src/Typing.purs";
  const text = MAIN.replace("module Main", "module Typing");
  notify("textDocument/didOpen", { textDocument: { uri, languageId: "purescript", version: 1, text: "" } });
  let line = 0;
  let character = 0;
  let requests = 0;
  await time(`Typing ${text.length} characters`, () => {
    for (let index = 0; index < text.length; index++) {
      const char = text[index];
      const at = { line, character };
      notify("textDocument/didChange", {
        textDocument: { uri, version: index + 2 },
        contentChanges: [{ range: { start: at, end: at }, text: char }],
      });
      if (char === "\n") {
        line++;
        character = 0;
      } else {
        character += char.length;
      }
      const cursor = { textDocument: { uri }, position: { line, character } };
      request("textDocument/hover", cursor);
      request("textDocument/completion", cursor);
      requests += 2;
      if (index % 8 === 0) drainDiagnostics();
    }
  });
  const final = drainDiagnostics();
  assert.deepEqual(errors(final.get(uri)), [], "the fully typed module should check");
  console.log(`Stress: ${text.length} edits and ${requests} requests without a panic`);
}

const memory = exports.memory.buffer.byteLength;
const wasmBytes = module.byteLength;
console.log("");
for (const [label, ms] of timings) console.log(`${label.padEnd(36)} ${ms.toFixed(1).padStart(8)} ms`);
console.log(`${"WASM memory".padEnd(36)} ${(memory / 1024 / 1024).toFixed(1).padStart(8)} MiB`);
console.log(`${"Module size".padEnd(36)} ${(wasmBytes / 1024).toFixed(0).padStart(8)} KiB`);
console.log("\nAll checks passed.");
