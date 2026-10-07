import { Fragment, useState } from "react";
import { Tab, TabList, TabPanel, Tabs } from "react-aria-components";
import AppleIcon from "~icons/simple-icons/apple";
import LinuxIcon from "~icons/simple-icons/linux";
import WindowsIcon from "~icons/simple-icons/windows";
import ExternalLinkIcon from "~icons/lucide/external-link";

const platforms = [
  {
    id: "unix",
    systems: [{ Icon: AppleIcon, name: "macOS" }, { Icon: LinuxIcon, name: "Linux" }],
    prompt: "$",
    command: "curl -fsSL https://iris-lang.com/install.sh | sh",
    script: "/install.sh",
  },
  {
    id: "windows",
    systems: [{ Icon: WindowsIcon, name: "Windows" }],
    prompt: "PS>",
    command: "irm https://iris-lang.com/install.ps1 | iex",
    script: "/install.ps1",
  },
];

export function installationImpl({
  commandClassName,
  copyButton,
  headerClassName,
  iconClassName,
  sourceClassName,
  sourceIconClassName,
  systemClassName,
  panelClassName,
  promptClassName,
  rootClassName,
  tabClassName,
  tabListClassName,
}) {
  const [selected, setSelected] = useState("unix");
  const script = platforms.find(platform => platform.id === selected).script;

  return (
    <Tabs className={rootClassName} onSelectionChange={setSelected} selectedKey={selected}>
      <div className={headerClassName}>
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
        <a
          aria-label={`Show the ${script.slice(1)} source (opens in a new tab)`}
          className={sourceClassName}
          href={script}
          rel="noopener noreferrer"
          target="_blank"
        >
          Show source
          <ExternalLinkIcon aria-hidden="true" className={sourceIconClassName} focusable="false" />
        </a>
      </div>
      {platforms.map(({ id, prompt, command }) => (
        <TabPanel className={panelClassName} id={id} key={id}>
          <code className={commandClassName}><span aria-hidden="true" className={promptClassName}>{prompt} </span>{command}</code>
          {copyButton(command)}
        </TabPanel>
      ))}
    </Tabs>
  );
}
