import { render, take } from "./renderer.mjs";
import * as timeline from "./src/playground.ts";

await render({
  name: "playground",
  composition: "Playground",
  timeline,
  manifest: { take: take("playground", "playground.mp4"), share: take("playground-share", "playground-share.mp4") },
  manifestFile: "playground-manifest.json",
});
