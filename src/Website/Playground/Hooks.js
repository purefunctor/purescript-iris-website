import { atom, useAtom, useAtomValue } from "jotai";
import { useEffect, useLayoutEffect, useMemo, useRef } from "react";

const initialState = {
  phase: "loading",
  files: [],
  open: [],
  active: null,
  viewing: null,
  sidebar: false,
  sidebarWidth: 240,
  panel: true,
  panelWidth: 380,
  panelHeight: 320,
  panelTab: "output",
  console: true,
  consoleHeight: 0,
  server: { kind: null, version: null, revision: null, status: "starting", message: null },
  packages: { available: [], active: 0, packageSet: null, loaded: 0, total: 0, bytes: 0, totalBytes: 0 },
  run: { status: "idle", lines: [], view: false },
  sourceMaps: true,
  outputStale: false,
  generated: { status: "idle", message: "", mapped: false },
  templates: [],
  shared: false,
};

const stateAtom = atom(initialState);

export const usePlaygroundImpl = (theme) => () => {
  const editor = useRef(null);
  const generated = useRef(null);
  const frames = useRef(null);
  const controller = useRef(null);
  const [state, setState] = useAtom(stateAtom);

  useEffect(() => {
    let disposed = false;
    let instance;
    import("#playground/client/playground.js")
      .then(({ createPlayground }) =>
        createPlayground({
          editor: editor.current,
          generated: generated.current,
          frames: frames.current,
          theme,
          onChange: setState,
        }),
      )
      .then((created) => {
        instance = created;
        if (disposed) instance.dispose();
        else controller.current = instance;
      })
      .catch((error) => {
        console.error(error);
        setState((current) => ({
          ...current,
          phase: "failed",
          server: { ...current.server, status: "failed", message: String(error?.message ?? error) },
        }));
      });
    return () => {
      disposed = true;
      instance?.dispose();
      controller.current = null;
    };
  }, []);

  const actions = useMemo(() => {
    const call = (name, ...args) => controller.current?.actions[name](...args);
    return {
      openFile: (path) => () => call("openFile", path),
      closeFile: (path) => () => call("closeFile", path),
      closeViewer: () => call("closeViewer"),
      toggleSidebar: () => call("toggleSidebar"),
      resizeSidebar: (width) => () => call("resizeSidebar", width),
      closeSidebar: () => call("closeSidebar"),
      togglePanel: () => call("togglePanel"),
      resizePanel: (size) => () => call("resizePanel", size),
      closePanel: () => call("closePanel"),
      selectPanelTab: (tab) => () => call("selectPanelTab", tab),
      toggleSourceMaps: () => call("toggleSourceMaps"),
      openFrame: (frame) => () => call("openFrame", frame),
      toggleConsole: () => call("toggleConsole"),
      resizeConsole: (height) => () => call("resizeConsole", height),
      closeConsole: () => call("closeConsole"),
      createFile: () => call("createFile"),
      renameFile: (from) => (to) => () => call("renameFile", from, to) ?? null,
      deleteFile: (path) => () => call("deleteFile", path),
      run: () => call("run"),
      stop: () => call("stop"),
      clearOutput: () => call("clearOutput"),
      share: () => call("share"),
      loadTemplate: (id) => () => call("loadTemplate", id),
      activatePackage: (name) => () => call("activatePackage", name),
      deactivatePackage: (name) => () => call("deactivatePackage", name),
      reset: () => call("reset"),
      retry: () => {
        const pageFailedToLoad = !controller.current;
        return pageFailedToLoad ? location.reload() : call("retry");
      },
    };
  }, []);

  return { state, actions, editor, generated, frames };
};

