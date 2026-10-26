import { acts, type Act, type Feature } from "./chapters.ts";
import { beat, fps, retime, sec, tail, timing, type Take } from "./takes.ts";

export { chapters } from "./takes.ts";
export type Manifest = { take: Take };

export type Marker = { feature: Feature; index: number; act: Act; from: number };
export type Scene = { kind: "open"; from: number; duration: number } | { kind: "end"; from: number; duration: number };

export function plan({ take }: Manifest) {
  const times = retime(Math.max(0, take.beats[0].t - 0.8), Math.min(take.duration - 1 / fps, take.last + tail));
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
      markers.push({ feature, index: index++, act, from: frameAt(beat(take, feature.slug)) });
  });
  const endFrom = from + times.length - fade;
  const scenes: Scene[] = [
    { kind: "open", from: 0, duration: sec(timing.open) },
    { kind: "end", from: endFrom, duration: sec(timing.end) },
  ];
  return { scenes, track, markers, frameAt, duration: endFrom + sec(timing.end) };
}
