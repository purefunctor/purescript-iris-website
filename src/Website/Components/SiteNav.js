import { createElement, useEffect, useId, useRef, useState } from "react";

// On the page the brand links to, scroll back to the top instead of reloading. Modified and
// non-primary clicks keep their usual behaviour, such as opening a new tab.
export const scrollToTop = event => {
  if (event.defaultPrevented || event.button !== 0) return;
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  const target = new URL(event.currentTarget.href, window.location.href);
  if (target.origin !== window.location.origin || target.pathname !== window.location.pathname) return;

  event.preventDefault();
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  window.scrollTo({ top: 0, behavior: reduced ? "auto" : "smooth" });
  if (window.location.hash) history.replaceState(history.state, "", window.location.pathname + window.location.search);
};

// A non-modal disclosure keeps navigation in normal tab order and closes when it loses focus.
export function mobileNavigationImpl({ className, buttonClassName, panelClassName, openIcon, closeIcon, content }) {
  const [open, setOpen] = useState(false);
  const root = useRef(null);
  const trigger = useRef(null);
  const panelId = useId();

  useEffect(() => {
    if (!open) return;
    const outside = event => {
      if (!root.current.contains(event.target)) setOpen(false);
    };
    const resize = () => {
      if (!root.current.getClientRects().length) setOpen(false);
    };
    document.addEventListener("pointerdown", outside);
    window.addEventListener("resize", resize);
    return () => {
      document.removeEventListener("pointerdown", outside);
      window.removeEventListener("resize", resize);
    };
  }, [open]);

  return createElement("div", {
    className,
    ref: root,
    onBlur: event => {
      if (!event.currentTarget.contains(event.relatedTarget)) setOpen(false);
    },
    onKeyDown: event => {
      if (open && event.key === "Escape") {
        event.preventDefault();
        setOpen(false);
        trigger.current.focus();
      }
    },
  },
  createElement("button", {
    className: buttonClassName,
    ref: trigger,
    type: "button",
    "aria-label": open ? "Close navigation" : "Open navigation",
    "aria-expanded": open,
    "aria-controls": panelId,
    onClick: () => setOpen(value => !value),
  }, open ? closeIcon : openIcon),
  open && createElement("nav", {
    id: panelId,
    className: panelClassName,
    "aria-label": "Site navigation",
    onClick: event => {
      if (event.target.closest("a[href], button")) setOpen(false);
    },
  }, content));
}