export const useTabListOverflowImpl = (selected) => () => {
  const tabList = useRef(null);
  useLayoutEffect(() => {
    const list = tabList.current;
    if (!list) return undefined;
    const mark = () => {
      const start = list.scrollLeft > 1;
      const end = list.scrollLeft + list.clientWidth < list.scrollWidth - 1;
      if (start && end) list.dataset.overflow = "both";
      else if (start) list.dataset.overflow = "start";
      else if (end) list.dataset.overflow = "end";
      else delete list.dataset.overflow;
    };
    const wheel = (event) => {
      if (Math.abs(event.deltaY) > Math.abs(event.deltaX)) list.scrollLeft += event.deltaY;
    };
    mark();
    const observer = new ResizeObserver(mark);
    observer.observe(list);
    list.addEventListener("scroll", mark, { passive: true });
    list.addEventListener("wheel", wheel, { passive: true });
    return () => {
      observer.disconnect();
      list.removeEventListener("scroll", mark);
      list.removeEventListener("wheel", wheel);
    };
  }, []);
  useEffect(() => {
    tabList.current
      ?.querySelector("[data-selected]")
      ?.scrollIntoView({ block: "nearest", inline: "nearest" });
  }, [selected]);
  return tabList;
};

export const useFrameSlotImpl = (frames) => () => {
  const slot = useRef(null);
  useLayoutEffect(() => {
    const container = frames.current;
    const element = slot.current;
    if (!container || !element) return undefined;
    const place = () => {
      const outer = container.parentElement.getBoundingClientRect();
      const inner = element.getBoundingClientRect();
      container.style.insetInlineStart = `${inner.left - outer.left}px`;
      container.style.insetBlockStart = `${inner.top - outer.top}px`;
      container.style.width = `${inner.width}px`;
      container.style.height = `${inner.height}px`;
    };
    place();
    const observer = new ResizeObserver(place);
    observer.observe(element);
    observer.observe(container.parentElement);
    let frame = 0;
    const followSlotWhilePanelAnimates = () => {
      place();
      frame = requestAnimationFrame(followSlotWhilePanelAnimates);
    };
    const onPanelAnimation = (event) => {
      if (!event.target.contains(element)) return;
      cancelAnimationFrame(frame);
      if (event.type === "animationstart") followSlotWhilePanelAnimates();
      else place();
    };
    const events = ["animationstart", "animationend", "animationcancel"];
    for (const type of events) container.parentElement.addEventListener(type, onPanelAnimation);
    return () => {
      cancelAnimationFrame(frame);
      for (const type of events) container.parentElement.removeEventListener(type, onPanelAnimation);
      observer.disconnect();
      for (const property of ["inset-inline-start", "inset-block-start", "width", "height"]) {
        container.style.removeProperty(property);
      }
    };
  }, [frames]);
  return slot;
};

const reducedMotion = () => matchMedia("(prefers-reduced-motion: reduce)").matches;

const SETTLE_WITHOUT_ANIMATION_END = 400;

function usePresence(open, animate) {
  const phaseAtom = useMemo(() => atom(open ? "open" : "closed"), []);
  const [phase, setPhase] = useAtom(phaseAtom);
  useLayoutEffect(() => {
    const moving = animate && !reducedMotion();
    setPhase((current) => {
      if (open) return current === "closed" || current === "exiting" ? (moving ? "entering" : "open") : current;
      return current === "closed" ? current : moving ? "exiting" : "closed";
    });
  }, [open, animate]);
  useEffect(() => {
    if (phase !== "entering" && phase !== "exiting") return undefined;
    const timeout = setTimeout(() => setPhase((current) => settled(current)), SETTLE_WITHOUT_ANIMATION_END);
    return () => clearTimeout(timeout);
  }, [phase]);
  return {
    rendered: phase !== "closed",
    props: {
      "data-entering": phase === "entering" || null,
      "data-exiting": phase === "exiting" || null,
      onAnimationEnd: (event) => {
        if (event.target === event.currentTarget) setPhase(settled);
      },
    },
  };
}

const settled = (phase) => (phase === "exiting" ? "closed" : phase === "entering" ? "open" : phase);

const KEYBOARD_RESIZE_STEP = 16;

function keepDragCursorAndIgnoreFrames(cursor) {
  if (cursor) document.documentElement.style.cursor = cursor;
  else document.documentElement.style.removeProperty("cursor");
  for (const frame of document.querySelectorAll("iframe")) {
    if (cursor) frame.style.pointerEvents = "none";
    else frame.style.removeProperty("pointer-events");
  }
}
const SHRINK_KEY_FOR_GROW_KEY = { ArrowRight: "ArrowLeft", ArrowLeft: "ArrowRight", ArrowUp: "ArrowDown", ArrowDown: "ArrowUp" };

