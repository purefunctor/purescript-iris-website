// Runs emitted JavaScript in a sandboxed frame and reports what it logs.
//
// Generated modules import each other by relative path, which blob URLs cannot resolve, so each
// file's specifiers are rewritten to bare keys under iris-output/ that the frame's import map maps
// to blob URLs. Keys must be bare, because a path such as /x.js cannot resolve against a blob
// URL's base. Other bare specifiers, such as npm packages that some FFI imports, cannot be
// provided. The lexer's asm.js build needs no WebAssembly, so the page's policy stays as is.

import { parse } from "es-module-lexer/js";

const PREFIX = "iris-output/";
const SANDBOX = "/playground/sandbox.html";

/** Rewrites imports between `files` and returns the frame's files, keyed by import map key. */
export async function link(files) {
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
      if (!specifier.startsWith("./") && !specifier.startsWith("../")) {
        missing.add(specifier);
        continue;
      }
      const resolved = new URL(specifier, `https://iris.invalid/${file.path}`).pathname.slice(1);
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
   * @param {HTMLElement} container where the hidden frame lives
   * @param {(event: { type: "console" | "error" | "done", level?: string, text?: string }) => void} onEvent
   */
  constructor(container, onEvent) {
    this.#container = container;
    this.#onEvent = onEvent;
  }

  get running() {
    return this.#frame !== null;
  }

  /** Starts a program in a new frame, stopping the previous one. */
  run(files, entry) {
    this.stop();
    const frame = document.createElement("iframe");
    frame.setAttribute("sandbox", "allow-scripts");
    frame.setAttribute("referrerpolicy", "no-referrer");
    frame.setAttribute("aria-hidden", "true");
    frame.tabIndex = -1;
    frame.title = "Program sandbox";
    frame.style.cssText = "position:absolute;width:0;height:0;border:0;visibility:hidden";
    this.#listener = ({ source, data }) => {
      if (source !== frame.contentWindow || typeof data !== "object" || data === null) return;
      if (data.type === "ready") {
        frame.contentWindow.postMessage({ type: "run", files, entry: `${PREFIX}${entry}` }, "*");
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
