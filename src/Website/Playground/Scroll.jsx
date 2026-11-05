import SimpleBar from "simplebar-react";
import simplebarCss from "simplebar-react/dist/simplebar.min.css?inline";

const theme = `
.simplebar-scrollbar::before { background: var(--granite-500); border-radius: 0; left: 3px; right: 3px; }
.simplebar-scrollbar.simplebar-visible::before { opacity: 0.8; }
.simplebar-track.simplebar-vertical { width: 9px; }
.simplebar-track.simplebar-horizontal { height: 9px; }
.simplebar-track.simplebar-horizontal .simplebar-scrollbar::before { top: 3px; bottom: 3px; left: 0; right: 0; }
.simplebar-content-wrapper:focus-visible { outline: 2px solid var(--focus-ring); outline-offset: -2px; }
`;

if (typeof document !== "undefined" && !document.getElementById("iris-simplebar")) {
  const style = document.createElement("style");
  style.id = "iris-simplebar";
  style.textContent = simplebarCss + theme;
  document.head.append(style);
}

export const scrollImpl = ({ className, children }) => (
  <SimpleBar className={className} autoHide={false}>
    {({ scrollableNodeProps, contentNodeProps }) => (
      <div {...scrollableNodeProps} role={undefined} aria-label={undefined} tabIndex={-1}>
        <div {...contentNodeProps}>{children}</div>
      </div>
    )}
  </SimpleBar>
);

export const followingScrollImpl = ({ className, label, children, scrollRef, onScroll }) => (
  <SimpleBar className={className} ariaLabel={label} scrollableNodeProps={{ ref: scrollRef, onScroll }}>
    {children}
  </SimpleBar>
);
