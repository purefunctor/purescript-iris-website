import { useMemo } from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { Backdrop, Clip, EndScene, inOut, OpenScene } from "./Scenes";
import { left, plan, right, split, type Manifest, type Marker } from "./playground";
import { fps, width } from "./takes";

function FeatureCaption({ marker }: { marker: Marker }) {
  const frame = useCurrentFrame();
  const shown = interpolate(frame, [0, 0.25 * fps, marker.duration - 0.3 * fps, marker.duration], [0, 1, 1, 0], {
    easing: inOut,
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom: 132, display: "flex", justifyContent: "center", opacity: shown }}>
      <div style={{ fontFamily: "var(--font-sans)", fontSize: 46, fontWeight: 500, lineHeight: 1.25, color: "var(--granite-50)", backgroundColor: "oklch(from var(--granite-950) l c h / 86%)", padding: "8px 22px" }}>
        {marker.feature.title}
      </div>
    </div>
  );
}

export function PlaygroundTrailer({ manifest }: { manifest: Manifest }) {
  const { open, end, main, shared, splitFrom, markers } = useMemo(() => plan(manifest), [manifest]);
  const frame = useCurrentFrame();
  const t = interpolate(frame, [splitFrom, splitFrom + split.duration * fps], [0, 1], {
    easing: inOut,
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const mainBox = { x: left.x * t, y: left.y * t, scale: 1 + (split.scale - 1) * t };
  const shareBox = { x: right.x + (width - right.x) * (1 - t), y: right.y, scale: split.scale };
  return (
    <AbsoluteFill style={{ background: "var(--canvas-texture), var(--bg-canvas)", color: "var(--text-primary)" }}>
      <Backdrop endFrom={end.from} />
      <Clip src={manifest.take.src} pose={main[frame]} box={mainBox} />
      <Clip src={manifest.share.src} pose={shared[frame]} box={shareBox} />
      {markers.map((marker) => (
        <Sequence key={marker.feature.slug} from={marker.from} durationInFrames={marker.duration} layout="none">
          <FeatureCaption marker={marker} />
        </Sequence>
      ))}
      <Sequence from={open.from} durationInFrames={open.duration} layout="none">
        <OpenScene duration={open.duration} subtitle="PureScript in the browser, with the editor's analysis." command="iris-lang.com/playground" prompt={false} />
      </Sequence>
      <Sequence from={end.from} durationInFrames={end.duration} layout="none">
        <EndScene command="iris-lang.com/playground" link="Compiled by Iris, in your browser." prompt={false} />
      </Sequence>
    </AbsoluteFill>
  );
}
