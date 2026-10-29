import { render, take } from "./renderer.mjs";
import * as timeline from "./src/editor.ts";

await render({
  name: "trailer",
  composition: "Trailer",
  timeline,
  manifest: { take: take("trailer", "take.mp4") },
  manifestFile: "manifest.json",
});
