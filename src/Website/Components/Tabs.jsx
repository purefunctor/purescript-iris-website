import { Tab, TabList, TabPanel, Tabs } from "react-aria-components/Tabs";

export const tabsImpl = ({ label, items, classes }) => (
  <Tabs className={classes.root}>
    <TabList aria-label={label} className={classes.list}>
      {items.map(({ id, tab }) => (
        <Tab className={classes.tab} id={id} key={id}>
          {tab}
        </Tab>
      ))}
    </TabList>
    {items.map(({ id, panel }) => (
      <TabPanel className={classes.panel} id={id} key={id} shouldForceMount>
        {panel}
      </TabPanel>
    ))}
  </Tabs>
);
