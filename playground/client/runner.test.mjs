import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { registerHooks } from "node:module";
import { test } from "node:test";
import { runInNewContext } from "node:vm";
import { TraceMap, encodedMap, originalPositionFor } from "@jridgewell/trace-mapping";
import { link } from "./runner.js";

const source = "file:///project/src/Main.purs";
const sourceMap = (mappings, sources = [source]) => encodedMap(new TraceMap({
  version: 3, sources, sourcesContent: ["module Main where"], names: ["main"], mappings,
}));
const denseMap = (text) => sourceMap(text.split("\n").map((line, row) =>
  Array.from({ length: line.length }, (_, column) => [column, 0, row + 10, column, 0])));
const location = (map, text, token) => {
  const prefix = text.slice(0, text.indexOf(token));
  return originalPositionFor(new TraceMap(map), {
    line: prefix.split("\n").length,
    column: prefix.length - prefix.lastIndexOf("\n") - 1,
  });
};
const foreign = { path: "Main/foreign.js", text: "export const crash = () => { throw Error('ffi'); };" };

test("link preserves source URIs and same-line columns after static, dynamic and export rewrites", async () => {
  const text = `import { crash } from "./foreign.js"; const emoji = "😀"; crash(); export { crash } from "./foreign.js"; const load = () => import('./foreign.js'); throw Error("after");\n\nexport const main = crash;`;
  const map = denseMap(text);
  const original = structuredClone(map);
  const result = await link([{ path: "Main/index.js", text, map }, foreign]);
  const code = result.files["iris-output/Main/index.js"];
  assert.deepEqual(result.missing, []);
  assert.equal(result.css, "");
  assert.match(code, /import\("iris-output\/Main\/foreign.js"\)/);
  assert.deepEqual(Object.keys(result.maps), ["Main/index.js"]);
  assert.equal(typeof result.maps["Main/index.js"].mappings, "string");
  for (const token of ["const emoji", "crash();", "const load", "throw Error", "export const main"]) {
    assert.deepEqual(location(result.maps["Main/index.js"], code, token), location(map, text, token), token);
  }
  assert.deepEqual(map, original, "link must not mutate emitter maps");
  assert.deepEqual(result.maps["Main/index.js"].sourcesContent, map.sourcesContent);
});

test("rewriting restores sparse mapping state and preserves unmapped regions", async () => {
  const text = `import "./foreign.js"; mapped(); unmapped();\nraw();`;
  const literal = text.indexOf("./foreign.js");
  const unmapped = text.indexOf("unmapped()");
  // The active mapping after the import starts inside the replaced literal, not at its end.
  const map = sourceMap([[[0], [literal + 2, 0, 8, 3], [unmapped]], []]);
  const result = await link([{ path: "Main/index.js", text, map }, foreign]);
  const linkedMap = result.maps["Main/index.js"];
  const code = result.files["iris-output/Main/index.js"];
  assert.deepEqual(location(linkedMap, code, "mapped()"), location(map, text, "mapped()"));
  for (const token of ["iris-output", "unmapped()", "raw()"]) {
    assert.equal(location(linkedMap, code, token).source, null, token);
  }
});

test("rewrites that remove a string continuation preserve later line and column mappings", async () => {
  const text = 'const load = () => import("./foreign\\\n.js"); throw Error("after");\nexport const main = load;';
  const map = denseMap(text);
  const result = await link([{ path: "Main/index.js", text, map }, foreign]);
  assert.deepEqual(result.missing, []);
  const code = result.files["iris-output/Main/index.js"];
  assert.equal(code.split("\n").length, 2);
  for (const token of ["throw Error", "export const main"]) {
    assert.deepEqual(location(result.maps["Main/index.js"], code, token), location(map, text, token));
  }
});

test("unchanged maps, missing imports and unmapped FFI retain the public link contract", async () => {
  const text = 'import "unprovided"; export const main = () => {};';
  const map = sourceMap([[[0, 0, 0, 0]]], ["iris-package:///prelude/src/Prelude.purs"]);
  const result = await link([{ path: "Main/index.js", text, map }, foreign, { path: "Main/index.js.map", text: "{}" }]);
  assert.deepEqual(result.missing, ["unprovided"]);
  assert.deepEqual(result.maps, { "Main/index.js": map });
  assert.equal(result.files["iris-output/Main/index.js"], text);
  assert.equal(result.files["iris-output/Main/foreign.js"], foreign.text);
  assert.equal(Object.keys(result.files).length, 2);
  assert.deepEqual((await link([foreign])).maps, {});
});

