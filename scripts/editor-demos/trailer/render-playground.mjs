// Renders the playground trailer from the two Cap takes that `playground.mjs` exports, to
// out/playground*. Run from this directory after recording them; renderer.mjs lists the options.
import { render, take } from "./renderer.mjs";
// Node strips the types from the composition's plain TypeScript modules.
import * as timeline from "./src/playground.ts";

await render({
  name: "playground",
  composition: "Playground",
  timeline,
  manifest: { take: take("playground", "playground.mp4"), share: take("playground-share", "playground-share.mp4") },
  manifestFile: "playground-manifest.json",
});
