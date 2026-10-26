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
const reviewMarginSeconds = 1;
const settledOpeningLockupSeconds = "3.6";

export function take(clip, src) {
  const raw = `${tools}/${clip}-raw.mp4`;
  mkdirSync(`${here}/public`, { recursive: true });
  copyFileSync(raw, `${here}/public/${src}`);
  const probe = (entry) => execFileSync("ffprobe", ["-v", "error", "-select_streams", "v", "-show_entries", entry, "-of", "csv=p=0", raw], { encoding: "utf8" }).trim();
  const [width] = probe("stream=width,height").split(",").map(Number);
  const pace = JSON.parse(readFileSync(`${recordings}/${clip}.pace.json`, "utf8"));
  return { src, width, duration: Number(probe("format=duration")), ...pace };
}

export async function render({ name, composition: id, timeline: { plan, chapters }, manifest, manifestFile }) {
  const { values } = parseArgs({
    options: {
      still: { type: "string" },
      frames: { type: "string" },
      output: { type: "string", default: `${here}/out` },
      crf: { type: "string", default: "28" },
      "av1-crf": { type: "string", default: "52" },
      encode: { type: "boolean", default: false },
      review: { type: "string" },
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
      const from = Math.max(0, marks[index].at - reviewMarginSeconds);
      const to = Math.min(total, (marks[index + 1]?.at ?? total) + reviewMarginSeconds);
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

  const master = `${values.output}/${name}-master.mp4`;
  function encodePublished() {
    const ffmpeg = (...args) => execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-i", master, ...args]);
    const downscaleToStreamable1080p = ["-vf", "scale=1920:1080:flags=lanczos", "-pix_fmt", "yuv420p", "-an", "-movflags", "+faststart"];
    ffmpeg(...downscaleToStreamable1080p, "-c:v", "libsvtav1", "-preset", "5", "-crf", values["av1-crf"], "-g", "240", "-svtav1-params", "tune=0",
      `${values.output}/${name}-av1.mp4`);
    ffmpeg(...downscaleToStreamable1080p, "-c:v", "libx264", "-preset", "slow", "-crf", values.crf, "-profile:v", "high", "-level:v", "4.2",
      `${values.output}/${name}.mp4`);
    execFileSync("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-ss", settledOpeningLockupSeconds, "-i", master,
      "-vf", "scale=1920:1080:flags=lanczos", "-frames:v", "1", "-c:v", "libwebp", "-quality", "85", `${values.output}/${name}.webp`]);
  }
  if (values.encode) {
    encodePublished();
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

  encodePublished();
  console.log(JSON.stringify(chapters(plan(manifest).markers), null, 2));
  console.log(values.output);
}
