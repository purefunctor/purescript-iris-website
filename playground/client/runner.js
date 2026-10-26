
import { parse } from "es-module-lexer/js";
import { TraceMap, decodedMappings, encodedMappings, traceSegment } from "@jridgewell/trace-mapping";

const IMPORT_MAP_PREFIX = "iris-output/";
const SANDBOX = "/playground/sandbox.html";
const STYLEX = "@stylexjs/stylex";
const PROVIDED_NPM_SPECIFIER = /^(react(-dom)?(\/|$)|@stylexjs\/stylex$)/;
const NPM_DIRECTORY = "npm/";
const STATIC_IMPORT = -1;
const IMPORT_META = -2;

const onceRetryingFailures = (load) => {
  let promise = null;
  return () =>
    (promise ??= load().catch((error) => {
      promise = null;
      throw error;
    }));
};

const loadModules = onceRetryingFailures(async () => {
  const response = await fetch("/playground/modules.json");
  if (!response.ok) throw new Error(`Could not load npm modules: ${response.status}`);
  return response.json();
});
const STYLEX_COMPILER = "/playground/stylex.js";
const loadStylex = onceRetryingFailures(() => import(/* @vite-ignore */ STYLEX_COMPILER));
const loadTheme = onceRetryingFailures(async () => {
  const response = await fetch("/playground/frame.json");
  if (!response.ok) throw new Error(`Could not load the frame's theme: ${response.status}`);
  const { css, fonts } = await response.json();
  return {
    css,
    fonts: fonts.map(({ family, data }) => ({ family, data: Uint8Array.from(atob(data), (char) => char.charCodeAt(0)) })),
  };
});

export async function link(files) {
  const first = rewrite(files, {});
  if (!first.missing.some((specifier) => PROVIDED_NPM_SPECIFIER.test(specifier))) return { ...first, css: "" };
  const [bundle, compiler] = await Promise.all([
    loadModules(),
    first.missing.includes(STYLEX) ? loadStylex() : null,
  ]);
  const compiled = compiler ? compileStylexBeforeRewrite(files, compiler) : { files, css: "" };
  const vendor = Object.entries(bundle.files).map(([name, text]) => ({ path: `${NPM_DIRECTORY}${name}`, text }));
  const provided = Object.fromEntries(
    Object.entries(bundle.entries).map(([specifier, name]) => [specifier, `${NPM_DIRECTORY}${name}`]),
  );
  return { ...rewrite([...compiled.files, ...vendor], provided), css: compiled.css };
}

function compileStylexBeforeRewrite(files, compiler) {
  const rules = [];
  const compiled = files.map((file) => {
    if (!file.path.endsWith(".js") || !file.text.includes(STYLEX)) return file;
    const result = compiler.compile(file.text, `/${file.path}`, file.map);
    rules.push(...result.rules);
    return { path: file.path, text: result.code, map: result.map };
  });
  return { files: compiled, css: compiler.styleSheet(rules) };
}

function rewrite(files, provided) {
  const paths = new Set(files.map((file) => file.path));
  const linked = {};
  const maps = {};
  const missing = new Set();
  for (const file of files) {
    if (!file.path.endsWith(".js")) continue;
    const [imports] = parse(file.text);
    const edits = [];
    let text = "";
    let last = 0;
    for (const { n: specifier, s: start, e: end, d: dynamic } of imports) {
      if (specifier === undefined || dynamic === IMPORT_META) continue;
      const relative = specifier.startsWith("./") || specifier.startsWith("../");
      if (!relative && !Object.hasOwn(provided, specifier)) {
        missing.add(specifier);
        continue;
      }
      const resolved = relative
        ? new URL(specifier, `https://iris.invalid/${file.path}`).pathname.slice(1)
        : provided[specifier];
      if (!paths.has(resolved)) missing.add(`${resolved} (imported by ${file.path})`);
      const importMapKey = `${IMPORT_MAP_PREFIX}${resolved}`;
      const replacement = dynamic === STATIC_IMPORT ? importMapKey : JSON.stringify(importMapKey);
      edits.push({ start, end, replacement });
      text += file.text.slice(last, start) + replacement;
      last = end;
    }
    const code = text + file.text.slice(last);
    linked[`${IMPORT_MAP_PREFIX}${file.path}`] = code;
    if (file.map) maps[file.path] = rewriteMap(file.map, file.text, code, edits);
  }
  return { files: linked, maps, missing: [...missing].sort() };
}

