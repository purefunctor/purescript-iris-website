import { useEffect, useMemo, useRef, useState } from "react";
import { Tab, TabList, TabPanel, Tabs } from "react-aria-components/Tabs";

const initialState = {
  phase: "loading",
  files: [],
  open: [],
  active: null,
  viewing: null,
  sidebar: false,
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

// The side panel's Output and Packages tabs.
export function panelTabsImpl({
  rootClassName,
  tabListClassName,
  tabClassName,
  panelClassName,
  badgeClassName,
  output,
  outputBadge,
  packages,
  packagesBadge,
}) {
  return (
    <Tabs className={rootClassName} defaultSelectedKey="output">
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
      <TabPanel className={panelClassName} id="output">
        {output}
      </TabPanel>
      <TabPanel className={panelClassName} id="packages">
        {packages}
      </TabPanel>
    </Tabs>
  );
}
