// Runs emitted JavaScript in a sandboxed frame and reports what it logs.
//
// Generated modules import each other by relative path, which blob URLs cannot resolve, so each
// file's specifiers are rewritten to bare keys under iris-output/ that the frame's import map maps
// to blob URLs. Keys must be bare, because a path such as /x.js cannot resolve against a blob
// URL's base. The only bare specifiers provided are React's, which the Registry's React bindings
// import, and StyleX's, which Iris.StyleX compiles to. The page fetches them, bundled from the
// site's own packages by src/pages/playground/modules.json.ts, only when a program imports one.
// StyleX calls must also be compiled to class names and CSS, as the site's bundler does, so the
// page then loads the compiler from src/pages/playground/stylex.js.ts and runs it before linking,
// and the frame adds the CSS. Other npm packages cannot be provided. The lexer's asm.js build
// needs no WebAssembly, so the page's policy stays as is.

import { parse } from "es-module-lexer/js";
import { TraceMap, decodedMappings, encodedMappings, traceSegment } from "@jridgewell/trace-mapping";

const PREFIX = "iris-output/";
const SANDBOX = "/playground/sandbox.html";
const STYLEX = "@stylexjs/stylex";
const PROVIDED = /^(react(-dom)?(\/|$)|@stylexjs\/stylex$)/;
// Generated modules live in directories named after PureScript modules, which are capitalized.
const NPM_DIRECTORY = "npm/";

/** Loads once, and again after a failure. */
const once = (load) => {
  let promise = null;
  return () =>
    (promise ??= load().catch((error) => {
      promise = null;
      throw error;
    }));
};

const loadModules = once(async () => {
  const response = await fetch("/playground/modules.json");
  if (!response.ok) throw new Error(`Could not load npm modules: ${response.status}`);
  return response.json();
});
// A literal specifier would make Vite resolve the endpoint as a source file.
const STYLEX_COMPILER = "/playground/stylex.js";
const loadStylex = once(() => import(/* @vite-ignore */ STYLEX_COMPILER));
// The site's tokens, base styles and fonts, from src/pages/playground/frame.json.ts.
const loadTheme = once(async () => {
  const response = await fetch("/playground/frame.json");
  if (!response.ok) throw new Error(`Could not load the frame's theme: ${response.status}`);
  const { css, fonts } = await response.json();
  return {
    css,
    fonts: fonts.map(({ family, data }) => ({ family, data: Uint8Array.from(atob(data), (char) => char.charCodeAt(0)) })),
  };
});

/**
 * Rewrites imports between `files` and returns the frame's files, keyed by import map key, with
 * the CSS of the program's StyleX styles, and `maps`: the source map of each linked module that
 * has one, keyed by its path in `files`. FFI and runtime modules have none, so their stack frames
 * stay in JavaScript.
 */
export async function link(files) {
  const first = rewrite(files, {});
  if (!first.missing.some((specifier) => PROVIDED.test(specifier))) return { ...first, css: "" };
  const [bundle, compiler] = await Promise.all([
    loadModules(),
    first.missing.includes(STYLEX) ? loadStylex() : null,
  ]);
  let css = "";
  if (compiler) {
    // The compiler finds StyleX calls through their import, so it runs before the rewrite.
    const rules = [];
    files = files.map((file) => {
      if (!file.path.endsWith(".js") || !file.text.includes(STYLEX)) return file;
      const compiled = compiler.compile(file.text, `/${file.path}`, file.map);
      rules.push(...compiled.rules);
      // Babel reprints the module, so only its composed map stays valid. A cached compiler from
      // before maps omits it, which leaves the module unmapped rather than mapped wrongly.
      return { path: file.path, text: compiled.code, map: compiled.map };
    });
    css = compiler.styleSheet(rules);
  }
  const vendor = Object.entries(bundle.files).map(([name, text]) => ({ path: `${NPM_DIRECTORY}${name}`, text }));
  const provided = Object.fromEntries(
    Object.entries(bundle.entries).map(([specifier, name]) => [specifier, `${NPM_DIRECTORY}${name}`]),
  );
  return { ...rewrite([...files, ...vendor], provided), css };
}

