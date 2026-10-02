// Noise-driven dot lattice floating on a Gerstner-wave surface. The field morphs from one noise
// seed to the next instead of scrolling, and holds a still frame when motion is reduced.
const seed = 5139;
const spacing = 22;
const clearRadius = 0.62;
const morphMilliseconds = 2600;
const palette = [
  "--spectrum-red",
  "--spectrum-orange",
  "--spectrum-yellow",
  "--spectrum-green",
  "--spectrum-blue",
  "--spectrum-indigo",
  "--spectrum-violet",
];

const random = state => () => {
  state = (state ^ (state << 13)) >>> 0;
  state = (state ^ (state >>> 17)) >>> 0;
  state = (state ^ (state << 5)) >>> 0;
  return state / 4294967296;
};

function makeNoise(noiseSeed) {
  const next = random((noiseSeed * 2654435761) >>> 0 || 1);
  const permutation = Array.from({ length: 256 }, (_, index) => index);
  for (let index = 255; index > 0; index--) {
    const swap = Math.floor(next() * (index + 1));
    [permutation[index], permutation[swap]] = [permutation[swap], permutation[index]];
  }
  const p = new Uint8Array(512);
  for (let index = 0; index < 512; index++) p[index] = permutation[index & 255];
  const values = new Float32Array(256).map(() => next());
  const smooth = t => t * t * (3 - 2 * t);
  const value = (x, y) => {
    const xi = Math.floor(x);
    const yi = Math.floor(y);
    const X = xi & 255;
    const Y = yi & 255;
    const a = values[p[p[X] + Y]];
    const b = values[p[p[X + 1] + Y]];
    const c = values[p[p[X] + Y + 1]];
    const d = values[p[p[X + 1] + Y + 1]];
    const u = smooth(x - xi);
    const v = smooth(y - yi);
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
  };
  return (x, y) => value(x, y) * 0.57 + value(x * 2.03, y * 2.03) * 0.29 + value(x * 4.1, y * 4.1) * 0.14;
}

const smoothstep = (a, b, x) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

function makeOcean(oceanSeed) {
  const next = random(((oceanSeed + 29) * 2246822519) >>> 0 || 1);
  const base = next() * Math.PI * 2;
  const waves = Array.from({ length: 4 }, (_, index) => {
    const direction = base + (next() - 0.5) * 1.6;
    const length = (520 / (1 + index * 0.7)) * (0.8 + next() * 0.4);
    return {
      dx: Math.cos(direction),
      dy: Math.sin(direction),
      k: (Math.PI * 2) / length,
      amplitude: spacing * (0.62 / (1 + index * 0.6)) * (0.8 + next() * 0.4),
      frequency: ((Math.PI * 2) / (6.5 + next() * 3.5)) * Math.sqrt(520 / length),
      phase: next() * Math.PI * 2,
    };
  });
  const total = waves.reduce((sum, wave) => sum + wave.amplitude, 0);
  return (x, y, t) => {
    let ox = 0;
    let oy = 0;
    let z = 0;
    for (const wave of waves) {
      const theta = wave.k * (wave.dx * x + wave.dy * y) - wave.frequency * t + wave.phase;
      const cos = Math.cos(theta);
      ox += 0.7 * wave.amplitude * wave.dx * cos;
      oy += 0.7 * wave.amplitude * wave.dy * cos;
      z += wave.amplitude * Math.sin(theta);
    }
    return [x + ox, y + oy, z / total];
  };
}

