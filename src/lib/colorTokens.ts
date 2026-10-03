import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

type Oklch = [lightness: number, chroma: number, hue: number];

/**
 * Read the opaque OKLCH color tokens from `src/global.css` as sRGB hex, for build-time renderers
 * such as Satori and librsvg that cannot parse `oklch()`. Resolves `var()` aliases and relative
 * `oklch(from var(--token) …)` colors whose channels are `l`, `c`, `h`, numbers, or
 * `calc(channel ± number)`; translucent and other tokens are skipped.
 */
export async function readColorTokens(): Promise<Record<string, string>> {
  const css = await readFile(resolve("src/global.css"), "utf8");
  const declarations = new Map(Array.from(css.matchAll(/--([\w-]+):\s*([^;]+);/g), ([, name, value]) => [name, value.trim()]));
  const resolved = new Map<string, Oklch | null>();
  const color = (name: string): Oklch | null => {
    if (resolved.has(name)) return resolved.get(name)!;
    resolved.set(name, null);
    const value = declarations.get(name) ?? "";
    let result: Oklch | null = null;
    let match;
    if ((match = value.match(/^var\(--([\w-]+)\)$/))) {
      result = color(match[1]);
    } else if ((match = value.match(/^oklch\(([\d.]+)%\s+([\d.]+)\s+([\d.]+)\)$/))) {
      result = [Number(match[1]) / 100, Number(match[2]), Number(match[3])];
    } else if ((match = value.match(/^oklch\(from var\(--([\w-]+)\)\s+(.+)\)$/))) {
      const base = color(match[1]);
      const channels = match[2].match(/calc\([^)]*\)|\S+/g) ?? [];
      const values = base && channels.length === 3 ? channels.map((channel) => evaluate(channel, base)) : [];
      if (values.length === 3 && values.every((value) => value != null)) result = values as Oklch;
    }
    resolved.set(name, result);
    return result;
  };
  const tokens: Record<string, string> = {};
  for (const name of declarations.keys()) {
    const value = color(name);
    if (value) tokens[name] = oklchToHex(value);
  }
  return tokens;
}

function evaluate(channel: string, [l, c, h]: Oklch): number | null {
  const match = channel.match(/^(?:calc\(\s*)?([lch]|[\d.]+)(?:\s*([+-])\s*([\d.]+))?\s*\)?$/);
  if (!match) return null;
  const operand = { l, c, h }[match[1]] ?? Number(match[1]);
  const offset = match[2] ? Number(match[3]) * (match[2] === "-" ? -1 : 1) : 0;
  return operand + offset;
}

function oklchToHex([lightness, chroma, hue]: Oklch): string {
  const a = chroma * Math.cos((hue * Math.PI) / 180);
  const b = chroma * Math.sin((hue * Math.PI) / 180);
  const l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (lightness - 0.0894841775 * a - 1.291485548 * b) ** 3;
  const linear = [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  ];
  return `#${linear
    .map((channel) => {
      const encoded = channel <= 0.0031308 ? 12.92 * channel : 1.055 * channel ** (1 / 2.4) - 0.055;
      return Math.round(Math.min(1, Math.max(0, encoded)) * 255).toString(16).padStart(2, "0");
    })
    .join("")}`;
}
