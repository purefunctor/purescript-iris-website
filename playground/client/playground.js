
import index from "../packages/index.json";
import { TraceMap } from "@jridgewell/trace-mapping";
import { resolveClosure } from "../packages/registry.js";
import { createGeneratedOutput } from "./generated-output.js";
import { LanguageClient } from "./language-client.js";
import { applyDiagnostics, LANGUAGE, registerProviders } from "./monaco-bridge.js";
import { configure, createEditor, monaco } from "./monaco.js";
import { link, Runner } from "./runner.js";
import { stackFrames } from "./source-maps.js";
import { decodeProject, encodeProject, loadSavedProject, saveProject } from "./storage.js";
import { TEMPLATES } from "./templates.js";

const PROJECT = "file:///project/";
const SIDEBAR_OVERLAYS_EDITOR = "(max-width: 720px)";
const MAX_LINES = 1000;
const SIDEBAR_WIDTH_STORAGE_KEY = "iris-playground-sidebar-width";
const PANEL_SIZE_STORAGE_KEY = "iris-playground-panel-size";
const CONSOLE_HEIGHT_STORAGE_KEY = "iris-playground-console-height";
const CORE_OWNERS = ["purescript", "purescript-contrib"];
const CORE_PACKAGES = Object.keys(index.packages).filter((name) => CORE_OWNERS.includes(index.packages[name].owner));
const templatePackages = (template) => [...CORE_PACKAGES, ...template.packages];
const PACKAGES_OF_PROJECTS_SAVED_BEFORE_PACKAGE_CHOICE = TEMPLATES.flatMap(templatePackages);
const EMBEDDED_EDITOR = {
  fontSize: 13,
  lineHeight: 20,
  lineNumbersMinChars: 2,
  lineDecorationsWidth: 10,
  folding: false,
  overviewRulerLanes: 0,
  hideCursorInOverviewRuler: true,
  wordWrap: "on",
  tabFocusMode: true,
  padding: { top: 10, bottom: 10 },
};


