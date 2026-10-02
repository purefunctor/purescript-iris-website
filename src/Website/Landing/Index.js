// Brings the hero and its installation commands into view, scrolling only when they are off screen, then
// focuses the selected command's copy button and runs `onRevealed` once scrolling has settled.
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

  // The hero fills the first screen, so bring all of it back rather than only the commands.
  (install.closest("section") ?? install).scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "start" });
  if (reduced) {
    finish();
    return;
  }

  // Wait until scrolling has settled: `scrollend` where supported, otherwise a few frames
  // without movement. Safari lacks `scrollend`, and long smooth scrolls outlast a fixed delay.
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
