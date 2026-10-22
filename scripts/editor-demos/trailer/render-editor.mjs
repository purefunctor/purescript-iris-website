// Renders the editor trailer from the one-shot Cap take that `editor.mjs trailer` exports, to
// out/trailer*. Run from this directory after recording it; renderer.mjs lists the options.
import { render, take } from "./renderer.mjs";
// Node strips the types from the composition's plain TypeScript modules.
import * as timeline from "./src/editor.ts";

await render({
  name: "trailer",
  composition: "Trailer",
  timeline,
  manifest: { take: take("trailer", "take.mp4") },
  manifestFile: "manifest.json",
});