export const useResizableImpl = ({ id, label, open, size, min, max, collapse, vertical, fromEnd, share, resize, close }) => () => {
  const dragAtom = useMemo(() => atom(null), []);
  const [drag, setDrag] = useAtom(dragAtom);
  const shown = drag ? drag.open : open;
  const current = drag ? drag.size : size;
  const presence = usePresence(shown, !drag);
  const limit = (value, most = max) => Math.min(most, Math.max(min, Math.round(value)));
  const growKey = vertical ? (fromEnd ? "ArrowUp" : "ArrowDown") : fromEnd ? "ArrowLeft" : "ArrowRight";

  const end = () => {
    if (!drag) return;
    keepDragCursorAndIgnoreFrames(null);
    setDrag(null);
    if (drag.open) resize(drag.size)();
    else close();
  };
  const onKeyDown = (event) => {
    if (event.key === SHRINK_KEY_FOR_GROW_KEY[growKey] && open) {
      if (size - KEYBOARD_RESIZE_STEP < min) close();
      else resize(size - KEYBOARD_RESIZE_STEP)();
    } else if (event.key === growKey) {
      resize(open ? limit(size + KEYBOARD_RESIZE_STEP) : size)();
    } else if (event.key === "Enter") {
      if (open) close();
      else resize(size)();
    } else {
      return;
    }
    event.preventDefault();
  };

  return {
    shown,
    current,
    rendered: presence.rendered,
    presenceProps: presence.props,
    handleProps: {
      "aria-controls": id,
      "aria-label": label,
      "aria-orientation": vertical ? "horizontal" : "vertical",
      "aria-valuemax": max,
      "aria-valuemin": 0,
      "aria-valuenow": shown ? current : 0,
      "aria-valuetext": shown ? `${current} pixels` : "Closed",
      "data-dragging": drag ? true : null,
      onKeyDown,
      onLostPointerCapture: end,
      onPointerDown: (event) => {
        if (event.button !== 0) return;
        event.preventDefault();
        event.currentTarget.setPointerCapture(event.pointerId);
        keepDragCursorAndIgnoreFrames(vertical ? "row-resize" : "col-resize");
        setDrag({ bounds: event.currentTarget.parentElement.getBoundingClientRect(), size, open });
      },
      onPointerMove: (event) => {
        if (!drag) return;
        const { bounds } = drag;
        const raw = vertical
          ? fromEnd ? bounds.bottom - event.clientY : event.clientY - bounds.top
          : fromEnd ? bounds.right - event.clientX : event.clientX - bounds.left;
        const opened = raw >= collapse;
        const most = Math.min(max, (vertical ? bounds.height : bounds.width) * share);
        setDrag({ ...drag, open: opened, size: opened ? limit(raw, most) : drag.size });
      },
      role: "separator",
      tabIndex: 0,
    },
  };
};

function mediaQueryAtom(query) {
  const changed = atom(null);
  changed.onMount = (set) => {
    const list = matchMedia(query);
    const update = () => set(list.matches);
    update();
    list.addEventListener("change", update);
    return () => list.removeEventListener("change", update);
  };
  return atom((get) => get(changed) ?? matchMedia(query).matches);
}

const panelBelowEditorAtom = mediaQueryAtom("(max-width: 960px)");

export const usePanelBelowEditorImpl = () => useAtomValue(panelBelowEditorAtom);

export const useFollowOutputImpl = () => {
  const scroller = useRef(null);
  const following = useRef(true);
  const follow = () => {
    const element = scroller.current;
    if (element && following.current) element.scrollTop = element.scrollHeight;
  };
  useLayoutEffect(follow);
  useEffect(() => {
    const observer = new ResizeObserver(follow);
    observer.observe(scroller.current);
    return () => observer.disconnect();
  }, []);
  const onScroll = () => {
    const element = scroller.current;
    following.current = element.scrollHeight - element.scrollTop - element.clientHeight < 2;
  };
  return { scroller, onScroll };
};
