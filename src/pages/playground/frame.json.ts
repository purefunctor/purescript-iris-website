import type { APIRoute } from "astro";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { layerOrder } from "#src/lib/inlineStyles";

export const prerender = true;

const FONTS = [
  { family: "Geist Variable", file: "node_modules/@fontsource-variable/geist/files/geist-latin-wght-normal.woff2" },
  {
    family: "Geist Mono Variable",
    file: "node_modules/@fontsource-variable/geist-mono/files/geist-mono-latin-wght-normal.woff2",
  },
];

export const GET: APIRoute = async () => {
  const css = `${layerOrder}
@layer reset {
  *, ::before, ::after { box-sizing: border-box; }
  html {
    background-color: oklch(16% 0.004 255);
    color: oklch(96.5% 0.002 255);
    color-scheme: dark;
    font-family: "Geist Variable", ui-sans-serif, system-ui, sans-serif;
    font-size: 14px;
    font-synthesis: none;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
  }
  body { margin: 0; }
  button, input, select, textarea { color: inherit; font: inherit; }
  ::selection { background: oklch(71% 0.19 44 / 30%); }
}
`;
  const fonts = await Promise.all(
    FONTS.map(async ({ family, file }) => ({ family, data: (await readFile(resolve(file))).toString("base64") })),
  );
  return new Response(JSON.stringify({ css, fonts }), { headers: { "Content-Type": "application/json" } });
};
