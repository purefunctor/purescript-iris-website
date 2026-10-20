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

// The Output and Packages panel, which animates as it opens and closes.
export function panelImpl({ open, id, label, className, children }) {
  const presence = usePresence(open, true);
  if (!presence.rendered) return null;
  return (
    <aside aria-label={label} className={className} id={id} {...presence.props}>
      {children}
    </aside>
  );
}

const MIN_WIDTH = 180;
const MAX_WIDTH = 480;
// Dragging the edge narrower than this closes the sidebar, and dragging past it opens it again.
const COLLAPSE_WIDTH = 120;
const STEP = 16;

// The sidebar and the handle on its edge. A drag previews locally and reaches the controller once
// it ends, so the rest of the page renders once per drag. Without the sidebar, the handle stays at
// the editor's edge, so dragging it out opens the sidebar again.
export function sidebarImpl({ id, open, width, resize, close, className, handleClassName, children }) {
  const [drag, setDrag] = useState(null);
  const shown = drag ? drag.open : open;
  const current = drag ? drag.width : width;
  const presence = usePresence(shown, !drag);
  const clamp = (value) => Math.min(MAX_WIDTH, Math.max(MIN_WIDTH, Math.round(value)));

  const end = () => {
    if (!drag) return;
    document.documentElement.style.removeProperty("cursor");
    setDrag(null);
    if (drag.open) resize(drag.width)();
    else close();
  };
  const onKeyDown = (event) => {
    if (event.key === "ArrowLeft" && open) {
      if (width - STEP < MIN_WIDTH) close();
      else resize(width - STEP)();
    } else if (event.key === "ArrowRight") {
      resize(open ? clamp(width + STEP) : width)();
    } else if (event.key === "Enter") {
      if (open) close();
      else resize(width)();
    } else {
      return;
    }
    event.preventDefault();
  };

  return (
    <>
      {presence.rendered && (
        <div className={className} id={id} style={{ "--sidebar-width": `${current}px` }} {...presence.props}>
          {children}
        </div>
      )}
      <div
        aria-controls={id}
        aria-label="Resize files"
        aria-orientation="vertical"
        aria-valuemax={MAX_WIDTH}
        aria-valuemin={0}
        aria-valuenow={shown ? current : 0}
        aria-valuetext={shown ? `${current} pixels` : "Closed"}
        className={handleClassName}
        data-dragging={drag ? true : undefined}
        onKeyDown={onKeyDown}
        onLostPointerCapture={end}
        onPointerDown={(event) => {
          if (event.button !== 0) return;
          event.preventDefault();
          event.currentTarget.focus();
          event.currentTarget.setPointerCapture(event.pointerId);
          document.documentElement.style.cursor = "col-resize";
          const left = event.currentTarget.parentElement.getBoundingClientRect().left;
          setDrag({ left, width, open });
        }}
        onPointerMove={(event) => {
          if (!drag) return;
          const raw = event.clientX - drag.left;
          const opened = raw >= COLLAPSE_WIDTH;
          setDrag({ ...drag, open: opened, width: opened ? clamp(raw) : drag.width });
        }}
        role="separator"
        style={{ insetInlineStart: shown ? current - 3 : 0 }}
        tabIndex={0}
      />
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
