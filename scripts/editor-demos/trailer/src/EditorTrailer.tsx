import { useMemo } from "react";
import { AbsoluteFill, Freeze, OffthreadVideo, Sequence, staticFile, useCurrentFrame } from "remotion";
import { plan, type Manifest } from "./editor";
import { Backdrop, EndScene, OpenScene, out, sans } from "./Scenes";
import { fps, height, width, type Caption } from "./takes";

// The take, full screen and playing throughout, under the overlays.
function Take({ src, track, captions, scale }: { src: string; track: { source: number; opacity: number }[]; captions: (Caption & { until: number })[]; scale: number }) {
  const frame = useCurrentFrame();
  const pose = track[frame];
  if (!pose) return null;
  return (
    <AbsoluteFill style={{ opacity: pose.opacity }}>
      <Freeze frame={Math.round(pose.source * fps)}>
        <OffthreadVideo src={staticFile(src)} muted style={{ width, height, display: "block" }} />
      </Freeze>
      <div style={{ position: "absolute", inset: 0, transform: `scale(${scale})`, transformOrigin: "0 0" }}>
        {captions.map((caption, n) => (
          <CaptionMark key={caption.label} caption={caption} order={n} source={pose.source} />
        ))}
      </div>
    </AbsoluteFill>
  );
}

// One semantic role, captioned on the code: its tokens underlined in the role's editor color, and a
// flat tag in that color in the margin beside one of them. Captions keep to the take's own clock, so
// they hold while its frame holds, and leave before the next feature starts.
const tagColumn = 1600;
function CaptionMark({ caption, order, source }: { caption: Caption & { until: number }; order: number; source: number }) {
  const appear = caption.t + 0.35 + order * 0.8;
  const t = (delay: number, length: number) => out(Math.min(1, Math.max(0, (source - appear - delay) / length)));
  // Captions clear before the take's hold and zoom out ahead of the next beat.
  const gone = 1 - Math.min(1, Math.max(0, (source - (caption.until - 0.9)) / 0.4));
  if (source < appear || gone <= 0) return null;
  const color = `var(${caption.color})`;
  const [, top, , bottom] = caption.anchor.box;
  const middle = (top + bottom) / 2;
  const left = Math.max(tagColumn, caption.anchor.end + 64);
  const leader = left - 18 - (caption.anchor.end + 22);
  return (
    <div style={{ position: "absolute", inset: 0, opacity: gone }}>
      {caption.boxes.map(([l, , r, b], n) => (
        <div
          key={n}
          style={{ position: "absolute", left: l, top: b + 1, width: (r - l) * t(n * 0.03, 0.4), height: 4, backgroundColor: color }}
        />
      ))}
      <div
        style={{
          position: "absolute",
          left: caption.anchor.end + 22,
          top: middle - 1,
          width: leader,
          height: 2,
          backgroundColor: color,
          transform: `scaleX(${t(0.15, 0.45)})`,
          transformOrigin: "left",
        }}
      />
      <div
        style={{
          ...sans,
          position: "absolute",
          left,
          top: middle - 23,
          height: 46,
          display: "flex",
          alignItems: "center",
          padding: "0 18px",
          fontSize: 25,
          fontWeight: 500,
          color: "var(--granite-950)",
          backgroundColor: color,
          opacity: t(0.3, 0.35),
        }}
      >
        {caption.label}
      </div>
    </div>
  );
}

export function Trailer({ manifest }: { manifest: Manifest }) {
  const { scenes, track } = useMemo(() => plan(manifest), [manifest]);
  // Captions clear before the beat that follows them.
  const captions = useMemo(
    () =>
      manifest.take.captions.map((caption) => ({
        ...caption,
        until: Math.min(...manifest.take.beats.map((b) => b.t).filter((t) => t > caption.t)),
      })),
    [manifest],
  );
  return (
    <AbsoluteFill style={{ background: "var(--canvas-texture), var(--bg-canvas)", color: "var(--text-primary)" }}>
      <Backdrop endFrom={scenes.find((scene) => scene.kind === "end")!.from} />
      <Take src={manifest.take.src} track={track} captions={captions} scale={width / (manifest.take.width ?? width)} />
      {scenes.map((scene) => (
        <Sequence key={scene.kind} from={scene.from} durationInFrames={scene.duration} layout="none">
          {scene.kind === "open" ? <OpenScene duration={scene.duration} /> : <EndScene />}
        </Sequence>
      ))}
    </AbsoluteFill>
  );
}
