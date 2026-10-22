// What every trailer shares about its takes: the composition's size and rate, the cards' timing, the
// pacing the recorders write beside each take, and the helpers that plan a take onto frames.

export const fps = 60;
export const width = 1920;
export const height = 1080;
// The cards' left edge.
export const margin = 120;

export type Box = [left: number, top: number, right: number, bottom: number];
// A caption names one semantic role and underlines its tokens. `anchor.end` is where the anchor
// token's line ends, in device pixels, so that the caption's leader never crosses code.
export type Caption = { t: number; label: string; color: string; boxes: Box[]; anchor: { box: Box; end: number } };
// The pacing a recorder writes beside a take (recorder.mjs's capture), on the take's own timeline,
// in seconds: where the scripted work starts and ends, each feature's beat, and the captions.
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

// Scene lengths, in seconds.
export const timing = {
  // The command finishes typing at 3.45 s; its caret completes one blink before the take fades in.
  open: 5.3,
  // A take fades in under the opening's exit and out under the end card's entrance.
  crossfade: 0.8,
  end: 6.5,
};
// A take's last result has this long to read before it leaves.
export const tail = 1.6;

export const sec = (seconds: number) => Math.round(seconds * fps);

// When the take's beat for `slug` plays, on the take's timeline.
export function beat(take: Take, slug: string) {
  const found = take.beats.find((b) => b.slug === slug);
  if (!found) throw new Error(`The take has no beat for ${slug}`);
  return found.t;
}

// Source times for each frame from `from` to `to`, at recorded speed except for the stretches given
// their own rate.
export function retime(from: number, to: number, fast: [start: number, end: number, rate: number][] = []) {
  const times: number[] = [];
  for (let t = from; t < to; ) {
    times.push(t);
    const stretch = fast.find(([start, end]) => t >= start && t < end);
    t += (stretch ? stretch[2] : 1) / fps;
  }
  return times;
}

// Chapter start times in seconds, for a chapter list: when each feature's beat plays.
export const chapters = (markers: { feature: { slug: string; title: string }; from: number }[]) =>
  markers.map((marker) => ({ slug: marker.feature.slug, title: marker.feature.title, at: Math.round((marker.from / fps) * 10) / 10 }));
