import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { Link } from "react-aria-components/Link";
import { Tab, TabList, TabPanel, Tabs } from "react-aria-components/Tabs";
import { Focusable, Tooltip, TooltipTrigger } from "react-aria-components/Tooltip";
import ExternalLinkIcon from "~icons/lucide/external-link";

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

export function playgroundImpl({ theme, render }) {
  const editor = useRef(null);
  const generated = useRef(null);
  const frames = useRef(null);
  const controller = useRef(null);
  const [state, setState] = useState(initialState);

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
      retry: () => (controller.current ? call("retry") : location.reload()),
    };
  }, []);

  return render({ state, actions, editor, generated, frames });
}

export function panelTabsImpl({
  selected,
  select,
  rootClassName,
  barClassName,
  tabListClassName,
  settingsClassName,
  tabClassName,
  panelClassName,
  switchedPanelClassName,
  badgeClassName,
  output,
  outputAction,
  outputBadge,
  javascript,
  settings,
  packages,
  packagesBadge,
}) {
  const [switched, setSwitched] = useState(false);
  const panelClass = switched ? switchedPanelClassName : panelClassName;
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
  return (
    <Tabs
      className={rootClassName}
      onSelectionChange={(key) => {
        setSwitched(true);
        select(String(key))();
      }}
      selectedKey={selected}
    >
      <div className={barClassName}>
        <TabList aria-label="Playground panels" className={tabListClassName} ref={tabList}>
          <Tab className={tabClassName} id="output">
            Output
            {outputBadge && <span className={badgeClassName}>{outputBadge}</span>}
          </Tab>
          <Tab className={tabClassName} id="javascript">JavaScript</Tab>
          <Tab className={tabClassName} id="packages">
            Packages
            {packagesBadge && <span className={badgeClassName}>{packagesBadge}</span>}
          </Tab>
        </TabList>
        <div className={settingsClassName}>
          {selected === "output" && outputAction}
          {settings}
        </div>
      </div>
      <TabPanel className={panelClass} id="output">
        {output}
      </TabPanel>
      <TabPanel className={panelClass} id="javascript">
        {javascript}
      </TabPanel>
      <TabPanel className={panelClass} id="packages">
        {packages}
      </TabPanel>
    </Tabs>
  );
}

export function outputViewImpl({ frames, className }) {
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
    const follow = () => {
      place();
      frame = requestAnimationFrame(follow);
    };
    const moving = (event) => {
      if (!event.target.contains(element)) return;
      cancelAnimationFrame(frame);
      if (event.type === "animationstart") follow();
      else place();
    };
    const events = ["animationstart", "animationend", "animationcancel"];
    for (const type of events) container.parentElement.addEventListener(type, moving);
    return () => {
      cancelAnimationFrame(frame);
      for (const type of events) container.parentElement.removeEventListener(type, moving);
      observer.disconnect();
      for (const property of ["inset-inline-start", "inset-block-start", "width", "height"]) {
        container.style.removeProperty(property);
      }
    };
  }, [frames]);
  return <div className={className} ref={slot} />;
}

const reducedMotion = () => matchMedia("(prefers-reduced-motion: reduce)").matches;

function usePresence(open, animate) {
  const [phase, setPhase] = useState(open ? "open" : "closed");
  useLayoutEffect(() => {
    const moving = animate && !reducedMotion();
    setPhase((current) => {
      if (open) return current === "closed" || current === "exiting" ? (moving ? "entering" : "open") : current;
      return current === "closed" ? current : moving ? "exiting" : "closed";
    });
  }, [open, animate]);
  useEffect(() => {
    if (phase !== "entering" && phase !== "exiting") return undefined;
    const timeout = setTimeout(() => setPhase((current) => settled(current)), 400);
    return () => clearTimeout(timeout);
  }, [phase]);
  return {
    rendered: phase !== "closed",
    props: {
      "data-entering": phase === "entering" || undefined,
      "data-exiting": phase === "exiting" || undefined,
      onAnimationEnd: (event) => {
        if (event.target === event.currentTarget) setPhase(settled);
      },
    },
  };
}

const settled = (phase) => (phase === "exiting" ? "closed" : phase === "entering" ? "open" : phase);

const STEP = 16;

function dragging(cursor) {
  if (cursor) document.documentElement.style.cursor = cursor;
  else document.documentElement.style.removeProperty("cursor");
  for (const frame of document.querySelectorAll("iframe")) {
    if (cursor) frame.style.pointerEvents = "none";
    else frame.style.removeProperty("pointer-events");
  }
}
const SHRINK = { ArrowRight: "ArrowLeft", ArrowLeft: "ArrowRight", ArrowUp: "ArrowDown", ArrowDown: "ArrowUp" };

