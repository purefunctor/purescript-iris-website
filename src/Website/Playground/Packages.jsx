import { useMemo, useState } from "react";

// Searches the package set, which the project can import from in full, and links each package to
// its documentation on Pursuit.
export function packagesImpl({
  packages,
  rootClassName,
  searchClassName,
  inputClassName,
  noteClassName,
  listClassName,
  rowClassName,
  nameClassName,
  versionClassName,
}) {
  const [query, setQuery] = useState("");
  const matches = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return packages.available;
    const found = packages.available.filter((entry) => entry.name.includes(needle));
    found.sort((a, b) => (b.name.startsWith(needle) - a.name.startsWith(needle)) || a.name.localeCompare(b.name));
    return found;
  }, [packages.available, query]);
  const count = packages.available.length;

  return (
    <div className={rootClassName}>
      <div className={searchClassName}>
        <input
          aria-label="Search packages"
          className={inputClassName}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={`Search ${count} packages`}
          spellCheck={false}
          type="search"
          value={query}
        />
      </div>
      <ul aria-label="Packages" className={listClassName}>
        {matches.map((entry) => (
          <li className={rowClassName} key={entry.name}>
            <a
              className={nameClassName}
              href={`https://pursuit.purescript.org/packages/purescript-${entry.name}/${entry.version}`}
              rel="noreferrer"
              target="_blank"
            >
              {entry.name}
            </a>
            <span className={versionClassName}>{entry.version}</span>
          </li>
        ))}
      </ul>
      {matches.length === 0 && <p className={noteClassName}>No package in this package set matches.</p>}
    </div>
  );
}
