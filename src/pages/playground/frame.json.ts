import type { APIRoute } from "astro";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { layerOrder } from "#src/lib/inlineStyles";

export const prerender = true;

// The design system for the frame that playground programs run in, which is a separate document
// without network access: the site's tokens, base styles for the elements programs render, and
// its fonts. The runner sends this to every frame, so programs inherit the site's look, and their
// StyleX styles can use its tokens. Base styles stay in the reset layer, below StyleX's layers.
const FONTS = [
  { family: "Geist Variable", file: "node_modules/@fontsource-variable/geist/files/geist-latin-wght-normal.woff2" },
  {
    family: "Geist Mono Variable",
    file: "node_modules/@fontsource-variable/geist-mono/files/geist-mono-latin-wght-normal.woff2",
  },
];

export const GET: APIRoute = async () => {
  const global = await readFile(resolve("src/global.css"), "utf8");
  // The token block is copied whole, since some values, such as data URLs, contain semicolons.
  const start = global.indexOf(":root {");
  const root = global.slice(start, global.indexOf("\n  }", start) + "\n  }".length);
  const css = `${layerOrder}
@layer reset {
  ${root}
  *, ::before, ::after { box-sizing: border-box; }
  html {
    background-color: var(--granite-950);
    color: var(--text-primary);
    color-scheme: dark;
    font-family: var(--font-sans);
    font-size: 14px;
    font-synthesis: none;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
  }
  body { margin: 0; }
  button, input, select, textarea { color: inherit; font: inherit; }
  ::selection { background: var(--selection); }
}
`;
  const fonts = await Promise.all(
    FONTS.map(async ({ family, file }) => ({ family, data: (await readFile(resolve(file))).toString("base64") })),
  );
  return new Response(JSON.stringify({ css, fonts }), { headers: { "Content-Type": "application/json" } });
};
