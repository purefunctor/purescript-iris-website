import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import LockIcon from "~icons/lucide/lock";
import PencilIcon from "~icons/lucide/pencil";
import PlusIcon from "~icons/lucide/plus";
import XIcon from "~icons/lucide/x";

const label = (path) => path.replace(/^src\//, "");

// One tab per project file, plus a tab for a read-only source that navigation opened. The active
// file can be renamed in place or deleted; the last file cannot be deleted.
export function fileTabsImpl({
  files,
  active,
  viewing,
  actions,
  rootClassName,
  tabClassName,
  activeTabClassName,
  nameClassName,
  errorCountClassName,
  warningCountClassName,
  iconButtonClassName,
  inputClassName,
  errorClassName,
  addClassName,
}) {
  const [editing, setEditing] = useState(null);
  const [draft, setDraft] = useState("");
  const [problem, setProblem] = useState(null);
  const [anchor, setAnchor] = useState(null);
  const input = useRef(null);

  // The tab strip scrolls horizontally, which clips anything below it, so the rejection renders
  // in the body, fixed under the input.
  useLayoutEffect(() => {
    if (!problem || !input.current) return setAnchor(null);
    const box = input.current.getBoundingClientRect();
    setAnchor({ top: box.bottom + 6, left: box.left });
  }, [problem]);

  useEffect(() => {
    if (editing) input.current?.select();
  }, [editing]);

  const startRename = (path) => {
    setEditing(path);
    setDraft(path);
    setProblem(null);
  };
  const commit = () => {
    const rejection = actions.renameFile(editing)(draft)();
    if (rejection) {
      setProblem(rejection);
    } else {
      setEditing(null);
      setProblem(null);
    }
  };

  return (
    <div className={rootClassName} role="group" aria-label="Files">
      {files.map((file) => {
        const selected = !viewing && file.path === active;
        if (editing === file.path) {
          return (
            <div className={activeTabClassName} key={file.path}>
              <input
                aria-label={`New path for ${file.path}`}
                aria-invalid={problem ? true : undefined}
                className={inputClassName}
                onBlur={() => setEditing(null)}
                onChange={(event) => setDraft(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") commit();
                  if (event.key === "Escape") setEditing(null);
                }}
                ref={input}
                size={Math.max(12, draft.length)}
                spellCheck={false}
                value={draft}
              />
              {problem &&
                anchor &&
                createPortal(
                  <span className={errorClassName} role="alert" style={anchor}>
                    {problem}
                  </span>,
                  document.body,
                )}
            </div>
          );
        }
        return (
          <div className={selected ? activeTabClassName : tabClassName} key={file.path}>
            <button
              aria-current={selected ? "true" : undefined}
              className={nameClassName}
              onClick={actions.selectFile(file.path)}
              onDoubleClick={() => startRename(file.path)}
              title={file.path}
              type="button"
            >
              {label(file.path)}
              {file.errors > 0 && (
                <span className={errorCountClassName} aria-label={`${file.errors} errors`}>
                  {file.errors}
                </span>
              )}
              {file.errors === 0 && file.warnings > 0 && (
                <span className={warningCountClassName} aria-label={`${file.warnings} warnings`}>
                  {file.warnings}
                </span>
              )}
            </button>
            {selected && (
              <>
                <button aria-label={`Rename ${file.path}`} className={iconButtonClassName} onClick={() => startRename(file.path)} title="Rename" type="button">
                  <PencilIcon aria-hidden />
                </button>
                {files.length > 1 && (
                  <button aria-label={`Delete ${file.path}`} className={iconButtonClassName} onClick={actions.deleteFile(file.path)} title="Delete" type="button">
                    <XIcon aria-hidden />
                  </button>
                )}
              </>
            )}
          </div>
        );
      })}
      {viewing && (
        <div className={activeTabClassName}>
          <span aria-current="true" className={nameClassName} title={`${viewing.uri} (read-only)`}>
            <LockIcon aria-label="Read-only" />
            {viewing.label}
          </span>
          <button aria-label={`Close ${viewing.label}`} className={iconButtonClassName} onClick={actions.closeViewer} title="Close" type="button">
            <XIcon aria-hidden />
          </button>
        </div>
      )}
      <button aria-label="New file" className={addClassName} onClick={actions.createFile} title="New file" type="button">
        <PlusIcon aria-hidden />
      </button>
    </div>
  );
}
