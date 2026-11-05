const durationMilliseconds = 900;

export const countIn = rootRef => className => () => {
  const root = rootRef.current;
  if (!root || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return () => {};
  const targets = [...root.getElementsByClassName(className)]
    .map(element => ({ element, value: element.textContent }))
    .filter(({ value }) => /^\d+(\.\d+)?$/.test(value));
  let frame = 0;
  const render = progress => {
    for (const { element, value } of targets) {
      const decimals = value.split(".")[1]?.length ?? 0;
      element.textContent = (Number(value) * progress).toFixed(decimals);
    }
  };
  const run = () => {
    const started = performance.now();
    const tick = now => {
      const t = Math.min(1, (now - started) / durationMilliseconds);
      render(1 - Math.pow(1 - t, 3));
      if (t < 1) frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
  };
  const observer = new IntersectionObserver(
    entries => {
      if (!entries.some(entry => entry.isIntersecting)) return;
      observer.disconnect();
      run();
    },
    { threshold: 0.5 },
  );
  observer.observe(root);
  return () => {
    observer.disconnect();
    cancelAnimationFrame(frame);
    render(1);
  };
};
