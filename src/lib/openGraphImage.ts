import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import React from "react";
import satori from "satori";
import sharp from "sharp";

const width = 1200;
const height = 630;

/** Render a page-specific, build-time social image; newlines balance longer headlines. */
export async function renderOpenGraphImage(headline: string): Promise<Uint8Array> {
  const [wordmarkFont, bodyFont, background] = await Promise.all([
    readFile(resolve("node_modules/@fontsource/bruno-ace/files/bruno-ace-latin-400-normal.woff")),
    readFile(resolve("node_modules/@fontsource/inter/files/inter-latin-400-normal.woff")),
    sharp(resolve("src/assets/iris-digital-field.webp"))
      .resize(width, height, { fit: "cover" })
      .jpeg({ quality: 85 })
      .toBuffer(),
  ]);

  const svg = await satori(
    React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        width,
        height,
        position: "relative",
        overflow: "hidden",
        backgroundColor: "#faf9ff",
        color: "#33314b",
      },
    },
      React.createElement("img", {
        src: `data:image/jpeg;base64,${background.toString("base64")}`,
        style: { position: "absolute", width, height, top: 0, left: 0 },
      }),
      React.createElement("div", {
        style: {
          display: "flex",
          flexDirection: "column",
          width: 950,
          paddingLeft: 82,
          position: "relative",
        },
      },
        React.createElement("div", {
          style: {
            fontFamily: "Bruno Ace",
            fontSize: 180,
            letterSpacing: -10,
            lineHeight: 1,
          },
        }, "IRIS"),
        React.createElement("div", {
          style: {
            display: "flex",
            flexDirection: "column",
            fontFamily: "Inter",
            fontSize: 44,
            fontWeight: 400,
            lineHeight: 1.18,
            maxWidth: 860,
            marginTop: 24,
          },
        }, ...headline.split("\n").map((line) =>
          React.createElement("div", { key: line, style: { display: "flex" } }, line),
        )),
      ),
      React.createElement("div", {
        style: {
          position: "absolute",
          display: "flex",
          bottom: 48,
          left: 84,
          fontFamily: "Inter",
          fontSize: 23,
          letterSpacing: 1,
          color: "#595077",
        },
      }, "iris-lang.com"),
    ),
    {
      width,
      height,
      fonts: [
        { name: "Bruno Ace", data: wordmarkFont, weight: 400, style: "normal" },
        { name: "Inter", data: bodyFont, weight: 400, style: "normal" },
      ],
    },
  );

  return sharp(Buffer.from(svg)).png().toBuffer();
}
