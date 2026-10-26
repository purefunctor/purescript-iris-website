import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import ChevronRightIcon from "~icons/lucide/chevron-right";
import FilePlusIcon from "~icons/lucide/file-plus";
import PencilIcon from "~icons/lucide/pencil";
import TrashIcon from "~icons/lucide/trash-2";
import FileIcon from "~icons/material-icon-theme/document";
import JavaScriptIcon from "~icons/material-icon-theme/javascript";
import PureScriptIcon from "~icons/material-icon-theme/purescript";
import ReactIcon from "~icons/material-icon-theme/react";

const fileIconsByExtension = {
  purs: PureScriptIcon,
  js: JavaScriptIcon,
  jsx: ReactIcon,
};

function iconFor(name) {
  const dot = name.lastIndexOf(".");
  return (dot > 0 && fileIconsByExtension[name.slice(dot + 1)]) || FileIcon;
}

function buildTree(files) {
  const root = { folders: new Map(), files: [] };
  for (const file of files) {
    const segments = file.path.split("/");
    let node = root;
    let prefix = "";
    for (const segment of segments.slice(0, -1)) {
      prefix = prefix ? `${prefix}/${segment}` : segment;
      if (!node.folders.has(segment)) node.folders.set(segment, { path: prefix, folders: new Map(), files: [] });
      node = node.folders.get(segment);
    }
    node.files.push({ ...file, name: segments.at(-1) });
  }
  return root;
}

function errorsIn(node) {
  let errors = node.files.reduce((sum, file) => sum + file.errors, 0);
  for (const folder of node.folders.values()) errors += errorsIn(folder);
  return errors;
}

export function fileTreeImpl({
  files,
  active,
  viewing,
  actions,
  rootClassName,
  headerClassName,
  titleClassName,
  newFileClassName,
  scrollClassName,
  listClassName,
  folderClassName,
  itemClassName,
  rowClassName,
  activeRowClassName,
  chevronClassName,
  openChevronClassName,
  iconClassName,
  nameClassName,
  errorCountClassName,
  warningCountClassName,
  errorDotClassName,
  actionsClassName,
  actionClassName,
  inputClassName,
  problemClassName,
}) {
  const tree = useMemo(() => buildTree(files), [files]);
  const [collapsed, setCollapsed] = useState(() => new Set());
  const [editing, setEditing] = useState(null);
  const [draft, setDraft] = useState("");
  const [problem, setProblem] = useState(null);
  const [anchor, setAnchor] = useState(null);
  const input = useRef(null);

  useEffect(() => {
    if (editing) input.current?.select();
  }, [editing]);

  useLayoutEffect(() => {
    if (!problem || !input.current) return setAnchor(null);
    const box = input.current.getBoundingClientRect();
    setAnchor({ top: box.bottom + 6, left: box.left });
  }, [problem]);

  const toggle = (path) =>
    setCollapsed((current) => {
      const next = new Set(current);
      if (!next.delete(path)) next.add(path);
      return next;
    });
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
  const depth = (level) => ({ "--depth": level });

  const renderFolder = (name, folder, level) => {
    const open = !collapsed.has(folder.path);
    const errors = open ? 0 : errorsIn(folder);
    return (
      <li className={folderClassName} key={folder.path}>
        <button aria-expanded={open} className={rowClassName} onClick={() => toggle(folder.path)} style={depth(level)} type="button">
          <ChevronRightIcon aria-hidden className={open ? openChevronClassName : chevronClassName} />
          <span className={nameClassName}>{name}</span>
          {errors > 0 && <span aria-label={`${errors} errors inside`} className={errorDotClassName} />}
        </button>
        {open && renderChildren(folder, level + 1)}
      </li>
    );
  };

  const renderFile = (file, level) => {
    if (editing === file.path) {
      return (
        <li className={itemClassName} key={file.path}>
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
            spellCheck={false}
            style={depth(level)}
            value={draft}
          />
          {problem &&
            anchor &&
            createPortal(
              <span className={problemClassName} role="alert" style={anchor}>
                {problem}
              </span>,
              document.body,
            )}
        </li>
      );
    }
    const selected = !viewing && file.path === active;
    const Icon = iconFor(file.name);
    return (
      <li className={itemClassName} key={file.path}>
        <button
          aria-current={selected ? "true" : undefined}
          className={selected ? activeRowClassName : rowClassName}
          onClick={actions.openFile(file.path)}
          onDoubleClick={() => startRename(file.path)}
          style={depth(level)}
          title={file.path}
          type="button"
        >
          <Icon aria-hidden className={iconClassName} />
          <span className={nameClassName}>{file.name}</span>
          {file.errors > 0 && (
            <span aria-label={`${file.errors} errors`} className={errorCountClassName}>
              {file.errors}
            </span>
          )}
          {file.errors === 0 && file.warnings > 0 && (
            <span aria-label={`${file.warnings} warnings`} className={warningCountClassName}>
              {file.warnings}
            </span>
          )}
        </button>
        <span className={actionsClassName}>
          <button aria-label={`Rename ${file.path}`} className={actionClassName} onClick={() => startRename(file.path)} title="Rename" type="button">
            <PencilIcon aria-hidden />
          </button>
          {files.length > 1 && (
            <button aria-label={`Delete ${file.path}`} className={actionClassName} onClick={actions.deleteFile(file.path)} title="Delete" type="button">
              <TrashIcon aria-hidden />
            </button>
          )}
        </span>
      </li>
    );
  };

  const renderChildren = (node, level) => (
    <ul className={listClassName}>
      {[...node.folders]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([name, folder]) => renderFolder(name, folder, level))}
      {[...node.files].sort((a, b) => a.name.localeCompare(b.name)).map((file) => renderFile(file, level))}
    </ul>
  );

  return (
    <nav aria-labelledby="playground-files" className={rootClassName}>
      <div className={headerClassName}>
        <h2 className={titleClassName} id="playground-files">
          Files
        </h2>
        <button aria-label="New file" className={newFileClassName} onClick={actions.createFile} title="New file" type="button">
          <FilePlusIcon aria-hidden />
        </button>
      </div>
      <div className={scrollClassName}>{renderChildren(tree, 0)}</div>
    </nav>
  );
}
