const stillFramesOnceSettled = 6;
const unmovedScrollTimeoutMilliseconds = 300;
const longestScrollMilliseconds = 4000;

const afterScrollSettles = onSettled => {
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
    onSettled();
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
    const stopped = moved && still >= stillFramesOnceSettled;
    const neverStarted = !moved && elapsed > unmovedScrollTimeoutMilliseconds;
    if (stopped || neverStarted || elapsed > longestScrollMilliseconds) settle();
    else frame = requestAnimationFrame(watch);
  };
  window.addEventListener("scrollend", settle);
  frame = requestAnimationFrame(watch);
};

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

  const hero = install.closest("section") ?? install;
  hero.scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "start" });
  if (reduced) {
    finish();
    return;
  }

  afterScrollSettles(finish);
};

export const enableCopyEditing = () => {
  if (!import.meta.env.DEV || !new URLSearchParams(window.location.search).has("edit")) return () => {};
  document.designMode = "on";
  document.documentElement.spellcheck = false;
  return () => {
    document.designMode = "off";
  };
};
