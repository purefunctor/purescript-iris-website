// The playground's controller. It owns the project's files, the editor, the language client and the
// runner, and publishes one plain state object for the UI to render. The UI never sees Monaco or
// LSP: it calls the actions returned by `createPlayground`.
//
// The page starts in the `loading` phase while the worker downloads the package set and loads the
// language server. The editor is created once both are ready, so the first thing it shows is a
// checked project.

import { LanguageClient } from "./language-client.js";
import { applyDiagnostics, LANGUAGE, registerProviders } from "./monaco-bridge.js";
import { configure, createEditor, monaco } from "./monaco.js";
import { link, Runner } from "./runner.js";
import { decodeProject, encodeProject, loadSavedProject, saveProject } from "./storage.js";

const PROJECT = "file:///project/";
const MAX_LINES = 1000;

export const DEFAULT_FILES = [
  {
    path: "src/Main.purs",
    text: `module Main where

import Prelude

import Data.Array (range)
import Data.Foldable (sum)
import Effect (Effect)
import Effect.Console (log)
import Greeting (greet)

main :: Effect Unit
main = do
  log (greet "Iris")
  log ("The sum of 1 to 10 is " <> show (sum (range 1 10)))
`,
  },
  {
    path: "src/Greeting.purs",
    text: `module Greeting (greet) where

import Prelude

greet :: String -> String
greet name = "Hello, " <> name <> "!"
`,
  },
];

/**
 * @param {object} options
 * @param {HTMLElement} options.editor the element Monaco fills
 * @param {HTMLElement} options.frames where program frames live
 * @param {object} options.theme the Monaco theme computed at build time
 * @param {(state: object) => void} options.onChange
 */