export const startField = canvasRef => () => {
  const canvas = canvasRef.current;
  const context = canvas?.getContext("2d");
  if (!context) return () => {};

  const motion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const ocean = makeOcean(seed);
  const field = fieldSeed => ({ noise: makeNoise(fieldSeed), hue: makeNoise(fieldSeed + 7) });
  let from = field(seed);
  let to = field(seed + 1);
  let step = 0;
  let segmentStart = null;
  let blend = 0;
  let lastTime = 0;
  let width = 0;
  let height = 0;
  let frame = 0;
  let visible = true;
  let colors = [];
  const noise = (x, y) => (blend ? from.noise(x, y) * (1 - blend) + to.noise(x, y) * blend : from.noise(x, y));
  const hue = (x, y) => (blend ? from.hue(x, y) * (1 - blend) + to.hue(x, y) * blend : from.hue(x, y));

  const resize = () => {
    const ratio = Math.min(2, window.devicePixelRatio || 1);
    width = canvas.clientWidth;
    height = canvas.clientHeight;
    canvas.width = width * ratio;
    canvas.height = height * ratio;
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    const style = getComputedStyle(canvas);
    colors = palette.map(name => style.getPropertyValue(name).trim() || "gray");
  };

  const draw = time => {
    lastTime = time;
    if (!motion.matches && time) {
      if (segmentStart == null) segmentStart = time;
      while (time - segmentStart >= morphMilliseconds) {
        segmentStart += morphMilliseconds;
        step++;
        from = to;
        to = field(seed + step + 1);
      }
      blend = smoothstep(0, 1, (time - segmentStart) / morphMilliseconds);
    }
    context.clearRect(0, 0, width, height);
    if (!width || !height) return;

    const narrow = width < 1100;
    const rowHeight = spacing * 0.866;
    const scale = 1 / Math.max(90, Math.min(260, Math.max(width, height) * 0.3));
    const hueScale = scale * 1.4;
    const points = [];
    for (let row = -1, y0 = -rowHeight; y0 < height + rowHeight; row++, y0 = row * rowHeight) {
      for (let column = -1, x0 = -spacing; x0 < width + spacing; column++, x0 = column * spacing) {
        const x = x0 + (row & 1 ? spacing / 2 : 0);
        const y = y0;
        const distance = Math.hypot(x, y) / Math.hypot(width, height);
        const mask = smoothstep(clearRadius * 0.58, clearRadius, distance) * (narrow ? 0.55 : 1);
        if (mask < 0.02) continue;
        const [px, py, z] = ocean(x, y, time / 1000);
        points.push([px, py, mask, noise(x * scale, y * scale), hue(x * hueScale + 3, y * hueScale + 3), z]);
      }
    }
    if (!points.length) return;

    // Threshold at a percentile so roughly half of the visible points swell, and rank hues so
    // each palette step receives an even share of patches.
    const noises = points.map(point => point[3]).sort((a, b) => a - b);
    const hues = points.map(point => point[4]).sort((a, b) => a - b);
    const rank = value => {
      let low = 0;
      let high = hues.length;
      while (low < high) {
        const middle = (low + high) >> 1;
        if (hues[middle] < value) low = middle + 1;
        else high = middle;
      }
      return low / hues.length;
    };
    const low = noises[Math.floor(noises.length * 0.5)];
    const high = Math.max(low + 0.02, noises[Math.floor(noises.length * 0.95)]);
    for (const [x, y, mask, n, h, z] of points) {
      const edge = smoothstep(0.02, 0.55, mask);
      if (edge < 0.02) continue;
      const lift = 1 + z * 0.45;
      const value = smoothstep(low, high, n) * mask;
      context.fillStyle = colors[Math.min(colors.length - 1, Math.floor(rank(h) * colors.length))];
      context.globalAlpha = Math.min(1, (0.45 + value * 0.55) * edge * (0.82 + z * 0.22));
      context.beginPath();
      context.arc(x, y, spacing * (0.03 * (0.4 + 0.6 * edge) + value * 0.045) * lift, 0, Math.PI * 2);
      context.fill();
    }
    context.globalAlpha = 1;
  };

  const loop = time => {
    draw(time);
    frame = requestAnimationFrame(loop);
  };
  const update = () => {
    cancelAnimationFrame(frame);
    frame = 0;
    if (visible && !motion.matches) frame = requestAnimationFrame(loop);
    else draw(lastTime);
  };

  const resizeObserver = new ResizeObserver(() => {
    resize();
    draw(lastTime);
  });
  const intersectionObserver = new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting;
    update();
  });
  resize();
  draw(0);
  resizeObserver.observe(canvas);
  intersectionObserver.observe(canvas);
  motion.addEventListener("change", update);

  return () => {
    cancelAnimationFrame(frame);
    resizeObserver.disconnect();
    intersectionObserver.disconnect();
    motion.removeEventListener("change", update);
  };
};
