import { layoutField, makeField, makeOcean, palette } from "#src/Website/Components/Backdrop.js";

// Fade the site's actual coloured ocean in and out; flow while interacting.
export function createNavigationOcean(canvas) {
  const context = canvas.getContext("2d");
  const motion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const seed = 5139;
  const density = 2.5;
  const ocean = makeOcean(seed);
  const epoch = performance.now();
  let from = makeField(seed);
  let to = makeField(seed + 1);
  let step = 0;
  let blend = 0;
  let active = false;
  let reveal = 0;
  let pulseStart = -Infinity;
  let frame = 0;
  let lastTime = 0;
  let width = 0;
  let height = 0;
  let colors = [];
  const field = {
    ocean,
    noise: (x, y) => from.noise(x, y) * (1 - blend) + to.noise(x, y) * blend,
    hue: (x, y) => from.hue(x, y) * (1 - blend) + to.hue(x, y) * blend,
  };
  const smooth = t => t * t * (3 - 2 * t);
  const clear = () => {
    context?.clearRect(0, 0, width, height);
    canvas.removeAttribute("data-ocean");
    reveal = 0;
    lastTime = 0;
  };
  const fit = () => {
    width = canvas.clientWidth;
    height = canvas.clientHeight;
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    const pixelWidth = Math.round(width * ratio);
    const pixelHeight = Math.round(height * ratio);
    if (canvas.width !== pixelWidth || canvas.height !== pixelHeight) {
      canvas.width = pixelWidth;
      canvas.height = pixelHeight;
    }
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    const style = getComputedStyle(canvas);
    colors = palette.map(token => style.getPropertyValue(token).trim());
  };
  const schedule = () => { if (!frame) frame = requestAnimationFrame(draw); };
  const draw = now => {
    frame = 0;
    if (motion.matches || !width || !height) { clear(); return; }
    const elapsed = now - epoch;
    const delta = lastTime ? Math.min(now - lastTime, 50) : 16;
    lastTime = now;
    const opening = active || now - pulseStart < 650;
    reveal = Math.max(0, Math.min(1, reveal + delta / (opening ? 350 : -240)));
    if (!reveal && !opening) { clear(); return; }
    const nextStep = Math.floor(elapsed / 2600);
    if (nextStep !== step) {
      step = nextStep;
      from = makeField(seed + step);
      to = makeField(seed + step + 1);
    }
    blend = smooth(elapsed / 2600 - step);
    const opacity = smooth(reveal);
    const pressure = Math.exp(-(now - pulseStart) / 240);
    context.clearRect(0, 0, width, height);
    canvas.setAttribute("data-ocean", "");
    for (const dot of layoutField(width * density, height * density, elapsed, field, null, false)) {
      const x = dot.x / density;
      const y = dot.y / density;
      context.fillStyle = colors[dot.color];
      context.globalAlpha = dot.alpha * opacity * (0.55 + pressure * 0.15);
      context.beginPath();
      context.arc(x, y, dot.radius / density * 1.6, 0, Math.PI * 2);
      context.fill();
    }
    context.globalAlpha = 1;
    schedule();
  };
  const onMotion = () => {
    cancelAnimationFrame(frame);
    frame = 0;
    clear();
    if (context && active && !motion.matches) { fit(); schedule(); }
  };
  motion.addEventListener("change", onMotion);
  return {
    setActive(value) {
      active = value;
      if (!context || motion.matches) return;
      if (active) fit();
      schedule();
    },
    pulse() {
      if (!context || motion.matches) return;
      fit();
      pulseStart = performance.now();
      schedule();
    },
    stop() {
      active = false;
      cancelAnimationFrame(frame);
      motion.removeEventListener("change", onMotion);
      clear();
    },
  };
}
