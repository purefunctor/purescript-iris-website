import { createEditor, monaco } from "./monaco.js";
import { mappingIndex, matchingSegments } from "./source-maps.js";

const NO_MODULE = "Open a PureScript file to see its JavaScript.";
const DEBOUNCE = 300;

export function createGeneratedOutput({ host, source, client, onChange }) {
  const model = monaco.editor.createModel("", "javascript");
  const editor = createEditor(host, {
    model,
    readOnly: true,
    wordWrap: "off",
    ariaLabel: "Generated JavaScript",
    occurrencesHighlight: "off",
    selectionHighlight: false,
    renderLineHighlight: "none",
  });
  const panes = [
    ["source", source],
    ["generated", editor],
  ];
  const sourceLines = source.createDecorationsCollection();
  const generatedSpans = editor.createDecorationsCollection();
  const pinnedKeys = panes.map(([, pane]) => pane.createContextKey("irisSourceMapPinned", false));

  let state = { status: "idle", message: NO_MODULE, mapped: false };
  let pinned = false;
  let segments = [];
  let uri = "";
  let visible = false;
  let enabled = true;
  let revision = 0;
  let requesting = false;
  let disposed = false;
  let timer;
  let hoverFrame;

  const linked = () => visible && enabled && state.status === "ready" && segments.length > 0;

  const publish = (update) => {
    state = { ...state, ...update };
    if (update.status !== undefined) source.updateOptions({ hover: { enabled: !linked() } });
    onChange(state);
  };

  const pin = (value) => {
    pinned = value;
    for (const key of pinnedKeys) key.set(value);
  };

  const clear = () => {
    sourceLines.clear();
    generatedSpans.clear();
    pin(false);
  };

  const highlight = (matches, { pinning = false, reveal = false } = {}) => {
    if (!linked()) return;
    const lines = new Set(matches.map((segment) => segment.sourceLine));
    sourceLines.set(
      [...lines].map((line) => ({
        range: new monaco.Range(line, 1, line, 1),
        options: { isWholeLine: true, className: "iris-map-line" },
      })),
    );
    generatedSpans.set(
      matches
        .filter((segment) => segment.end > segment.start)
        .map((segment) => ({
          range: new monaco.Range(segment.line, segment.start, segment.line, segment.end),
          options: { inlineClassName: "iris-map-span" },
        })),
    );
    const [first] = matches;
    pin(pinning && first !== undefined);
    if (reveal && first) {
      source.revealLineInCenterIfOutsideViewport(first.sourceLine);
      editor.revealRangeInCenterIfOutsideViewport(
        new monaco.Range(first.line, first.start, first.line, Math.max(first.end, first.start)),
      );
    }
  };

  const refresh = async () => {
    if (disposed || requesting || !visible) return;
    const current = source.getModel()?.uri.toString() ?? "";
    if (current !== uri) {
      uri = current;
      model.setValue("");
      segments = [];
      publish({ mapped: false });
    }
    if (!uri.endsWith(".purs")) {
      publish({ status: "idle", message: NO_MODULE });
      return;
    }
    const requested = revision;
    const shown = model.getValue() !== "";
    requesting = true;
    publish({ status: "loading", message: shown ? "Updating · previous output shown" : "Compiling JavaScript…" });
    try {
      const result = await client.request("iris/generated", { uri });
      if (disposed || revision !== requested) return;
      if (result.status !== "generated") {
        publish({
          status: "stale",
          mapped: false,
          message: shown
            ? "Last successful output · fix compiler errors to update"
            : "Fix compiler errors to see JavaScript.",
        });
        return;
      }
      model.setValue(result.text);
      segments = result.map
        ? mappingIndex(result.map, result.text).segments.filter((segment) => segment.source === uri)
        : [];
      publish({
        status: "ready",
        mapped: segments.length > 0,
        message: segments.length > 0 ? "" : "Source maps are unavailable for this output.",
      });
    } catch (error) {
      if (disposed || revision !== requested) return;
      publish({
        status: "unavailable",
        mapped: false,
        message:
          error.code === -32601
            ? "This language server does not support JavaScript inspection."
            : `Could not generate JavaScript: ${error.message}`,
      });
    } finally {
      requesting = false;
      if (!disposed && revision !== requested) schedule();
    }
  };

  const schedule = () => {
    clearTimeout(timer);
    if (visible && !disposed) timer = setTimeout(refresh, DEBOUNCE);
  };

  const invalidate = () => {
    revision++;
    cancelAnimationFrame(hoverFrame);
    clear();
    publish({ status: "stale", mapped: false, message: "Source changed · mappings paused until compilation finishes" });
    schedule();
  };

  const subscriptions = [source.onDidChangeModel(invalidate)];
  for (const [side, pane] of panes) {
    subscriptions.push(
      pane.onMouseMove(({ target }) => {
        if (pinned || !linked()) return;
        cancelAnimationFrame(hoverFrame);
        hoverFrame = requestAnimationFrame(() => {
          if (pinned || !linked()) return;
          const position = target.type === monaco.editor.MouseTargetType.CONTENT_TEXT ? target.position : null;
          const point = position && monaco.Range.fromPositions(position);
          highlight(point ? matchingSegments(segments, side, point) : []);
        });
      }),
      pane.onMouseLeave(() => {
        cancelAnimationFrame(hoverFrame);
        if (!pinned) clear();
      }),
      pane.onDidChangeCursorSelection(({ selection, source: cause }) => {
        if (cause === "api" || !linked()) return;
        cancelAnimationFrame(hoverFrame);
        highlight(matchingSegments(segments, side, selection), { pinning: true, reveal: true });
      }),
      pane.addAction({
        id: "iris.clearSourceMap",
        label: "Clear source map highlight",
        keybindings: [monaco.KeyCode.Escape],
        precondition: "irisSourceMapPinned",
        run: clear,
      }),
    );
  }
  onChange(state);

  return {
    invalidate,
    update(show, mapsEnabled) {
      const opened = show && !visible;
      visible = show;
      enabled = mapsEnabled;
      host.inert = !visible;
      const linking = visible && enabled;
      source.updateOptions({
        occurrencesHighlight: linking ? "off" : "singleFile",
        selectionHighlight: !linking,
        hover: { enabled: !linked() },
      });
      if (!linking) {
        cancelAnimationFrame(hoverFrame);
        clear();
      }
      if (opened) refresh();
    },
    dispose() {
      disposed = true;
      clearTimeout(timer);
      cancelAnimationFrame(hoverFrame);
      for (const subscription of subscriptions) subscription.dispose();
      sourceLines.clear();
      editor.dispose();
      model.dispose();
    },
  };
}
