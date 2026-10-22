// The rendering pipeline that every trailer's entry script shares: render-editor.mjs for the editor
// trailer and render-playground.mjs for the playground trailer. An entry script names its trailer,
// its composition and timeline module, and the takes it is cut from, then calls `render`, which
// takes these options:
//   (none)                       the whole trailer, its poster and chapter times
//   --still 240,1200             single frames, for checking a design
//   --frames 0-600               a range of frames, for checking motion
//   --encode                     the published encodes again, from the last master
//   --review rename,completion   review clips of those features, from the last encode
//   --scale 1                    a 1080p master instead of 4K, for checking a take
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

// One raw Cap export, copied into public/ as `src`. The exports play at recorded speed, and the
// recorders write their pacing beside them.
export function take(clip, src) {
  const raw = `${tools}/${clip}-raw.mp4`;
  mkdirSync(`${here}/public`, { recursive: true });
  copyFileSync(raw, `${here}/public/${src}`);
  const probe = (entry) => execFileSync("ffprobe", ["-v", "error", "-select_streams", "v", "-show_entries", entry, "-of", "csv=p=0", raw], { encoding: "utf8" }).trim();
  const [width] = probe("stream=width,height").split(",").map(Number);
  const pace = JSON.parse(readFileSync(`${recordings}/${clip}.pace.json`, "utf8"));
  return { src, width, duration: Number(probe("format=duration")), ...pace };
}

// `name` prefixes the outputs in out/, `composition` is the Remotion composition's id, `timeline`
// is the module that plans it (with `plan` and `chapters`), and `manifest` is written to
// public/`manifestFile`, where Remotion Studio fetches it.
export async function render({ name, composition: id, timeline: { plan, chapters }, manifest, manifestFile }) {
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
      // The master's size, as a multiple of the composition's. 1 renders a 1080p master, for checking
      // a take faster; publish only from the 4K master.
      scale: { type: "string", default: "2" },
    },
  });
  writeFileSync(`${here}/public/${manifestFile}`, JSON.stringify(manifest, null, 2));

  if (values.review) {
    const marks = chapters(plan(manifest).markers);
    const total = Number(execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
      `${values.output}/${name}.mp4`], { encoding: "utf8" }));
    mkdirSync(`${values.output}/review`, { recursive: true });
    for (const slug of values.review.split(",")) {
      const index = marks.findIndex((mark) => mark.slug === slug);
      if (index < 0) throw new Error(`No feature ${slug}; choose from ${marks.map((mark) => mark.slug).join(", ")}`);
      // From a second before the feature starts to a second into the next feature.
      const from = Math.max(0, marks[index].at - 1);
      const to = Math.min(total, (marks[index + 1]?.at ?? total) + 1);
      const output = `${values.output}/review/${String(index + 1).padStart(2, "0")}-${slug}.mp4`;
      execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-ss", String(from), "-to", String(to),
        "-i", `${values.output}/${name}.mp4`, "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart", output]);
      console.log(output);
    }
    return;
  }

  const serveUrl = await bundle({ entryPoint: `${here}/src/index.ts` });
  const inputProps = { manifest };
  const composition = await selectComposition({ serveUrl, id, inputProps });
  mkdirSync(values.output, { recursive: true });
  const concurrency = Math.max(1, Math.floor(cpus().length / 2));

  // The published encodes, scaled down from the 4K master: AV1 for browsers that decode it, and an
  // H.264 fallback at level 4.2, which every browser and phone that plays 1080p60 decodes. Both start
  // playing before they finish downloading. The poster is the opening lockup once the logo, wordmark
  // and command have settled.
  const master = `${values.output}/${name}-master.mp4`;
  function encode() {
    const ffmpeg = (...args) => execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-i", master, ...args]);
    const scale = ["-vf", "scale=1920:1080:flags=lanczos", "-pix_fmt", "yuv420p", "-an", "-movflags", "+faststart"];
    ffmpeg(...scale, "-c:v", "libsvtav1", "-preset", "5", "-crf", values["av1-crf"], "-g", "240", "-svtav1-params", "tune=0",
      `${values.output}/${name}-av1.mp4`);
    ffmpeg(...scale, "-c:v", "libx264", "-preset", "slow", "-crf", values.crf, "-profile:v", "high", "-level:v", "4.2",
      `${values.output}/${name}.mp4`);
    execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-ss", "3.6", "-i", master,
      "-vf", "scale=1920:1080:flags=lanczos", "-frames:v", "1", "-c:v", "libwebp", "-quality", "85", `${values.output}/${name}.webp`]);
  }
  if (values.encode) {
    encode();
    console.log(values.output);
    return;
  }

  if (values.still) {
    for (const frame of values.still.split(",").map(Number)) {
      const output = `${values.output}/${name}-still-${frame}.png`;
      await renderStill({ serveUrl, composition, inputProps, frame, output });
      console.log(output);
    }
    return;
  }

  const frameRange = values.frames ? values.frames.split("-").map(Number) : null;
  // The master renders at 4K by default, twice the composition's size, so that type, the lattice and
  // the take's edges are supersampled when the published encode scales it back down to 1080p.
  let last = -1;
  await renderMedia({
    serveUrl,
    composition,
    inputProps,
    codec: "h264",
    scale: Number(values.scale),
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
    return;
  }

  encode();
  console.log(JSON.stringify(chapters(plan(manifest).markers), null, 2));
  console.log(values.output);
}
