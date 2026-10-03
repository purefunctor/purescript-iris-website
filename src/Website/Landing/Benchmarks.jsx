import { useEffect, useRef, useState } from "react";
import { Tab, TabList, TabPanel, Tabs } from "react-aria-components";

// The bars race once the chart is on screen. One panel follows the selected tab rather than one
// panel per tab, so switching keeps the chart mounted and its styles transition between the
// measurements. Motion-reduced styles show the finished chart instead.
export function benchmarkChartImpl({
  chart,
  controlsClassName,
  footer,
  headerClassName,
  iconClassName,
  introduction,
  panelClassName,
  rootClassName,
  tabClassName,
  tabListClassName,
  tabs,
}) {
  const root = useRef(null);
  const [started, setStarted] = useState(false);
  const [selected, setSelected] = useState(tabs[0].id);

  useEffect(() => {
    if (!root.current) return undefined;
    const observer = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting) return;
      setStarted(true);
      observer.disconnect();
    }, { threshold: 0.4 });
    observer.observe(root.current);
    return () => observer.disconnect();
  }, []);

  const select = key => {
    setStarted(true);
    setSelected(key);
  };

  return (
    <div ref={root}>
      <Tabs className={rootClassName} onSelectionChange={select} selectedKey={selected}>
        <div className={headerClassName}>
          {introduction}
          <div className={controlsClassName}>
            <TabList aria-label="Benchmark" className={tabListClassName}>
              {tabs.map(({ icon: Icon, id, label }) => (
                <Tab className={tabClassName} id={id} key={id}>
                  <Icon aria-hidden="true" className={iconClassName} focusable="false" />
                  {label}
                </Tab>
              ))}
            </TabList>
          </div>
        </div>
        <TabPanel className={panelClassName} id={selected}>{chart({ selected, started })}</TabPanel>
      </Tabs>
      {footer}
    </div>
  );
}