/** `provided` maps bare specifiers to paths among `files`. */
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
      if (specifier === undefined || dynamic === -2) continue;
      const relative = specifier.startsWith("./") || specifier.startsWith("../");
      if (!relative && !Object.hasOwn(provided, specifier)) {
        missing.add(specifier);
        continue;
      }
      const resolved = relative
        ? new URL(specifier, `https://iris.invalid/${file.path}`).pathname.slice(1)
        : provided[specifier];
      if (!paths.has(resolved)) missing.add(`${resolved} (imported by ${file.path})`);
      // Static imports span the specifier without quotes; dynamic ones span the quoted literal.
      const replacement = dynamic === -1 ? `${PREFIX}${resolved}` : JSON.stringify(`${PREFIX}${resolved}`);
      edits.push({ start, end, replacement });
      text += file.text.slice(last, start) + replacement;
      last = end;
    }
    const code = text + file.text.slice(last);
    linked[`${PREFIX}${file.path}`] = code;
    if (file.map) maps[file.path] = rewriteMap(file.map, file.text, code, edits);
  }
  return { files: linked, maps, missing: [...missing].sort() };
}

// The offset of each line's first character, with the line terminators of JavaScript.
const lineStarts = (text) => [
  0,
  ...Array.from(text.matchAll(/\r\n|[\n\r\u2028\u2029]/g), (match) => match.index + match[0].length),
];

// The zero-based line and column of `offset`, given its text's `lineStarts`.
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

// Moves `map` from `before` to `after`, the same module with its import specifiers replaced as
// `edits` record. Source-map columns and lexer offsets both count UTF-16 code units. Moving only
// whole lines is not enough, because an import and the expression that throws can share a line.
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
    // Mapping state resets on each original line, including when a continued string literal
    // loses its newline during rewriting. Do not let the preceding line's mapping bleed in.
    if (segments[0]?.[0] !== 0) move(oldLines[line], null);
    for (const segment of segments) move(oldLines[line] + segment[0], segment);
  }
  let shift = 0;
  for (const { start, end, replacement } of edits) {
    const [startLine, startColumn] = position(oldLines, start);
    const [endLine, endColumn] = position(oldLines, end);
    // The rewritten literal belongs to its original start; restore the original mapping
    // immediately afterwards, even if its last segment was inside the replaced literal.
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

  /**
   * The frame stays hidden until the program changes its document, such as when Halogen or React
   * mounts into it. The runner then shows the frame, filling `container`, and reports a `view`
   * event, so the output becomes the program's page instead of its log.
   *
   * @param {HTMLElement} container where the frame lives
   * @param {(event: { type: "console" | "error" | "done" | "view", level?: string, text?: string }) => void} onEvent
   */
  constructor(container, onEvent) {
    this.#container = container;
    this.#onEvent = onEvent;
  }

  get running() {
    return this.#frame !== null;
  }

  /** Starts a program in a new frame, stopping the previous one. */
  run(files, entry, css) {
    this.stop();
    const frame = document.createElement("iframe");
    // Forms fire submit events only with allow-forms; the frame's form-action keeps them from leaving.
    frame.setAttribute("sandbox", "allow-scripts allow-forms");
    frame.setAttribute("referrerpolicy", "no-referrer");
    frame.setAttribute("aria-hidden", "true");
    frame.tabIndex = -1;
    frame.title = "Program sandbox";
    frame.style.cssText = "display:block;width:100%;height:100%;border:0;visibility:hidden";
    // The theme loads while the frame does; a program runs unstyled if it cannot.
    const theme = loadTheme().catch(() => null);
    this.#listener = ({ source, data }) => {
      if (source !== frame.contentWindow || typeof data !== "object" || data === null) return;
      if (data.type === "ready") {
        theme.then((theme) => {
          if (this.#frame === frame) frame.contentWindow.postMessage({ type: "run", files, entry: `${PREFIX}${entry}`, css, theme }, "*");
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
