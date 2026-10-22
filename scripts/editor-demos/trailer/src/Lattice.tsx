import { useLayoutEffect, useMemo, useRef } from "react";
import { useCurrentFrame } from "remotion";
// The site's hero backdrop, rendered frame by frame instead of on requestAnimationFrame.
import { layoutField, makeField, makeOcean, palette } from "../../../../src/Website/Components/Backdrop.js";
import { fps, height, width } from "./editor";

const seed = 5139;
// The video is watched smaller than the page it borrows from, so the lattice is laid out at
// two-thirds size and drawn enlarged.
const scale = 1.5;
const morph = 2.6;
const rippleSpeed = 900;
const rippleWidth = 90;

export type Ripple = { x: number; y: number; frame: number };

const smoothstep = (a: number, b: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

// The noise fields for one moment: the field morphs into the next one every `morph` seconds.
const fields = new Map<number, ReturnType<typeof makeField>>();
const field = (step: number) => {
  if (!fields.has(step)) fields.set(step, makeField(seed + step));
  return fields.get(step)!;
};
const ocean = makeOcean(seed);

// `reveal` maps each point to how far the lattice has appeared there, from 0 to 1.
export function Lattice({
  ripples,
  reveal,
  clearing = true,
  opacity = 1,
}: {
  ripples: Ripple[];
  reveal?: (x: number, y: number) => number;
  clearing?: boolean;
  opacity?: number;
}) {
  const frame = useCurrentFrame();
  const canvas = useRef<HTMLCanvasElement>(null);
  const colors = useMemo(() => {
    const style = getComputedStyle(document.documentElement);
    return palette.map((name: string) => style.getPropertyValue(name).trim());
  }, []);

  useLayoutEffect(() => {
    const context = canvas.current?.getContext("2d");
    if (!context) return;
    // Remotion renders the 4K master at twice the composition's size; the canvas keeps up.
    const ratio = window.devicePixelRatio || 1;
    const seconds = frame / fps;
    const step = Math.floor(seconds / morph);
    const blend = smoothstep(0, 1, seconds / morph - step);
    const [from, to] = [field(step), field(step + 1)];
    const noise = (x: number, y: number) => from.noise(x, y) * (1 - blend) + to.noise(x, y) * blend;
    const hue = (x: number, y: number) => from.hue(x, y) * (1 - blend) + to.hue(x, y) * blend;
    const live = ripples
      .map((r) => ({ ...r, radius: ((frame - r.frame) / fps) * rippleSpeed, reach: Math.hypot(width, height) }))
      .filter((r) => r.radius >= 0 && r.radius < r.reach + rippleWidth);
    const ring = (x: number, y: number) => {
      [x, y] = [x * scale, y * scale];
      let strength = 0;
      let dx = 0;
      let dy = 0;
      for (const r of live) {
        const distance = Math.hypot(x - r.x, y - r.y) || 1;
        const wave = Math.exp(-(((distance - r.radius) / rippleWidth) ** 2)) * Math.sqrt(Math.max(0, 1 - r.radius / r.reach));
        if (wave > strength) [strength, dx, dy] = [wave, (x - r.x) / distance, (y - r.y) / distance];
      }
      return [strength, dx, dy];
    };
    const dots = layoutField(width / scale, height / scale, seconds * 1000, { noise, hue, ocean }, live.length ? ring : null, clearing);
    context.setTransform(1, 0, 0, 1, 0, 0);
    context.clearRect(0, 0, width * ratio, height * ratio);
    context.setTransform(scale * ratio, 0, 0, scale * ratio, 0, 0);
    for (const dot of dots) {
      const shown = reveal ? reveal(dot.x * scale, dot.y * scale) : 1;
      if (shown <= 0.01) continue;
      context.fillStyle = colors[dot.color];
      context.globalAlpha = dot.alpha * shown * opacity;
      context.beginPath();
      context.arc(dot.x, dot.y, dot.radius * (0.6 + 0.4 * shown), 0, Math.PI * 2);
      context.fill();
    }
    context.globalAlpha = 1;
  }, [frame, ripples, reveal, clearing, opacity, colors]);

  const ratio = typeof window === "undefined" ? 1 : window.devicePixelRatio || 1;
  return <canvas ref={canvas} width={width * ratio} height={height * ratio} style={{ position: "absolute", inset: 0, width, height }} />;
}
