import { useMemo, useState } from "react";

const TITLES = {
  dependency: (entry) => `Required by ${entry.requiredBy}`,
  installed: () => "Installed, so activating needs no download",
};

// Searches the package set and activates or deactivates packages, linking each one to its
// documentation on Pursuit. It shows the active packages until the reader switches to all of them;
// the switch's thumb slides under the chosen side.
export function packagesImpl({
  packages,
  busy,
  activate,
  deactivate,
  rootClassName,
  searchClassName,
  inputClassName,
  filtersClassName,
  filterClassName,
  thumbClassName,
  thumbEndClassName,
  noteClassName,
  listClassName,
  rowClassName,
  nameClassName,
  versionClassName,
  toggleClassNames,
}) {
  const [query, setQuery] = useState("");
  const [showAll, setShowAll] = useState(false);
  // Deactivating a package in the Active view keeps the rows it showed, its own and the
  // dependencies it frees, until the reader switches filters or leaves the Packages pane, which
  // unmounts this panel. Their switches slide off in place and can slide back on.
  const [kept, setKept] = useState(() => new Set());
  const isActive = (entry) =>
    entry.status === "active" || entry.status === "dependency" || kept.has(entry.name);
  const found = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return packages.available;
    const found = packages.available.filter((entry) => entry.name.includes(needle));
    found.sort((a, b) => (b.name.startsWith(needle) - a.name.startsWith(needle)) || a.name.localeCompare(b.name));
    return found;
  }, [packages.available, query]);
  const matches = showAll ? found : found.filter(isActive);
  const leave = (name) => {
    if (!showAll) setKept(new Set([...kept, ...matches.map((entry) => entry.name)]));
    return deactivate(name);
  };

  const filter = (all, label) => (
    <button aria-pressed={showAll === all} className={filterClassName} onClick={() => {
        setShowAll(all);
        setKept(new Set());
      }} type="button">
      {label}
    </button>
  );

  return (
    <div className={rootClassName}>
      <div className={searchClassName}>
        <input
          aria-label="Search packages"
          className={inputClassName}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={`Search ${showAll ? packages.available.length : packages.active} packages`}
          spellCheck={false}
          type="search"
          value={query}
        />
        <div aria-label="Show packages" className={filtersClassName} role="group">
          <span aria-hidden="true" className={showAll ? thumbEndClassName : thumbClassName} />
          {filter(false, `Active ${packages.active}`)}
          {filter(true, `All ${packages.available.length}`)}
        </div>
      </div>
      <ul aria-label="Packages" className={listClassName}>
        {matches.map((entry) => (
          <li className={rowClassName} key={entry.name}>
            <a
              className={nameClassName}
              href={`https://pursuit.purescript.org/packages/purescript-${entry.name}/${entry.version}`}
              rel="noreferrer"
              target="_blank"
              title={entry.name}
            >
              {entry.name}
            </a>
            <span className={versionClassName}>{entry.version}</span>
            <PackageToggle
              activate={activate}
              busy={busy}
              classNames={toggleClassNames}
              deactivate={leave}
              entry={entry}
            />
          </li>
        ))}
      </ul>
      {matches.length === 0 && (
        <p className={noteClassName}>
          {found.length > 0 ? "No active package matches; show all packages to activate one." : "No package in this package set matches."}
        </p>
      )}
    </div>
  );
}


// The X and the check share one shape, two strokes, so browsers that animate `d` morph one into
// the other while the knob slides.
const CROSS = "M3 3 L9 9 M9 3 L3 9";
const CHECK = "M2.5 6.5 L5 9 M5 9 L9.5 3";

// A package's switch. A dependency's stays on and disabled, since it leaves with the packages
// that need it.
function PackageToggle({ entry, busy, activate, deactivate, classNames }) {
  const locked = entry.status === "dependency";
  const on = locked || entry.status === "active";
  return (
    <button
      aria-checked={on}
      aria-label={entry.name}
      className={on ? classNames.trackOn : classNames.track}
      disabled={busy || locked}
      onClick={() => (on ? deactivate : activate)(entry.name)()}
      role="switch"
      title={locked ? `Required by ${entry.requiredBy}` : undefined}
      type="button"
    >
      <span className={on ? classNames.knobOn : classNames.knob}>
        <svg aria-hidden="true" className={classNames.icon} viewBox="0 0 12 12">
          <path className={on ? classNames.markOn : classNames.mark} d={on ? CHECK : CROSS} />
        </svg>
      </span>
    </button>
  );
}
