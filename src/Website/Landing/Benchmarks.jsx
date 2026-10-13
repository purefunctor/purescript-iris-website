import { useEffect, useRef, useState } from "react";
import { Tab, TabList, TabPanel, Tabs } from "react-aria-components/Tabs";
import { particleField } from "#src/Website/Landing/Particles.js";

// The bars race once the chart is on screen. One panel follows the selected tab rather than one
// panel per tab, so switching keeps the chart mounted and its styles transition between the
// measurements. Motion-reduced styles show the finished chart instead.
//
// Selecting a tab bursts its temperature's particles from it: snowflakes for a cold build, sparks
// for a hot rebuild.

export function benchmarkChartImpl({
  chart,
  controlsClassName,
  footer,
  headerClassName,
  introduction,
  panelClassName,
  particlesClassName,
  rootClassName,
  tabListClassName,
  tabs,
}) {
  const root = useRef(null);
  const canvas = useRef(null);
  const particles = useRef(null);
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

  useEffect(() => {
    if (!canvas.current) return undefined;
    const field = particleField(canvas.current);
    particles.current = field;
    return () => {
      particles.current = null;
      field.stop();
    };
  }, []);

  const select = key => {
    setStarted(true);
    setSelected(key);
    const tab = root.current?.querySelector(`[role="tab"][id$="-tab-${key}"]`);
    if (tab && !matchMedia("(prefers-reduced-motion: reduce)").matches) particles.current?.burst(key, tab);
  };

  return (
    <div ref={root}>
      <Tabs className={rootClassName} onSelectionChange={select} selectedKey={selected}>
        <div className={headerClassName}>
          {introduction}
          <div className={controlsClassName}>
            <canvas aria-hidden="true" className={particlesClassName} ref={canvas} />
            <TabList aria-label="Benchmark" className={tabListClassName}>
              {tabs.map(({ className, icon: Icon, iconClassName, id, label }) => (
                <Tab className={className} id={id} key={id}>
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
