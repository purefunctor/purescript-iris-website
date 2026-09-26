export const observeAlphaDock = ({ banner, header, onDock }) => () => {
  let frame = 0;
  let docked = false;

  const check = () => {
    frame = 0;
    if (!banner.current || !header.current) return;

    const next = banner.current.getBoundingClientRect().bottom <= header.current.getBoundingClientRect().bottom;
    if (next !== docked) {
      docked = next;
      onDock(next)();
    }
  };
  const schedule = () => {
    if (!frame) frame = requestAnimationFrame(check);
  };

  window.addEventListener("scroll", schedule, { passive: true });
  window.addEventListener("resize", schedule);
  schedule();

  return () => {
    window.removeEventListener("scroll", schedule);
    window.removeEventListener("resize", schedule);
    if (frame) cancelAnimationFrame(frame);
  };
};