export async function createPlayground({ editor: host, frames, theme, onChange }) {
  const query = new URLSearchParams(location.search);
  const shared = await decodeProject(location.hash).catch(() => null);
  const project = shared ?? loadSavedProject() ?? { files: DEFAULT_FILES };
  if (shared) history.replaceState(null, "", location.pathname + location.search);

  let state = {
    phase: "loading",
    files: project.files.map(({ path }) => ({ path, errors: 0, warnings: 0 })),
    active: project.active && project.files.some((file) => file.path === project.active) ? project.active : project.files[0]?.path ?? null,
    viewing: null,
    server: { kind: null, version: null, status: "starting", message: null },
    packages: { available: [], packageSet: null, loaded: 0, total: 0, bytes: 0, totalBytes: 0 },
    run: { status: "idle", lines: [] },
    shared: false,
  };
  const setState = (update) => {
    state = { ...state, ...update(state) };
    onChange(state);
  };

  configure(theme);
  let editor = null;
  const models = new Map();
  let providers = null;
  let saveTimer;

  const uriOf = (path) => `${PROJECT}${path}`;
  const save = () => {
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => saveProject(snapshot()), 400);
  };
  const snapshot = () => ({
    files: state.files.map(({ path }) => ({ path, text: models.get(path).getValue() })),
    active: state.active,
  });

  const client = new LanguageClient({
    createWorker: () => new Worker(new URL("./worker.js", import.meta.url), { type: "module", name: "iris-language-server" }),
    server: query.get("server") === "mock" ? "mock" : "auto",
    handlers: {
      onStatus: ({ status, server, message }) =>
        setState((current) => ({
          phase: current.phase === "ready" ? "ready" : status === "failed" ? "failed" : "loading",
          server: { ...current.server, ...(server ?? {}), status, message: message ?? null },
        })),
      onProgress: ({ packageSet, loaded, total, bytes, totalBytes }) =>
        setState((current) => ({
          packages: { ...current.packages, packageSet, loaded, total, bytes, totalBytes },
        })),
      onNotification: (method, params) => {
        if (method !== "textDocument/publishDiagnostics") return;
        const counts = applyDiagnostics(params);
        setState((current) => ({
          files: current.files.map((file) => (uriOf(file.path) === params.uri ? { ...file, ...counts } : file)),
        }));
      },
      // A restarted server starts empty: open every document again.
      onRestart: () => {
        for (const [path, model] of models) openDocument(path, model);
      },
    },
  });

  const openDocument = (path, model) =>
    client.notify("textDocument/didOpen", {
      textDocument: {
        uri: uriOf(path),
        languageId: path.endsWith(".purs") ? LANGUAGE : "javascript",
        version: model.getVersionId(),
        text: model.getValue(),
      },
    });

  const addModel = (path, text) => {
    const model = monaco.editor.createModel(text, path.endsWith(".purs") ? LANGUAGE : "javascript", monaco.Uri.parse(uriOf(path)));
    model.onDidChangeContent((event) => {
      client.notify("textDocument/didChange", {
        textDocument: { uri: uriOf(path), version: model.getVersionId() },
        contentChanges: event.changes.map((change) => ({
          range: {
            start: { line: change.range.startLineNumber - 1, character: change.range.startColumn - 1 },
            end: { line: change.range.endLineNumber - 1, character: change.range.endColumn - 1 },
          },
          text: change.text,
        })),
      });
      save();
    });
    models.set(path, model);
    return model;
  };

  const removeModel = (path) => {
    const model = models.get(path);
    models.delete(path);
    client.notify("textDocument/didClose", { textDocument: { uri: uriOf(path) } });
    monaco.editor.setModelMarkers(model, "iris", []);
    model.dispose();
  };

  // Read-only models for package and Prim sources, created when navigation reaches them.
  const ensureModel = async (uri) => {
    const parsed = monaco.Uri.parse(uri);
    if (monaco.editor.getModel(parsed)) return;
    const text = await client.readSource(uri);
    if (text === null || monaco.editor.getModel(parsed)) return;
    monaco.editor.createModel(text, LANGUAGE, parsed);
  };

  const show = (path) => {
    const model = models.get(path);
    if (!model || !editor) return;
    editor.updateOptions({ readOnly: false });
    editor.setModel(model);
  };

  const view = (uri, selection) => {
    const model = monaco.editor.getModel(monaco.Uri.parse(uri));
    if (!model) return false;
    if (uri.startsWith(PROJECT)) {
      selectFile(uri.slice(PROJECT.length));
    } else {
      editor.setModel(model);
      editor.updateOptions({ readOnly: true });
      setState(() => ({ viewing: { uri, label: readOnlyLabel(uri) } }));
    }
    if (selection) {
      const range = "startLineNumber" in selection ? selection : new monaco.Range(selection.lineNumber, selection.column, selection.lineNumber, selection.column);
      editor.setSelection(range);
      editor.revealRangeInCenterIfOutsideViewport(range);
    }
    editor.focus();
    return true;
  };

  for (const file of project.files) addModel(file.path, file.text);
  onChange(state);

  // Starts the worker, which downloads the packages and loads the server, then creates the editor
  // the first time it succeeds.
  const start = async () => {
    setState((current) => ({ phase: current.phase === "ready" ? "ready" : "loading" }));
    const info = await client.start();
    if (!info) return;
    setState((current) => ({
      packages: { ...current.packages, available: info.packages, packageSet: info.packageSet },
    }));
    // Documents open before the editor asks for semantic tokens, which it does once per model.
    for (const [path, model] of models) openDocument(path, model);
    if (!editor) {
      editor = createEditor(host, { model: null });
      monaco.editor.registerEditorOpener({
        openCodeEditor: (_source, resource, selection) => view(resource.toString(), selection),
      });
      providers = registerProviders({ client: () => client, ensureModel, capabilities: client.capabilities });
      show(state.active);
    }
    setState(() => ({ phase: "ready" }));
  };

  const selectFile = (path) => {
    if (!models.has(path)) return;
    show(path);
    setState(() => ({ active: path, viewing: null }));
    save();
  };

  const run = async () => {
    setState(() => ({ run: { status: "compiling", lines: [] } }));
    try {
      const emitted = await client.request("iris/emit", {});
      if (emitted.status === "failed") {
        const lines = emitted.errors.map(({ uri, diagnostic }) => ({
          kind: "error",
          text: `${uri.replace(PROJECT, "")}:${diagnostic.range.start.line + 1}:${diagnostic.range.start.character + 1}  ${diagnostic.message}`,
        }));
        return setState(() => ({ run: { status: "failed", lines } }));
      }
      const entry =
        emitted.modules.find((module) => module.name === "Main") ??
        emitted.modules.find((module) => module.uri === uriOf(state.active)) ??
        emitted.modules[0];
      if (!entry) {
        return setState(() => ({ run: { status: "failed", lines: [{ kind: "error", text: "There is no module to run." }] } }));
      }
      const linked = await link(emitted.files);
      if (linked.missing.length > 0) {
        const lines = linked.missing.map((specifier) => ({
          kind: "error",
          text: `The playground cannot load ${specifier}, which an FFI module imports.`,
        }));
        return setState(() => ({ run: { status: "failed", lines } }));
      }
      setState(() => ({ run: { status: "running", lines: [{ kind: "info", text: `Running ${entry.name}.main` }] } }));
      runner.run(linked.files, entry.path);
    } catch (error) {
      setState(() => ({ run: { status: "failed", lines: [{ kind: "error", text: error.message }] } }));
    }
  };

  const runner = new Runner(frames, (event) => {
    setState((current) => {
      if (event.type === "done") return { run: { ...current.run, status: "done" } };
      const kind = event.type === "error" || event.level === "error" ? "error" : event.level === "warn" ? "warning" : "log";
      const lines = [...current.run.lines, { kind, text: event.text }].slice(-MAX_LINES);
      return { run: { ...current.run, status: event.type === "error" ? "failed" : current.run.status, lines } };
    });
  });

  const actions = {
    selectFile,
    closeViewer: () => selectFile(state.active),
    createFile: () => {
      let index = 1;
      while (models.has(`src/Module${index}.purs`)) index += 1;
      const path = `src/Module${index}.purs`;
      const model = addModel(path, `module Module${index} where\n\nimport Prelude\n\n`);
      openDocument(path, model);
      setState((current) => ({ files: [...current.files, { path, errors: 0, warnings: 0 }] }));
      selectFile(path);
      return path;
    },
    /** Returns an error message, or null when the file was renamed. */
    renameFile: (from, to) => {
      const target = to.trim();
      const problem = validatePath(target, from, models);
      if (problem) return problem;
      if (target === from) return null;
      const text = models.get(from).getValue();
      const renamed = renameModuleHeader(text, from, target);
      removeModel(from);
      const model = addModel(target, renamed);
      openDocument(target, model);
      setState((current) => ({
        files: current.files.map((file) => (file.path === from ? { path: target, errors: 0, warnings: 0 } : file)),
        active: current.active === from ? target : current.active,
      }));
      if (state.active === target) show(target);
      save();
      return null;
    },
    deleteFile: (path) => {
      if (!models.has(path) || models.size === 1) return;
      const index = state.files.findIndex((file) => file.path === path);
      removeModel(path);
      const files = state.files.filter((file) => file.path !== path);
      const active = state.active === path ? files[Math.max(0, index - 1)].path : state.active;
      setState(() => ({ files, active }));
      show(active);
      save();
    },
    run,
    stop: () => {
      runner.stop();
      setState((current) => ({
        run: { ...current.run, status: "stopped", lines: [...current.run.lines, { kind: "info", text: "Stopped" }] },
      }));
    },
    clearOutput: () => setState((current) => ({ run: { ...current.run, lines: [] } })),
    share: async () => {
      const url = `${location.origin}${location.pathname}${await encodeProject(snapshot())}`;
      await navigator.clipboard.writeText(url).catch(() => {});
      history.replaceState(null, "", url);
      setState(() => ({ shared: true }));
      setTimeout(() => setState(() => ({ shared: false })), 2000);
    },
    reset: () => {
      for (const path of [...models.keys()]) removeModel(path);
      for (const file of DEFAULT_FILES) openDocument(file.path, addModel(file.path, file.text));
      setState(() => ({
        files: DEFAULT_FILES.map(({ path }) => ({ path, errors: 0, warnings: 0 })),
        active: DEFAULT_FILES[0].path,
        viewing: null,
      }));
      show(DEFAULT_FILES[0].path);
      save();
    },
    retry: () => {
      start();
    },
  };

  start();

  return {
    actions,
    dispose: () => {
      runner.stop();
      providers?.dispose();
      client.dispose();
      editor?.dispose();
      for (const model of monaco.editor.getModels()) model.dispose();
    },
  };
}

function readOnlyLabel(uri) {
  const path = uri.replace(/^file:\/\/\//, "");
  return path.replace(/^packages\/([^/]+)\/src\//, "$1 · ").replace(/^prim\//, "Prim · ");
}

function validatePath(path, from, models) {
  if (!/^src\/([A-Z][\w']*\/)*[A-Z][\w']*\.(purs|js)$/.test(path)) {
    return "Use a path such as src/Data/Example.purs, with capitalized module names.";
  }
  if (from.endsWith(".purs") !== path.endsWith(".purs")) return "Keep the file's extension.";
  if (path !== from && models.has(path)) return `${path} already exists.`;
  return null;
}

/** Updates `module Old.Name` to match a renamed file, when it matched the old name. */
function renameModuleHeader(text, from, to) {
  if (!from.endsWith(".purs")) return text;
  const name = (path) => path.slice("src/".length, -".purs".length).replaceAll("/", ".");
  const header = new RegExp(`^(\\s*module\\s+)${name(from).replaceAll(".", "\\.")}\\b`, "m");
  return text.replace(header, `$1${name(to)}`);
}