export async function createPlayground({ editor: host, generated: generatedHost, frames, theme, embedded, onChange }) {
  const query = new URLSearchParams(location.search);
  const shared = await decodeProject(location.hash).catch(() => null);
  const project = shared ?? (embedded ? null : loadSavedProject()) ?? { files: TEMPLATES[0].files, packages: templatePackages(TEMPLATES[0]), template: TEMPLATES[0].id };
  const sidebarOverlaysEditor = embedded ? "all" : SIDEBAR_OVERLAYS_EDITOR;
  if (shared) history.replaceState(null, "", location.pathname + location.search);

  const paths = project.files.map(({ path }) => path);
  const listed = (project.open ?? paths).filter((path) => paths.includes(path));
  const open = embedded && listed.length === 0 ? [paths.includes("src/Main.purs") ? "src/Main.purs" : paths[0]] : listed;
  const active = open.includes(project.active) ? project.active : open[0] ?? null;
  let activated = (project.packages ?? PACKAGES_OF_PROJECTS_SAVED_BEFORE_PACKAGE_CHOICE).filter((name, at, names) => index.packages[name] && names.indexOf(name) === at);
  let installed = new Set();
  const preference = (action) => (embedded ? null : ifStorageAvailable(action));
  const panelSize = preference(() => JSON.parse(localStorage.getItem(PANEL_SIZE_STORAGE_KEY))) ?? {};
  let state = {
    phase: "loading",
    files: paths.map((path) => ({ path, errors: 0, warnings: 0 })),
    open,
    active,
    viewing: null,
    sidebar: !matchMedia(sidebarOverlaysEditor).matches,
    sidebarWidth: Number(preference(() => localStorage.getItem(SIDEBAR_WIDTH_STORAGE_KEY))) || 240,
    panel: true,
    panelWidth: Number(panelSize.width) || 380,
    panelHeight: Number(panelSize.height) || Math.round(innerHeight * 0.4),
    panelTab: "output",
    console: true,
    consoleHeight: Number(preference(() => localStorage.getItem(CONSOLE_HEIGHT_STORAGE_KEY))) || 0,
    server: { kind: null, version: null, revision: null, status: "starting", message: null },
    packages: { available: [], active: 0, packageSet: index.packageSet.version, loaded: 0, total: 0, bytes: 0, totalBytes: 0 },
    run: { status: "idle", lines: [], view: false },
    sourceMaps: true,
    outputStale: false,
    generated: { status: "idle", message: "Open a PureScript file to see its JavaScript.", mapped: false },
    templates: TEMPLATES.map(({ id, name, description }) => ({ id, name, description })),
    shared: false,
    template: project.template ?? null,
  };
  const setState = (update) => {
    state = { ...state, ...update(state) };
    onChange(state);
    syncGenerated();
  };

  configure(theme);
  let editor = null;
  let generated = null;
  let projectRevision = 0;
  let runGeneration = 0;
  let runMaps = new Map();
  let generatedShown = null;
  const models = new Map();
  let providers = null;
  let saveTimer;

  const changed = () => {
    projectRevision++;
    generated?.invalidate();
    setState(() => ({ outputStale: true }));
  };
  const syncGenerated = () => {
    if (!generated) return;
    const show = state.panel && state.panelTab === "javascript" && state.server.status === "ready";
    const key = `${show} ${state.sourceMaps}`;
    if (key === generatedShown) return;
    generatedShown = key;
    generated.update(show, state.sourceMaps);
  };

  const uriOf = (path) => `${PROJECT}${path}`;
  const framesOf = (text, sourceMaps) => {
    const frames = stackFrames(text, runMaps, sourceMaps);
    if (!embedded) return frames;
    return frames.map((frame) => (models.has(frame.uri.slice(PROJECT.length)) && frame.uri.startsWith(PROJECT) ? frame : { ...frame, mapped: false }));
  };
  const save = () => {
    clearTimeout(saveTimer);
    if (embedded) return;
    saveTimer = setTimeout(() => saveProject(snapshot()), 400);
  };
  const snapshot = () => ({
    files: state.files.map(({ path }) => ({ path, text: models.get(path).getValue() })),
    open: state.open,
    active: state.active,
    packages: activated,
  });

  const activePackages = () => resolveClosure(index, activated).map(({ name }) => name);
  const publishPackages = () => {
    const active = activePackages();
    const loaded = new Set(active);
    const dependents = new Map(active.map((name) => [name, []]));
    for (const name of active) {
      for (const dependency of index.packages[name].dependencies) dependents.get(dependency).push(name);
    }
    const canDeactivate = (name) => activated.includes(name) && dependents.get(name).length === 0;
    const statusOf = (name) =>
      !loaded.has(name)
        ? installed.has(name) ? "installed" : "available"
        : canDeactivate(name) ? "active" : "dependency";
    const available = Object.entries(index.packages).map(([name, { version }]) => ({
      name,
      version,
      status: statusOf(name),
      requiredBy: (dependents.get(name) ?? []).join(", "),
    }));
    setState((current) => ({ packages: { ...current.packages, available, active: active.length } }));
  };

  const client = new LanguageClient({
    createWorker: () => new Worker(new URL("./worker.js", import.meta.url), { type: "module", name: "iris-language-server" }),
    server: query.get("server") === "mock" ? "mock" : "auto",
    handlers: {
      onStatus: ({ status, server, message }) => {
        setState((current) => ({
          phase: current.phase === "ready" ? "ready" : status === "failed" ? "failed" : "loading",
          server: { ...current.server, ...(server ?? {}), status, message: message ?? null },
        }));
        if (status !== "ready") generated?.invalidate();
      },
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
      onRestart: () => {
        openEveryDocument();
        generated?.invalidate();
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

  const openEveryDocument = () => {
    for (const [path, model] of models) openDocument(path, model);
  };

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
      changed();
      save();
    });
    models.set(path, model);
    return model;
  };

  const removeModel = (path) => {
    changed();
    const model = models.get(path);
    models.delete(path);
    client.notify("textDocument/didClose", { textDocument: { uri: uriOf(path) } });
    monaco.editor.setModelMarkers(model, "iris", []);
    model.dispose();
  };

  const ensureModel = async (uri) => {
    const parsed = monaco.Uri.parse(uri);
    if (monaco.editor.getModel(parsed)) return;
    const text = await client.readSource(uri);
    if (text === null || monaco.editor.getModel(parsed)) return;
    monaco.editor.createModel(text, LANGUAGE, parsed);
  };

  const show = (path) => {
    if (!editor) return;
    editor.updateOptions({ readOnly: false });
    editor.setModel(models.get(path) ?? null);
  };

  const view = (uri, selection) => {
    const model = monaco.editor.getModel(monaco.Uri.parse(uri));
    if (!model || (embedded && !uri.startsWith(PROJECT) && model !== editor.getModel())) return false;
    if (uri.startsWith(PROJECT)) {
      openFile(uri.slice(PROJECT.length));
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

  let serverWork = Promise.resolve();
  let serverPackageList = null;
  const serially = (action) => (serverWork = serverWork.then(action));

  const createEditorView = () => {
    editor = createEditor(host, { model: null, ...(embedded ? EMBEDDED_EDITOR : {}) });
    generated = createGeneratedOutput({
      host: generatedHost,
      source: editor,
      client,
      onChange: (generated) => setState(() => ({ generated })),
    });
    monaco.editor.registerEditorOpener({
      openCodeEditor: (_source, resource, selection) => view(resource.toString(), selection),
    });
    providers = registerProviders({ client: () => client, ensureModel, capabilities: client.capabilities });
    show(state.active);
    if (embedded) revealMain();
  };

  const revealMain = () => {
    const main = editor.getModel()?.findNextMatch("^main\\b", { lineNumber: 1, column: 1 }, true, true, null, false);
    if (!main) return;
    const lowest = editor.getScrollHeight() - editor.getLayoutInfo().height;
    let line = main.range.startLineNumber;
    while (line > 1 && editor.getTopForLineNumber(line) > lowest) line--;
    editor.setPosition({ lineNumber: main.range.startLineNumber, column: 1 });
    editor.setScrollTop(editor.getTopForLineNumber(line));
  };

  const start = () => serially(async () => {
    setState((current) => ({ phase: current.phase === "ready" ? "ready" : "loading" }));
    const names = activePackages();
    const info = await client.start(names);
    if (!info) return;
    serverPackageList = names.join();
    installed = new Set(info.installed);
    publishPackages();
    openEveryDocument();
    const first = !editor;
    if (first) createEditorView();
    setState(() => ({ phase: "ready" }));
    if (first && embedded) run();
  });

  const activate = (packages) => {
    changed();
    activated = packages;
    save();
    publishPackages();
    serially(async () => {
      const names = activePackages();
      if (serverPackageList === null || (names.join() === serverPackageList && state.server.status !== "failed")) return;
      const info = await client.restart(names);
      if (!info) return;
      serverPackageList = names.join();
      installed = new Set(info.installed);
      publishPackages();
    });
  };

  const openFile = (path) => {
    if (!models.has(path)) return;
    show(path);
    setState((current) => ({
      open: current.open.includes(path) ? current.open : [...current.open, path],
      active: path,
      viewing: null,
      sidebar: current.sidebar && !matchMedia(sidebarOverlaysEditor).matches,
    }));
    save();
  };

  const closeFile = (path) => {
    const index = state.open.indexOf(path);
    if (index === -1) return;
    const open = state.open.filter((other) => other !== path);
    const active = state.active === path ? open[Math.max(0, index - 1)] ?? null : state.active;
    if (!state.viewing) show(active);
    setState(() => ({ open, active }));
    save();
  };

  let templateLoads = 0;
  const loadTemplate = (id) => {
    const template = TEMPLATES.find((candidate) => candidate.id === id);
    if (!template) return;
    if (embedded && id === state.template && state.server.status !== "failed") return setState((current) => ({ sidebar: current.sidebar && !matchMedia(sidebarOverlaysEditor).matches }));
    runGeneration++;
    runner.stop();
    runMaps = new Map();
    for (const path of [...models.keys()]) removeModel(path);
    for (const file of template.files) openDocument(file.path, addModel(file.path, file.text));
    const paths = template.files.map(({ path }) => path);
    setState((current) => ({
      files: paths.map((path) => ({ path, errors: 0, warnings: 0 })),
      open: paths,
      active: paths[0],
      viewing: null,
      sidebar: current.sidebar && !matchMedia(sidebarOverlaysEditor).matches,
      run: { status: "idle", lines: [], view: false },
      template: id,
    }));
    show(paths[0]);
    activate(templatePackages(template));
    if (embedded) {
      revealMain();
      const load = ++templateLoads;
      serially(() => {
        if (load !== templateLoads) return;
        if (state.server.status === "ready") return run();
        const text = `Could not start the language server for ${template.name}: ${state.server.message ?? "unknown error"}. Pick the example again to retry.`;
        setState(() => ({
          run: { status: "failed", lines: [{ kind: "error", text }], view: false },
          outputStale: false,
        }));
      });
    }
  };

  const run = async () => {
    const generation = ++runGeneration;
    const revision = projectRevision;
    runner.stop();
    runMaps = new Map();
    setState(() => ({
      run: { status: "compiling", lines: [], view: false },
      outputStale: false,
      panel: true,
      panelTab: "output",
    }));
    try {
      const emitted = await client.request("iris/emit", {});
      if (generation !== runGeneration) return;
      if (emitted.status === "failed") {
        const lines = emitted.errors.map(({ uri, diagnostic }) => ({
          kind: "error",
          text: `${uri.replace(PROJECT, "")}:${diagnostic.range.start.line + 1}:${diagnostic.range.start.character + 1}  ${diagnostic.message}`,
        }));
        return setState(() => ({ run: { status: "failed", lines, view: false } }));
      }
      const entry =
        emitted.modules.find((module) => module.name === "Main") ??
        emitted.modules.find((module) => module.uri === uriOf(state.active)) ??
        emitted.modules[0];
      if (!entry) {
        return setState(() => ({
          run: { status: "failed", lines: [{ kind: "error", text: "There is no module to run." }], view: false },
        }));
      }
      const linked = await link(emitted.files);
      if (generation !== runGeneration) return;
      if (revision !== projectRevision) {
        return setState(() => ({ run: { status: "failed", lines: [{ kind: "info", text: "The project changed while compiling. Run it again." }], view: false } }));
      }
      if (linked.missing.length > 0) {
        const lines = linked.missing.map((specifier) => ({
          kind: "error",
          text: `The playground cannot load ${specifier}, which an FFI module imports.`,
        }));
        return setState(() => ({ run: { status: "failed", lines, view: false } }));
      }
      runMaps = new Map(Object.entries(linked.maps ?? {}).map(([path, map]) => [path, new TraceMap(map)]));
      setState(() => ({ run: { status: "running", lines: [], view: false } }));
      runner.run(linked.files, entry.path, linked.css);
    } catch (error) {
      if (generation !== runGeneration) return;
      setState(() => ({ run: { status: "failed", lines: [{ kind: "error", text: error.message }], view: false } }));
    }
  };

  const runner = new Runner(frames, (event) => {
    setState((current) => {
      if (event.type === "view") return { run: { ...current.run, view: true }, panel: true, panelTab: "output" };
      if (event.type === "done") return { run: { ...current.run, status: "done" } };
      const kind = event.type === "error" || event.level === "error" ? "error" : event.level === "warn" ? "warning" : "log";
      const frames = /iris-playground:\/\/\//.test(event.text) ? framesOf(event.text, current.sourceMaps) : null;
      const lines = [...current.run.lines, { kind, text: event.text, frames }].slice(-MAX_LINES);
      return { run: { ...current.run, status: event.type === "error" ? "failed" : current.run.status, lines } };
    });
  });

  const actions = {
    openFile,
    closeFile,
    closeViewer: () => {
      show(state.active);
      setState(() => ({ viewing: null }));
    },
    toggleSidebar: () => setState((current) => ({ sidebar: !current.sidebar })),
    resizeSidebar: (width) => {
      preference(() => localStorage.setItem(SIDEBAR_WIDTH_STORAGE_KEY, String(width)));
      setState(() => ({ sidebar: true, sidebarWidth: width }));
    },
    closeSidebar: () => setState(() => ({ sidebar: false })),
    togglePanel: () => setState((current) => ({ panel: !current.panel })),
    resizePanel: ({ width, height }) => {
      preference(() => localStorage.setItem(PANEL_SIZE_STORAGE_KEY, JSON.stringify({ width, height })));
      setState(() => ({ panel: true, panelWidth: width, panelHeight: height }));
    },
    closePanel: () => setState(() => ({ panel: false })),
    selectPanelTab: (tab) => setState(() => ({ panelTab: tab })),
    toggleSourceMaps: () =>
      setState((current) => {
        const sourceMaps = !current.sourceMaps;
        const lines = current.run.lines.map((line) =>
          line.frames ? { ...line, frames: framesOf(line.text, sourceMaps) } : line,
        );
        return { sourceMaps, run: { ...current.run, lines } };
      }),
    openFrame: async ({ uri, line, column }) => {
      if (!uri || state.outputStale) return;
      const revision = projectRevision;
      await ensureModel(uri);
      if (revision !== projectRevision) return;
      view(uri, { lineNumber: line, column });
    },
    resizeConsole: (height) => {
      preference(() => localStorage.setItem(CONSOLE_HEIGHT_STORAGE_KEY, String(height)));
      setState(() => ({ console: true, consoleHeight: height }));
    },
    toggleConsole: () => setState((current) => ({ console: !current.console })),
    closeConsole: () => setState(() => ({ console: false })),
    createFile: () => {
      let index = 1;
      while (models.has(`src/Module${index}.purs`)) index += 1;
      const path = `src/Module${index}.purs`;
      const model = addModel(path, `module Module${index} where\n\nimport Prelude\n\n`);
      openDocument(path, model);
      changed();
      setState((current) => ({ files: [...current.files, { path, errors: 0, warnings: 0 }] }));
      openFile(path);
      return path;
    },
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
        open: current.open.map((path) => (path === from ? target : path)),
        active: current.active === from ? target : current.active,
      }));
      if (state.active === target) show(target);
      save();
      return null;
    },
    deleteFile: (path) => {
      if (!models.has(path) || models.size === 1) return;
      removeModel(path);
      const index = state.open.indexOf(path);
      const open = state.open.filter((other) => other !== path);
      const active = state.active === path ? open[Math.max(0, index - 1)] ?? null : state.active;
      setState((current) => ({ files: current.files.filter((file) => file.path !== path), open, active }));
      if (!state.viewing) show(active);
      save();
    },
    run,
    stop: () => {
      runGeneration++;
      runner.stop();
      setState((current) => ({
        run: { status: "stopped", lines: [...current.run.lines, { kind: "info", text: "Stopped" }], view: false },
      }));
    },
    clearOutput: () => setState((current) => ({ run: { ...current.run, lines: [] } })),
    share: async () => {
      const url = `${location.origin}${location.pathname}${await encodeProject(snapshot())}`;
      await navigator.clipboard.writeText(url).catch(() => {});
      history.replaceState(null, "", url);
      setState(() => ({ shared: true }));
      setTimeout(() => setState(() => ({ shared: false })), 2500);
    },
    openFullPlayground: async () => {
      const opened = window.open("", "_blank");
      const url = `/playground/${await encodeProject(snapshot())}`;
      if (!opened) return window.open(url, "_blank", "noopener");
      opened.location.href = url;
      opened.opener = null;
    },
    loadTemplate,
    activatePackage: (name) => activate([...activated, name]),
    deactivatePackage: (name) => activate(activated.filter((other) => other !== name)),
    reset: () => loadTemplate(TEMPLATES[0].id),
    retry: () => {
      start();
    },
  };

  start();

  return {
    actions,
    dispose: () => {
      runGeneration++;
      clearTimeout(saveTimer);
      runner.stop();
      generated?.dispose();
      providers?.dispose();
      client.dispose();
      editor?.dispose();
      for (const model of monaco.editor.getModels()) model.dispose();
    },
  };
}

function ifStorageAvailable(action) {
  try {
    return action();
  } catch {
    return null;
  }
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

function renameModuleHeader(text, from, to) {
  if (!from.endsWith(".purs")) return text;
  const name = (path) => path.slice("src/".length, -".purs".length).replaceAll("/", ".");
  const header = new RegExp(`^(\\s*module\\s+)${name(from).replaceAll(".", "\\.")}\\b`, "m");
  return text.replace(header, `$1${name(to)}`);
}