const lineStarts = (text) => [
  0,
  ...Array.from(text.matchAll(/\r\n|[\n\r\u2028\u2029]/g), (match) => match.index + match[0].length),
];

function position(starts, offset) {
  let low = 0;
  let high = starts.length;
  while (low + 1 < high) {
    const middle = (low + high) >>> 1;
    if (starts[middle] <= offset) low = middle;
    else high = middle;
  }
  return [low, offset - starts[low]];
}

function rewriteMap(map, before, after, edits) {
  if (!edits.length) return map;
  const oldLines = lineStarts(before);
  const newLines = lineStarts(after);
  const trace = new TraceMap(map);
  const mappings = newLines.map(() => new Map());
  const put = (offset, segment) => {
    const [line, column] = position(newLines, offset);
    mappings[line].set(column, [column, ...(segment?.slice(1) ?? [])]);
  };
  const move = (offset, segment) => {
    let shift = 0;
    for (const edit of edits) {
      if (offset < edit.start) break;
      if (offset < edit.end) return;
      shift += edit.replacement.length - (edit.end - edit.start);
    }
    put(offset + shift, segment);
  };
  const decoded = decodedMappings(trace);
  for (let line = 0; line < oldLines.length; line++) {
    const segments = decoded[line] ?? [];
    if (segments[0]?.[0] !== 0) move(oldLines[line], null);
    for (const segment of segments) move(oldLines[line] + segment[0], segment);
  }
  let shift = 0;
  for (const { start, end, replacement } of edits) {
    const [startLine, startColumn] = position(oldLines, start);
    const [endLine, endColumn] = position(oldLines, end);
    put(start + shift, traceSegment(trace, startLine, startColumn));
    shift += replacement.length - (end - start);
    put(end + shift, traceSegment(trace, endLine, endColumn));
  }
  return {
    ...map,
    mappings: encodedMappings(new TraceMap({
      ...map,
      mappings: mappings.map((line) => [...line.values()].sort((a, b) => a[0] - b[0])),
    })),
  };
}

export class Runner {
  #container;
  #onEvent;
  #frame = null;
  #listener = null;

  constructor(container, onEvent) {
    this.#container = container;
    this.#onEvent = onEvent;
  }

  get running() {
    return this.#frame !== null;
  }

  run(files, entry, css) {
    this.stop();
    const frame = document.createElement("iframe");
    frame.setAttribute("sandbox", "allow-scripts allow-forms");
    frame.setAttribute("referrerpolicy", "no-referrer");
    frame.setAttribute("aria-hidden", "true");
    frame.tabIndex = -1;
    frame.title = "Program sandbox";
    frame.style.cssText = "display:block;width:100%;height:100%;border:0;visibility:hidden";
    const themeOrUnstyled = loadTheme().catch(() => null);
    this.#listener = ({ source, data }) => {
      if (source !== frame.contentWindow || typeof data !== "object" || data === null) return;
      if (data.type === "ready") {
        themeOrUnstyled.then((theme) => {
          if (this.#frame === frame) frame.contentWindow.postMessage({ type: "run", files, entry: `${IMPORT_MAP_PREFIX}${entry}`, css, theme }, "*");
        });
      } else if (data.type === "view") {
        frame.removeAttribute("aria-hidden");
        frame.tabIndex = 0;
        frame.title = "Program view";
        frame.style.visibility = "visible";
        this.#onEvent({ type: "view" });
      } else if (["console", "error", "done"].includes(data.type)) {
        this.#onEvent({ type: data.type, level: String(data.level ?? ""), text: String(data.text ?? "") });
      }
    };
    window.addEventListener("message", this.#listener);
    frame.src = SANDBOX;
    this.#frame = frame;
    this.#container.append(frame);
  }

  stop() {
    if (this.#listener) window.removeEventListener("message", this.#listener);
    this.#frame?.remove();
    this.#frame = null;
    this.#listener = null;
  }
}
