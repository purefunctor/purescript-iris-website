#!/usr/bin/env node
/** Run from the website root: node scripts/render-readme-banner.mjs <output.webp> */
import sharp from "sharp";
import { createServer } from "vite";

const output = process.argv[2];
if (!output) throw new Error("Usage: node scripts/render-readme-banner.mjs <output.webp>");

// Load the same TypeScript renderer and package aliases as Astro, without starting a web server.
const vite = await createServer({
  configFile: false,
  server: { middlewareMode: true },
  optimizeDeps: { noDiscovery: true, include: [] },
});
try {
  const { renderOpenGraphImage } = await vite.ssrLoadModule("/src/lib/openGraphImage.ts");
  const image = await renderOpenGraphImage({ seed: 5138, height: 320 });
  await sharp(image).webp({ lossless: true }).toFile(output);
} finally {
  await vite.close();
}

console.log(`Rendered 1200 × 320 README banner to ${output}`);
