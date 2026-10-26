export const revealInstall = installRef => onRevealed => () => {
  const install = installRef.current;
  if (!install) return;

  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const navHeight = parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--nav-height")) || 0;
  const bounds = install.getBoundingClientRect();
  const finish = () => {
    install.querySelector("[role=tabpanel] button")?.focus({ preventScroll: true });
    onRevealed();
  };

  if (bounds.top >= navHeight && bounds.bottom <= window.innerHeight) {
    finish();
    return;
  }

  (install.closest("section") ?? install).scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "start" });
  if (reduced) {
    finish();
    return;
  }

  const started = performance.now();
  let done = false;
  let frame = 0;
  let lastY = window.scrollY;
  let moved = false;
  let still = 0;
  const settle = () => {
    if (done) return;
    done = true;
    cancelAnimationFrame(frame);
    window.removeEventListener("scrollend", settle);
    finish();
  };
  const watch = now => {
    if (window.scrollY !== lastY) {
      lastY = window.scrollY;
      moved = true;
      still = 0;
    } else {
      still++;
    }
    const elapsed = now - started;
    if ((moved && still >= 6) || (!moved && elapsed > 300) || elapsed > 4000) settle();
    else frame = requestAnimationFrame(watch);
  };
  window.addEventListener("scrollend", settle);
  frame = requestAnimationFrame(watch);
};

export const enableCopyEditing = () => {
  if (!import.meta.env.DEV || !new URLSearchParams(window.location.search).has("edit")) return () => {};
  document.designMode = "on";
  document.documentElement.spellcheck = false;
  return () => {
    document.designMode = "off";
  };
};
