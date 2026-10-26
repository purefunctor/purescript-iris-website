import { createElement, useEffect, useId, useRef, useState } from "react";

const isPlainPrimaryClick = event =>
  !event.defaultPrevented && event.button === 0 && !(event.metaKey || event.ctrlKey || event.shiftKey || event.altKey);

const linksToCurrentPage = href => {
  const target = new URL(href, window.location.href);
  return target.origin === window.location.origin && target.pathname === window.location.pathname;
};

const isKeyboardActivation = clickEvent => clickEvent.detail === 0;

export const scrollToTop = event => {
  if (!isPlainPrimaryClick(event) || !linksToCurrentPage(event.currentTarget.href)) return;

  event.preventDefault();
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  window.scrollTo({ top: 0, behavior: reduced ? "auto" : "smooth" });
  if (window.location.hash) history.replaceState(history.state, "", window.location.pathname + window.location.search);
};

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

export function spectrumInstallButtonImpl({ className, pressedClassName, label, onPress, content }) {
  const [pressed, setPressed] = useState(false);
  const button = useRef(null);

  useEffect(() => {
    if (!pressed) return undefined;
    let current = true;
    const moving = button.current.getAnimations({ subtree: true }).map(animation => animation.finished);
    Promise.allSettled(moving).then(() => {
      if (current) setPressed(false);
    });
    return () => {
      current = false;
    };
  }, [pressed]);

  return createElement("button", {
    className: pressed ? pressedClassName : className,
    ref: button,
    type: "button",
    "aria-label": label,
    onPointerDown: event => {
      if (event.button === 0) setPressed(true);
    },
    onClick: event => {
      if (isKeyboardActivation(event)) setPressed(true);
      onPress();
    },
  }, ...content);
}
