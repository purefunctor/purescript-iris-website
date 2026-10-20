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
  server: { kind: null, version: null, revision: null, status: "starting", message: null },
  packages: { available: [], packageSet: null, loaded: 0, total: 0, bytes: 0, totalBytes: 0 },
  run: { status: "idle", lines: [] },
  shared: false,
};

// Loads the controller, with Monaco and the language server worker, only once the page renders,
// and hands its state and actions to the PureScript `render`.
export function playgroundImpl({ theme, render }) {
  const editor = useRef(null);
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
      createFile: () => call("createFile"),
      renameFile: (from) => (to) => () => call("renameFile", from, to) ?? null,
      deleteFile: (path) => () => call("deleteFile", path),
      run: () => call("run"),
      stop: () => call("stop"),
      clearOutput: () => call("clearOutput"),
      share: () => call("share"),
      reset: () => call("reset"),
      // Without a controller, the page itself failed to load, so it loads again.
      retry: () => (controller.current ? call("retry") : location.reload()),
    };
  }, []);

  return render({ state, actions, editor, frames });
}

// The side panel's Output and Packages tabs. The selection lives in the controller, so the panel
// reopens on the tab it closed on, and a panel fades in only when the reader switches to it, not
// when the whole panel opens.
export function panelTabsImpl({
  selected,
  select,
  rootClassName,
  barClassName,
  tabListClassName,
  tabClassName,
  panelClassName,
  switchedPanelClassName,
  badgeClassName,
  output,
  outputAction,
  outputBadge,
  packages,
  packagesBadge,
}) {
  const [switched, setSwitched] = useState(false);
  const panelClass = switched ? switchedPanelClassName : panelClassName;
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
        <TabList aria-label="Playground panels" className={tabListClassName}>
          <Tab className={tabClassName} id="output">
            Output
            {outputBadge && <span className={badgeClassName}>{outputBadge}</span>}
          </Tab>
          <Tab className={tabClassName} id="packages">
            Packages
            {packagesBadge && <span className={badgeClassName}>{packagesBadge}</span>}
          </Tab>
        </TabList>
        {selected === "output" && outputAction}
      </div>
      <TabPanel className={panelClass} id="output">
        {output}
      </TabPanel>
      <TabPanel className={panelClass} id="packages">
        {packages}
      </TabPanel>
    </Tabs>
  );
}

const reducedMotion = () => matchMedia("(prefers-reduced-motion: reduce)").matches;

// Keeps an element mounted while it animates out, and marks its `data-entering` and
// `data-exiting` phases for its styles to animate. The first render, changes while `animate` is
// false, such as during a drag, and reduced motion all switch at once.
function usePresence(open, animate) {
  const [phase, setPhase] = useState(open ? "open" : "closed");
  useLayoutEffect(() => {
    const moving = animate && !reducedMotion();
    setPhase((current) => {
      if (open) return current === "closed" || current === "exiting" ? (moving ? "entering" : "open") : current;
      return current === "closed" ? current : moving ? "exiting" : "closed";
    });
  }, [open, animate]);
  // A style without an animation never ends one, so phases also settle on a timer.
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
// Shrinks are named by the key that grows each kind of area.
const SHRINK = { ArrowRight: "ArrowLeft", ArrowLeft: "ArrowRight", ArrowUp: "ArrowDown", ArrowDown: "ArrowUp" };

// An area that the reader resizes by dragging the handle on one of its edges, or with the arrow
// keys on the focused handle. Dragging below `collapse` closes the area, and dragging the handle
// out again opens it. A drag previews locally and reaches the controller once it ends, so the rest
// of the page renders once per drag. `vertical` areas resize by height, and `fromEnd` areas sit at
// the end of their parent, so their handle is on their leading edge. A `share` below 1 keeps the
// area from taking more than that part of its parent.
function useResizable({ id, label, open, size, min, max, collapse, vertical, fromEnd, share = 1, resize, close }) {
  const [drag, setDrag] = useState(null);
  const shown = drag ? drag.open : open;
  const current = drag ? drag.size : size;
  const presence = usePresence(shown, !drag);
  const limit = (value, most = max) => Math.min(most, Math.max(min, Math.round(value)));
  const grow = vertical ? (fromEnd ? "ArrowUp" : "ArrowDown") : fromEnd ? "ArrowLeft" : "ArrowRight";

  const end = () => {
    if (!drag) return;
    document.documentElement.style.removeProperty("cursor");
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
      // A separator's orientation is its own: a side panel's edge runs vertically.
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
        document.documentElement.style.cursor = vertical ? "row-resize" : "col-resize";
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

// The sidebar and the handle on its edge. Without the sidebar, the handle stays at the editor's
// edge, so dragging it out opens the sidebar again.
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

// Website.Breakpoints' upTo960, where the panel moves below the editor.
const BELOW = "(max-width: 960px)";

// The Output and Packages panel and the handle on its leading edge. It sits beside the editor and
// resizes by width, or below it and resizes by height, keeping a size for each. Its styles cap it
// at 70% of the workspace, so the editor stays usable whatever size a wider window left it at.
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

// A status pill with a tooltip. With an `href` it links out and shows the external link icon;
// without one it is a focusable label, so that keyboard readers reach its tooltip too.
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