function useResizable({ id, label, open, size, min, max, collapse, vertical, fromEnd, share = 1, resize, close }) {
  const [drag, setDrag] = useState(null);
  const shown = drag ? drag.open : open;
  const current = drag ? drag.size : size;
  const presence = usePresence(shown, !drag);
  const limit = (value, most = max) => Math.min(most, Math.max(min, Math.round(value)));
  const grow = vertical ? (fromEnd ? "ArrowUp" : "ArrowDown") : fromEnd ? "ArrowLeft" : "ArrowRight";

  const end = () => {
    if (!drag) return;
    dragging(null);
    setDrag(null);
    if (drag.open) resize(drag.size)();
    else close();
  };
  const onKeyDown = (event) => {
    if (event.key === SHRINK[grow] && open) {
      if (size - STEP < min) close();
      else resize(size - STEP)();
    } else if (event.key === grow) {
      resize(open ? limit(size + STEP) : size)();
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
    presence,
    handleProps: {
      "aria-controls": id,
      "aria-label": label,
      "aria-orientation": vertical ? "horizontal" : "vertical",
      "aria-valuemax": max,
      "aria-valuemin": 0,
      "aria-valuenow": shown ? current : 0,
      "aria-valuetext": shown ? `${current} pixels` : "Closed",
      "data-dragging": drag ? true : undefined,
      onKeyDown,
      onLostPointerCapture: end,
      onPointerDown: (event) => {
        if (event.button !== 0) return;
        event.preventDefault();
        event.currentTarget.setPointerCapture(event.pointerId);
        dragging(vertical ? "row-resize" : "col-resize");
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
}

function useMediaQuery(query) {
  const [matches, setMatches] = useState(() => matchMedia(query).matches);
  useEffect(() => {
    const list = matchMedia(query);
    const update = () => setMatches(list.matches);
    update();
    list.addEventListener("change", update);
    return () => list.removeEventListener("change", update);
  }, [query]);
  return matches;
}

export function sidebarImpl({ id, open, width, resize, close, className, handleClassName, children }) {
  const area = useResizable({ id, label: "Resize files", open, size: width, min: 180, max: 480, collapse: 120, resize, close });
  return (
    <>
      {area.presence.rendered && (
        <div className={className} id={id} style={{ "--sidebar-width": `${area.current}px` }} {...area.presence.props}>
          {children}
        </div>
      )}
      <div className={handleClassName} style={{ insetInlineStart: area.shown ? area.current - 3 : 0 }} {...area.handleProps} />
    </>
  );
}

const BELOW = "(max-width: 960px)";

export function panelImpl({ id, label, open, width, height, resize, close, className, handleClassName, children }) {
  const vertical = useMediaQuery(BELOW);
  const area = useResizable({
    id,
    label: `Resize ${label.toLowerCase()}`,
    open,
    size: vertical ? height : width,
    min: vertical ? 120 : 240,
    max: vertical ? 800 : 900,
    collapse: vertical ? 80 : 160,
    vertical,
    fromEnd: true,
    share: 0.7,
    resize: (size) => resize(vertical ? { width, height: size } : { width: size, height }),
    close,
  });
  const sizes = (shown) => ({
    "--panel-width": `${shown ? (vertical ? width : area.current) : 0}px`,
    "--panel-height": `${shown ? (vertical ? area.current : height) : 0}px`,
  });
  return (
    <>
      {area.presence.rendered && (
        <aside aria-label={label} className={className} id={id} style={sizes(true)} {...area.presence.props}>
          {children}
        </aside>
      )}
      <div className={handleClassName} style={sizes(area.shown)} {...area.handleProps} />
    </>
  );
}

export function pillImpl({ href, label, accessibleLabel, tooltip, className, iconClassName, tooltipClassName }) {
  return (
    <TooltipTrigger closeDelay={100} delay={300}>
      {href ? (
        <Link aria-label={accessibleLabel} className={className} href={href} rel="noopener noreferrer" target="_blank">
          {label}
          <ExternalLinkIcon aria-hidden="true" className={iconClassName} focusable="false" />
        </Link>
      ) : (
        <Focusable>
          <span aria-label={accessibleLabel} className={className} role="img" tabIndex={0}>
            {label}
          </span>
        </Focusable>
      )}
      <Tooltip className={tooltipClassName} offset={8} placement="bottom">
        {tooltip}
      </Tooltip>
    </TooltipTrigger>
  );
}

const CONSOLE_BAR = 1 + 28;
const CONSOLE_MIN = CONSOLE_BAR + 10 * 23;

export function consoleImpl({ overlay, open, height, resize, close, className, scrollerClassName, handleClassName, bar, children }) {
  const scroller = useRef(null);
  const following = useRef(true);
  const area = useResizable({
    id: "playground-console",
    label: "Resize console",
    open,
    size: Math.max(CONSOLE_MIN, height),
    min: CONSOLE_MIN,
    max: 4000,
    collapse: CONSOLE_BAR + 40,
    vertical: true,
    fromEnd: true,
    share: 0.9,
    resize,
    close,
  });
  const shown = area.shown ? area.current : CONSOLE_BAR;
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
  return (
    <>
      {overlay && (
        <div className={handleClassName} style={{ insetBlockEnd: `calc(min(${shown}px, 100%) - 3px)` }} {...area.handleProps} />
      )}
      <div className={className} style={overlay ? { height: shown } : undefined}>
        {overlay && bar}
        <div
          aria-live="polite"
          className={scrollerClassName}
          id="playground-console"
          onScroll={onScroll}
          ref={scroller}
          role="log"
        >
          {children}
        </div>
      </div>
    </>
  );
}
