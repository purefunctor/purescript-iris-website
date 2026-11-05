import { useEffect } from "react";

export { default as javaScriptIcon } from "~icons/material-icon-theme/javascript";
export { default as pureScriptIcon } from "~icons/material-icon-theme/purescript";

const focusToggle = () => document.getElementById("embed-sidebar-toggle")?.focus();

export const afterPick = (action) => () => {
  action();
  focusToggle();
};

export const useCloseOnEscapeImpl = ({ open, close }) => () =>
  useEffect(() => {
    if (!open) return;
    const onKeyDown = (event) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      close();
      focusToggle();
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open, close]);
