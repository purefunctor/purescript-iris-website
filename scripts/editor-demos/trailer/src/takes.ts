
export const fps = 60;
export const width = 1920;
export const height = 1080;
export const margin = 120;

export type Box = [left: number, top: number, right: number, bottom: number];
export type Caption = { t: number; label: string; color: string; boxes: Box[]; anchor: { box: Box; end: number } };
export type Take = {
  src: string;
  width?: number;
  duration: number;
  first: number;
  last: number;
  beats: { slug: string; t: number }[];
  captions: Caption[];
};

export const timing = {
  open: 5.3,
  crossfade: 0.8,
  end: 6.5,
};
export const tail = 1.6;

export const sec = (seconds: number) => Math.round(seconds * fps);

export function beat(take: Take, slug: string) {
  const found = take.beats.find((b) => b.slug === slug);
  if (!found) throw new Error(`The take has no beat for ${slug}`);
  return found.t;
}

export function retime(from: number, to: number, fast: [start: number, end: number, rate: number][] = []) {
  const times: number[] = [];
  for (let t = from; t < to; ) {
    times.push(t);
    const stretch = fast.find(([start, end]) => t >= start && t < end);
    t += (stretch ? stretch[2] : 1) / fps;
  }
  return times;
}

export const chapters = (markers: { feature: { slug: string; title: string }; from: number }[]) =>
  markers.map((marker) => ({ slug: marker.feature.slug, title: marker.feature.title, at: Math.round((marker.from / fps) * 10) / 10 }));
