// Renders the editor trailer from the one-shot Cap take that `record.mjs trailer` exports. Run from
// this directory after recording it:
//   node render.mjs                 the whole trailer, its poster and chapter times
//   node render.mjs --still 240,1200  single frames, for checking a design
//   node render.mjs --frames 0-600  a range of frames, for checking motion
//   node render.mjs --encode        the published encodes again, from the last master
//   node render.mjs --review rename,completion  review clips of those features, from the last encode
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { cpus } from "node:os";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { bundle } from "@remotion/bundler";
import { renderMedia, renderStill, selectComposition } from "@remotion/renderer";

const here = fileURLToPath(new URL(".", import.meta.url));
const tools = process.env.IRIS_DEMO_HOME || "/tmp/iris-editor-tools";
const recordings = resolve(process.env.IRIS_DEMO_OUTPUT || `${tools}/recordings`);
const { values } = parseArgs({
  options: {
    still: { type: "string" },
    frames: { type: "string" },
    output: { type: "string", default: `${here}/out` },
    // The published 1080p encode. Zoom, motion and the lattice change most pixels, and CRF 28 keeps
    // zoomed text clean.
    crf: { type: "string", default: "28" },
    // AV1 matches the H.264 fallback on zoomed text and the dot lattice at about 40% fewer bytes.
    "av1-crf": { type: "string", default: "52" },
    // Re-encode the published files from an existing master without rendering it again.
    encode: { type: "boolean", default: false },
    // Cut the named features, by slug, from the last H.264 encode into out/review, for reviewing
    // changes to them without watching the whole trailer.
    review: { type: "string" },
  },
});

// Node strips the types from the composition's plain TypeScript modules.
const { plan, chapters } = await import("./src/timeline.ts");

// The raw Cap export plays at recorded speed; record.mjs writes its pacing beside the review copy.
mkdirSync(`${here}/public`, { recursive: true });
const raw = `${tools}/trailer-raw.mp4`;
copyFileSync(raw, `${here}/public/take.mp4`);
const probe = (entry) => execFileSync("ffprobe", ["-v", "error", "-select_streams", "v", "-show_entries", entry, "-of", "csv=p=0", raw], { encoding: "utf8" }).trim();
const duration = Number(probe("format=duration"));
const [takeWidth] = probe("stream=width,height").split(",").map(Number);
const pace = JSON.parse(readFileSync(`${recordings}/trailer.pace.json`, "utf8"));
const manifest = { take: { src: "take.mp4", width: takeWidth, duration, ...pace } };
writeFileSync(`${here}/public/manifest.json`, JSON.stringify(manifest, null, 2));

if (values.review) {
  const marks = chapters(plan(manifest).markers);
  const total = Number(execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
    `${values.output}/trailer.mp4`], { encoding: "utf8" }));
  mkdirSync(`${values.output}/review`, { recursive: true });
  for (const slug of values.review.split(",")) {
    const index = marks.findIndex((mark) => mark.slug === slug);
    if (index < 0) throw new Error(`No feature ${slug}; choose from ${marks.map((mark) => mark.slug).join(", ")}`);
    // From a second before the feature's caption to a second into the next feature.
    const from = Math.max(0, marks[index].at - 1);
    const to = Math.min(total, (marks[index + 1]?.at ?? total) + 1);
    const output = `${values.output}/review/${String(index + 1).padStart(2, "0")}-${slug}.mp4`;
    execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-ss", String(from), "-to", String(to),
      "-i", `${values.output}/trailer.mp4`, "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
      "-pix_fmt", "yuv420p", "-movflags", "+faststart", output]);
    console.log(output);
  }
  process.exit(0);
}

const serveUrl = await bundle({ entryPoint: `${here}/src/index.ts` });
const inputProps = { manifest };
const composition = await selectComposition({ serveUrl, id: "Trailer", inputProps });
mkdirSync(values.output, { recursive: true });
const concurrency = Math.max(1, Math.floor(cpus().length / 2));

// The published encodes, scaled down from the 4K master: AV1 for browsers that decode it, and an
// H.264 fallback at level 4.2, which every browser and phone that plays 1080p60 decodes. Both start
// playing before they finish downloading. The poster is the opening lockup once the logo, wordmark
// and command have settled.
const master = `${values.output}/trailer-master.mp4`;
function encode() {
  const ffmpeg = (...args) => execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-i", master, ...args]);
  const scale = ["-vf", "scale=1920:1080:flags=lanczos", "-pix_fmt", "yuv420p", "-an", "-movflags", "+faststart"];
  ffmpeg(...scale, "-c:v", "libsvtav1", "-preset", "5", "-crf", values["av1-crf"], "-g", "240", "-svtav1-params", "tune=0",
    `${values.output}/trailer-av1.mp4`);
  ffmpeg(...scale, "-c:v", "libx264", "-preset", "slow", "-crf", values.crf, "-profile:v", "high", "-level:v", "4.2",
    `${values.output}/trailer.mp4`);
  execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-ss", "3.6", "-i", master,
    "-vf", "scale=1920:1080:flags=lanczos", "-frames:v", "1", "-c:v", "libwebp", "-quality", "85", `${values.output}/trailer.webp`]);
}
if (values.encode) {
  encode();
  console.log(values.output);
  process.exit(0);
}

if (values.still) {
  for (const frame of values.still.split(",").map(Number)) {
    const output = `${values.output}/still-${frame}.png`;
    await renderStill({ serveUrl, composition, inputProps, frame, output });
    console.log(output);
  }
  process.exit(0);
}

const frameRange = values.frames ? values.frames.split("-").map(Number) : null;
// The master renders at 4K, twice the composition's size, so that type, the lattice and the take's
// edges are supersampled when the published encode scales it back down to 1080p.
let last = -1;
await renderMedia({
  serveUrl,
  composition,
  inputProps,
  codec: "h264",
  scale: 2,
  crf: 12,
  x264Preset: "veryfast",
  pixelFormat: "yuv420p",
  muted: true,
  concurrency,
  frameRange,
  outputLocation: master,
  onProgress: ({ progress }) => {
    const percent = Math.floor(progress * 100);
    if (percent % 5 === 0 && percent !== last) console.log(`${(last = percent)}%`);
  },
});
if (frameRange) {
  console.log(master);
  process.exit(0);
}

encode();
console.log(JSON.stringify(chapters(plan(manifest).markers), null, 2));
console.log(values.output);