test("StyleX composes source locations through Babel and import rewriting", async (t) => {
  // Exercise the actual compiler bundle exposed by the endpoint, without a server or network.
  const { bundlePlaygroundStylex } = await import("../../src/lib/playgroundStylex.ts");
  const compiler = await bundlePlaygroundStylex();
  const hooks = registerHooks({
    resolve(specifier, context, next) {
      return specifier === "/playground/stylex.js"
        ? { url: "playground-test:stylex", shortCircuit: true } : next(specifier, context);
    },
    load(url, context, next) {
      return url === "playground-test:stylex"
        ? { format: "module", source: compiler, shortCircuit: true } : next(url, context);
    },
  });
  t.after(() => hooks.deregister());
  t.mock.method(globalThis, "fetch", async (url) => {
    assert.equal(url, "/playground/modules.json");
    return { ok: true, json: async () => ({
      files: { "stylex.js": "export {};", "react.js": "export const version = 'test';" },
      entries: { "@stylexjs/stylex": "stylex.js", react: "react.js" },
    }) };
  });
  const text = 'import * as stylex from "@stylexjs/stylex"; const styles = stylex.create({ root: { color: "red" } }); export const main = () => { stylex.props(styles.root); throw Error("styled"); };';
  const plain = 'import { version } from "react"; export const main = () => version;';
  const map = denseMap(plain);
  const result = await link([
    { path: "Styled/index.js", text, map: denseMap(text) },
    { path: "Main/index.js", text: plain, map },
  ]);
  assert.deepEqual(result.missing, []);
  assert.match(result.css, /color:red/);
  assert.doesNotMatch(result.files["iris-output/Styled/index.js"], /stylex\.create/);
  assert.deepEqual(location(result.maps["Styled/index.js"], result.files["iris-output/Styled/index.js"], "throw"), {
    // Babel emits names for identifiers, not the throw keyword; the source position survives.
    source, line: 11, column: text.indexOf("throw"), name: null,
  });
  assert.deepEqual(Object.keys(result.maps), ["Styled/index.js", "Main/index.js"]);
  assert.deepEqual(location(result.maps["Main/index.js"], result.files["iris-output/Main/index.js"], "export const main"), location(map, plain, "export const main"));
});

test("sandbox posts stable raw URLs for console, errors and rejection stacks", async () => {
  const html = await readFile(new URL("../../public/playground/sandbox.html", import.meta.url), "utf8");
  const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const events = new Map();
  const messages = [];
  const blobs = [];
  const parent = { postMessage: (message) => messages.push(message) };
  const console = {};
  runInNewContext(script, {
    parent, console, Blob, Error,
    URL: { createObjectURL: (blob) => { blobs.push(blob); return `blob:null/module-${blobs.length}`; } },
    addEventListener: (type, handler) => events.set(type, handler),
    MutationObserver: class { observe() {} disconnect() {} },
    MessageChannel: class {
      port1 = { close() {}, onmessage: null };
      port2 = { postMessage: () => this.port1.onmessage() };
    },
    document: { body: {}, head: { append() {} }, createElement: () => ({}) },
  });
  assert.equal(messages[0].type, "ready");
  await events.get("message")({ source: parent, data: {
    type: "run", entry: "iris-output/Main/index.js", files: {
      "iris-output/Main/index.js": "export const main = () => {};\n//# sourceURL=old-name.js",
      "iris-output/Main/foreign.js": foreign.text,
    },
  } });
  assert.match(await blobs[0].text(), /old-name\.js\n\/\/# sourceURL=iris-playground:\/\/\/Main\/index\.js\n$/);
  console.log("at blob:null/module-1:1:33", "ffi@blob:null/module-2:2:9");
  const error = new Error("failed");
  error.stack = "Error: failed\n at blob:null/module-2:2:9\n at blob:null/module-1:3:7";
  console.error(error);
  events.get("error")({ error });
  events.get("unhandledrejection")({ reason: error });
  const posted = messages.slice(-4);
  assert.equal(posted[0].text, "at iris-playground:///Main/index.js:1:33 ffi@iris-playground:///Main/foreign.js:2:9");
  for (const message of posted.slice(1)) {
    assert.equal(message.text, "Error: failed\n at iris-playground:///Main/foreign.js:2:9\n at iris-playground:///Main/index.js:3:7");
  }
  assert.match(html, /default-src 'none'; form-action 'none'; script-src 'unsafe-inline' blob:; style-src 'unsafe-inline'/);
});
