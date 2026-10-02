import { Fragment } from "react";
import { Tab, TabList, TabPanel, Tabs } from "react-aria-components";
import AppleIcon from "~icons/simple-icons/apple";
import LinuxIcon from "~icons/simple-icons/linux";
import WindowsIcon from "~icons/simple-icons/windows";

const platforms = [
  {
    id: "unix",
    systems: [{ Icon: AppleIcon, name: "macOS" }, { Icon: LinuxIcon, name: "Linux" }],
    prompt: "$",
    command: "curl -fsSL https://iris-lang.com/install.sh | sh",
  },
  {
    id: "windows",
    systems: [{ Icon: WindowsIcon, name: "Windows" }],
    prompt: "PS>",
    command: "irm https://iris-lang.com/install.ps1 | iex",
  },
];

export function installationImpl({
  commandClassName,
  copyButton,
  iconClassName,
  systemClassName,
  panelClassName,
  promptClassName,
  rootClassName,
  tabClassName,
  tabListClassName,
}) {
  return (
    <Tabs className={rootClassName} defaultSelectedKey="unix">
      <TabList aria-label="Installation platform" className={tabListClassName}>
        {platforms.map(({ id, systems }) => (
          <Tab className={tabClassName} id={id} key={id}>
            {systems.map(({ Icon, name }, index) => (
              <Fragment key={name}>
                {index > 0 && " / "}
                <span className={systemClassName}>
                  <Icon aria-hidden="true" className={iconClassName} focusable="false" />
                  {name}
                </span>
              </Fragment>
            ))}
          </Tab>
        ))}
      </TabList>
      {platforms.map(({ id, prompt, command }) => (
        <TabPanel className={panelClassName} id={id} key={id}>
          <code className={commandClassName}><span aria-hidden="true" className={promptClassName}>{prompt} </span>{command}</code>
          {copyButton(command)}
        </TabPanel>
      ))}
    </Tabs>
  );
}
