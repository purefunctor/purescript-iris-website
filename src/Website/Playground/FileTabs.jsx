import LockIcon from "~icons/lucide/lock";
import XIcon from "~icons/lucide/x";

const label = (path) => path.replace(/^src\//, "");

export function fileTabsImpl({
  files,
  open,
  active,
  viewing,
  actions,
  rootClassName,
  tabClassName,
  activeTabClassName,
  nameClassName,
  errorCountClassName,
  warningCountClassName,
  closeClassName,
  activeCloseClassName,
}) {
  const counts = new Map(files.map((file) => [file.path, file]));
  return (
    <div className={rootClassName} role="group" aria-label="Open files">
      {open.map((path) => {
        const selected = !viewing && path === active;
        const file = counts.get(path);
        return (
          <div className={selected ? activeTabClassName : tabClassName} key={path}>
            <button
              aria-current={selected ? "true" : undefined}
              className={nameClassName}
              onClick={actions.openFile(path)}
              title={path}
              type="button"
            >
              {label(path)}
              {file?.errors > 0 && (
                <span className={errorCountClassName} aria-label={`${file.errors} errors`}>
                  {file.errors}
                </span>
              )}
              {file?.errors === 0 && file.warnings > 0 && (
                <span className={warningCountClassName} aria-label={`${file.warnings} warnings`}>
                  {file.warnings}
                </span>
              )}
            </button>
            <button aria-label={`Close ${label(path)}`} className={selected ? activeCloseClassName : closeClassName} onClick={actions.closeFile(path)} title="Close" type="button">
              <XIcon aria-hidden />
            </button>
          </div>
        );
      })}
      {viewing && (
        <div className={activeTabClassName}>
          <span aria-current="true" className={nameClassName} title={`${viewing.uri} (read-only)`}>
            <LockIcon aria-label="Read-only" />
            {viewing.label}
          </span>
          <button aria-label={`Close ${viewing.label}`} className={activeCloseClassName} onClick={actions.closeViewer} title="Close" type="button">
            <XIcon aria-hidden />
          </button>
        </div>
      )}
    </div>
  );
}
