import { acts, features, type Act, type Feature } from "./chapters.ts";

export const fps = 60;
export const width = 1920;
export const height = 1080;

export type Box = [left: number, top: number, right: number, bottom: number];
// A caption names one semantic role and underlines its tokens. `anchor.end` is where the anchor
// token's line ends, in device pixels, so that the caption's leader never crosses code.
export type Caption = { t: number; label: string; color: string; boxes: Box[]; anchor: { box: Box; end: number } };
// The pacing record.mjs writes beside the take, on the take's own timeline, in seconds: where the
// scripted work starts and ends, each feature's beat, and the captions.
export type Take = {
  src: string;
  // The take's frame size; captions are in its pixels.
  width?: number;
  duration: number;
  first: number;
  last: number;
  beats: { slug: string; t: number }[];
  captions: Caption[];
};
export type Manifest = { take: Take };

// Scene lengths, in seconds.
export const timing = {
  // The command finishes typing at 3.45 s; its caret completes one blink before the take fades in.
  open: 5.3,
  // The take fades in under the opening's exit and out under the end card's entrance.
  crossfade: 0.8,
  // Each feature's name stays captioned over the take this long.
  marker: 2.8,
  end: 6.5,
};

// The take's last result has this long to read before it leaves.
const tail = 1.6;

export const margin = 120;

const sec = (seconds: number) => Math.round(seconds * fps);

// One feature's name, captioned over the take as the feature starts.
export type Marker = { feature: Feature; index: number; act: Act; from: number; duration: number };
export type Scene = { kind: "open"; from: number; duration: number } | { kind: "end"; from: number; duration: number };

export function plan({ take }: Manifest) {
  const beat = (slug: string) => {
    const found = take.beats.find((b) => b.slug === slug);
    if (!found) throw new Error(`The take has no beat for ${slug}`);
    return found.t;
  };
  // The take plays once at recorded speed, from just before its first feature to its last result.
  const start = Math.max(0, take.beats[0].t - 0.8);
  const end = Math.min(take.duration - 1 / fps, take.last + tail);
  const times: number[] = [];
  for (let t = start; t < end; t += 1 / fps) times.push(t);
  const from = sec(timing.open - timing.crossfade);
  const fade = sec(timing.crossfade);
  const track: { source: number; opacity: number }[] = [];
  times.forEach((source, f) => {
    track[from + f] = { source, opacity: Math.min(1, f / fade, (times.length - f) / fade) };
  });
  const frameAt = (source: number) => from + Math.max(0, times.findIndex((t) => t >= source));

  let index = 0;
  const markers: Marker[] = [];
  acts.forEach((act) => {
    for (const feature of act.features)
      markers.push({ feature, index: index++, act, from: frameAt(beat(feature.slug)), duration: sec(timing.marker) });
  });
  const endFrom = from + times.length - fade;
  const scenes: Scene[] = [
    { kind: "open", from: 0, duration: sec(timing.open) },
    { kind: "end", from: endFrom, duration: sec(timing.end) },
  ];
  return { scenes, track, markers, frameAt, duration: endFrom + sec(timing.end) };
}

// Chapter start times in seconds, for the landing page's chapter list: when each feature's caption appears.
export const chapters = (markers: Marker[]) =>
  markers.map((marker) => ({ slug: marker.feature.slug, title: marker.feature.title, at: Math.round((marker.from / fps) * 10) / 10 }));
