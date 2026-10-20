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
 * the CSS of the program's StyleX styles.
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
      const compiled = compiler.compile(file.text, `/${file.path}`);
      rules.push(...compiled.rules);
      return { path: file.path, text: compiled.code };
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
  const missing = new Set();
  for (const file of files) {
    if (!file.path.endsWith(".js")) continue;
    const [imports] = parse(file.text);
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
      text += file.text.slice(last, start) + replacement;
      last = end;
    }
    linked[`${PREFIX}${file.path}`] = text + file.text.slice(last);
  }
  return { files: linked, missing: [...missing].sort() };
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
