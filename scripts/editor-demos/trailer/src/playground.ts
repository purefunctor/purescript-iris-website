// The playground trailer: the `playground` take full screen, which then slides into the left half
// while the `playground-share` take opens its share link on the right. The beats of both takes in
// playground.mjs, in the order that playground-screenplay.md describes, each named for its caption.
import type { Feature } from "./chapters.ts";
import { beat, fps, retime, sec, tail, timing, type Take } from "./takes.ts";

export { chapters } from "./takes.ts";

export type Manifest = { take: Take; share: Take };

export const features: (Feature & { take: "take" | "share" })[] = [
  { slug: "run", title: "Run in the browser", take: "take" },
  { slug: "edit", title: "Edit and run again", take: "take" },
  { slug: "templates", title: "React templates", take: "take" },
  { slug: "completion", title: "Completion with imports", take: "take" },
  { slug: "console", title: "Console", take: "take" },
  { slug: "todos", title: "React todos", take: "take" },
  { slug: "packages", title: "Registry packages", take: "take" },
  { slug: "package-import", title: "Imports from packages", take: "take" },
  { slug: "stylex", title: "StyleX", take: "take" },
  { slug: "files", title: "Multiple modules", take: "take" },
  { slug: "share", title: "Share by link", take: "take" },
  { slug: "open-link", title: "Open the link anywhere", take: "share" },
];

// The split's final layout: both takes at this scale, side by side, centred in the frame.
export const split = { scale: 0.485, gap: 32, duration: 1.0 };
export const panel = { width: 1920 * split.scale, height: 1080 * split.scale };
export const left = { x: (1920 - 2 * panel.width - split.gap) / 2, y: (1080 - panel.height) / 2 };
export const right = { x: left.x + panel.width + split.gap, y: left.y };

// Each feature's name stays captioned over the take this long.
const caption = 2.8;
// The incognito window downloads the shared project's packages; that wait plays this fast.
const loadingSpeed = 6;

export type Marker = { feature: Feature; index: number; from: number; duration: number };
type Pose = { source: number; opacity: number };

export function plan({ take, share }: Manifest) {
  const fade = sec(timing.crossfade);
  const from = sec(timing.open - timing.crossfade);

  // The main take plays once, from just before its first feature to its last result, then holds.
  const mainTimes = retime(Math.max(0, take.beats[0].t - 0.8), Math.min(take.duration - 1 / fps, take.last + tail));
  // The split starts once Share has copied the link and its result has held for a moment.
  const splitFrom = from + Math.max(0, mainTimes.findIndex((t) => t >= take.last + 0.4));
  // The share take starts as it slides in, and hurries through the shared project's download, from
  // just after Return opens the pasted link until the project has loaded.
  const loading = beat(share, "loading");
  const loaded = beat(share, "shared-loaded");
  const shareTimes = retime(Math.max(0, share.first - 0.6), Math.min(share.duration - 1 / fps, share.last + tail), [
    [loading + 0.6, loaded - 0.6, loadingSpeed],
  ]);
  const shareFrom = splitFrom + sec(0.3);
  const endFrom = shareFrom + shareTimes.length - fade;
  const fadeOut = (f: number) => Math.min(1, (endFrom + fade - f) / fade);

  const main: Pose[] = [];
  for (let f = from; f < endFrom + fade; f++) {
    const index = Math.min(mainTimes.length - 1, f - from);
    main[f] = { source: mainTimes[index], opacity: Math.min(1, (f - from) / fade, fadeOut(f)) };
  }
  const shared: Pose[] = [];
  shareTimes.forEach((source, f) => {
    shared[shareFrom + f] = { source, opacity: fadeOut(shareFrom + f) };
  });

  const frameAt = (clip: "take" | "share", source: number) =>
    clip === "take"
      ? from + Math.max(0, mainTimes.findIndex((t) => t >= source))
      : shareFrom + Math.max(0, shareTimes.findIndex((t) => t >= source));
  const markers: Marker[] = features.map((feature, index) => ({
    feature,
    index,
    from: frameAt(feature.take, beat(feature.take === "take" ? take : share, feature.slug)),
    duration: sec(caption),
  }));
  return {
    open: { from: 0, duration: sec(timing.open) },
    end: { from: endFrom, duration: sec(timing.end) },
    main,
    shared,
    splitFrom,
    markers,
    duration: endFrom + sec(timing.end),
  };
}
