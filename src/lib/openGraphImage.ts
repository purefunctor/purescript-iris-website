import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import React from "react";
import satori from "satori";
import sharp from "sharp";
import { readColorTokens } from "#src/lib/colorTokens";
import { renderFavicon } from "#src/lib/favicon";
import { palette, stillField } from "#src/Website/Components/Backdrop.js";

const width = 1200;
const height = 630;
const markSize = 272;
// Social previews are shown at a fraction of full size, so the field's dots are drawn larger.
const dotScale = 1.8;

/** Render the build-time social image: the site icon and wordmark centred on the hero's still dot field. */
export async function renderOpenGraphImage({ seed }: { seed?: number } = {}): Promise<Uint8Array> {
  const [color, black, mark] = await Promise.all([
    readColorTokens(),
    readFile(resolve("node_modules/@fontsource/geist/files/geist-latin-900-normal.woff")),
    renderFavicon({ disc: false }).then((svg) =>
      sharp(Buffer.from(svg), { density: (markSize / 32) * 72 * 2 }).resize(markSize * 2).png().toBuffer(),
    ),
  ]);
  const background = await renderField(color, seed);

  const svg = await satori(
    React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        width,
        height,
        backgroundColor: color["bg-canvas"],
        backgroundImage: `url(data:image/png;base64,${background.toString("base64")})`,
        color: color["text-primary"],
        fontFamily: "Geist",
      },
    },
      React.createElement("img", {
        src: `data:image/png;base64,${mark.toString("base64")}`,
        width: markSize,
        height: markSize,
      }),
      React.createElement("div", { style: { fontSize: 288, fontWeight: 900, letterSpacing: -11.5, lineHeight: 1 } }, "IRIS"),
    ),
    { width, height, fonts: [{ name: "Geist", data: black, weight: 900, style: "normal" }] },
  );

  return sharp(Buffer.from(svg)).png().toBuffer();
}

/** The hero's dot field without its clearing, dimmed behind the lockup, plus grain, rasterised so Satori embeds a single image. */
function renderField(color: Record<string, string>, seed?: number): Promise<Buffer> {
  const fills = palette.map((token) => color[token.slice(2)]);
  const dots = stillField(width, height, { clearing: false, seed })
    .map(({ x, y, radius, alpha, color: index }) =>
      `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(radius * dotScale).toFixed(2)}" fill="${fills[index]}" fill-opacity="${alpha.toFixed(3)}"/>`,
    )
    .join("");
  const canvas = color["bg-canvas"];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <defs>
      <filter id="grain" x="0" y="0" width="100%" height="100%">
        <feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="3" stitchTiles="stitch"/>
        <feColorMatrix type="saturate" values="0"/>
      </filter>
    </defs>
    <rect width="100%" height="100%" fill="${canvas}"/>
    ${dots}
    <rect width="100%" height="100%" fill="${canvas}" opacity="0.35"/>
    <rect width="100%" height="100%" filter="url(#grain)" opacity="0.09" style="mix-blend-mode:overlay"/>
  </svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer();
}
