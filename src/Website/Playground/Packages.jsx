import { useMemo, useState } from "react";

const LIMIT = 60;

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
        <p className={noteClassName}>
          Every package in package set {packages.packageSet} is installed. Import its modules from
          any file.
        </p>
      </div>
      <ul aria-label="Packages" className={listClassName}>
        {matches.slice(0, LIMIT).map((entry) => (
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
      <p className={noteClassName}>
        {matches.length === 0
          ? "No package in this package set matches."
          : matches.length > LIMIT
            ? `Showing ${LIMIT} of ${matches.length}. Search to find the rest.`
            : `${matches.length} ${matches.length === 1 ? "package" : "packages"}.`}
      </p>
    </div>
  );
}
