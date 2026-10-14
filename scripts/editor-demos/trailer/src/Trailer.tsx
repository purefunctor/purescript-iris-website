import type { CSSProperties, ReactNode } from "react";
import { useCallback, useMemo } from "react";
import {
  AbsoluteFill,
  Easing,
  Freeze,
  OffthreadVideo,
  Sequence,
  continueRender,
  delayRender,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
// The logo's dots, as the site's header and favicon draw them.
import { marks } from "../../../../src/Website/Components/Logo.js";
import { Lattice, type Ripple } from "./Lattice";
import { fps, height, margin, plan, timing, width, type Caption, type Manifest, type Marker } from "./timeline";

const fonts = delayRender("Loading Geist");
Promise.all(
  ["500", "700", "900"].map((weight) => document.fonts.load(`${weight} 100px "Geist Variable"`)).concat(
    document.fonts.load(`500 100px "Geist Mono Variable"`),
  ),
).then(() => continueRender(fonts));

// The site's --ease-out, and a symmetric curve for moves that start and stop on screen.
const out = Easing.bezier(0.2, 0.7, 0.2, 1);
const inOut = Easing.bezier(0.75, 0, 0.2, 1);
const sec = (seconds: number) => Math.round(seconds * fps);
const progress = (frame: number, start: number, duration: number, easing = out) =>
  interpolate(frame, [start, start + duration], [0, 1], { easing, extrapolateLeft: "clamp", extrapolateRight: "clamp" });



const sans: CSSProperties = { fontFamily: "var(--font-sans)" };
const mono: CSSProperties = { fontFamily: "var(--font-mono)" };

function Logo({ size, frame = Infinity, start = 0 }: { size: number; frame?: number; start?: number }) {
  return (
    <svg viewBox="0 0 32 32" width={size} height={size} style={{ overflow: "visible", flexShrink: 0 }}>
      {marks.map((mark: { x: number; y: number; radius: number; color: string }, index: number) => {
        // The ring pops in order around the centre, then the violet centre lands.
        const order = mark.color === "violet" ? marks.length : index;
        const t = progress(frame, start + order * 3, 22, Easing.bezier(0.3, 1.6, 0.5, 1));
        return (
          <circle
            key={mark.color}
            cx={mark.x}
            cy={mark.y}
            r={mark.radius * Math.max(0, t)}
            style={{ fill: `var(--spectrum-${mark.color})` }}
          />
        );
      })}
    </svg>
  );
}

// Text that rises into place behind a hard mask, one line or word at a time.
function Rise({ children, at, frame, distance = 1.6, style }: { children: ReactNode; at: number; frame: number; distance?: number; style?: CSSProperties }) {
  const t = progress(frame, at, sec(0.7));
  return (
    <span style={{ display: "inline-block", overflow: "hidden", paddingBottom: "0.14em", marginBottom: "-0.14em", verticalAlign: "top", ...style }}>
      <span style={{ display: "inline-block", transform: `translateY(${(1 - t) * distance * 100}%)` }}>{children}</span>
    </span>
  );
}

function Words({ text, at, frame, stagger = 4 }: { text: string; at: number; frame: number; stagger?: number }) {
  return (
    <>
      {text.split(" ").map((word, index, words) => (
        <span key={index}>
          <Rise at={at + index * stagger} frame={frame}>
            {word}
          </Rise>
          {index < words.length - 1 ? " " : null}
        </span>
      ))}
    </>
  );
}


function OpenScene({ duration }: { duration: number }) {
  const frame = useCurrentFrame();
  const leave = duration - sec(timing.crossfade);
  const gone = progress(frame, leave, sec(0.4), inOut);
  const subtitle = sec(1.55);
  const command = sec(2.35);
  const typed = Math.floor(interpolate(frame, [command + sec(0.3), command + sec(1.1)], [0, 17], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }));
  // The caret holds while typing, then blinks from the last keystroke: on, off, and on again as the
  // opening leaves, which timing.open allows for.
  const typedAt = command + sec(1.1);
  const caret = frame < command + sec(0.15) ? 0 : frame < typedAt || Math.floor((frame - typedAt) / sec(0.5)) % 2 === 0 ? 1 : 0;
  return (
    <AbsoluteFill style={{ opacity: 1 - gone }}>
      <div style={{ position: "absolute", left: margin, top: 300, display: "flex", flexDirection: "column", gap: 34 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 30, fontSize: 250 }}>
          <span
            style={{
              ...sans,
              fontWeight: 900,
              letterSpacing: "-0.05em",
              lineHeight: 0.8,
              marginLeft: "-0.045em",
              color: "var(--text-primary)",
            }}
          >
            <Rise at={sec(0.35)} frame={frame} distance={1.7}>
              IRIS
            </Rise>
          </span>
          <Logo size={214} frame={frame} start={sec(0.15)} />
        </div>
        <div style={{ ...sans, fontSize: 66, fontWeight: 500, letterSpacing: "-0.025em", lineHeight: 1.1, color: "var(--text-secondary)" }}>
          <Words text="Language analysis for PureScript, in the editor." at={subtitle} frame={frame} />
        </div>
        <div
          style={{
            ...mono,
            alignSelf: "flex-start",
            marginTop: 26,
            fontSize: 30,
            padding: "20px 28px",
            color: "var(--text-secondary)",
            backgroundColor: "var(--surface-1)",
            boxShadow: "inset 0 0 0 1px var(--border-default)",
            opacity: progress(frame, command, sec(0.35)),
            transform: `translateY(${(1 - progress(frame, command, sec(0.5))) * 16}px)`,
          }}
        >
          <span style={{ color: "var(--text-tertiary)" }}>$ </span>
          {"iris lsp --stdio".slice(0, typed)}
          <span style={{ display: "inline-block", width: "0.6em", height: "1.1em", marginLeft: 2, verticalAlign: "-0.2em", backgroundColor: "var(--accent)", opacity: caret }} />
        </div>
      </div>
    </AbsoluteFill>
  );
}

// A feature's name, set as a closed caption centred near the bottom of the frame, above where the
// landing page's player keeps its controls.
function FeatureCaption({ marker }: { marker: Marker }) {
  const frame = useCurrentFrame();
  const shown = Math.min(progress(frame, 0, sec(0.25)), 1 - progress(frame, marker.duration - sec(0.3), sec(0.3), inOut));
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom: 132, display: "flex", justifyContent: "center", opacity: shown }}>
      <div style={{ ...sans, fontSize: 46, fontWeight: 500, lineHeight: 1.25, color: "var(--granite-50)", backgroundColor: "oklch(from var(--granite-950) l c h / 86%)", padding: "8px 22px" }}>
        {marker.feature.title}
      </div>
    </div>
  );
}

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
// they hold while its frame holds, and leave before the next feature's card.
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

function EndScene() {
  const frame = useCurrentFrame();
  const enter = sec(0.5);
  const t = (delay: number) => progress(frame, enter + sec(delay), sec(0.6));
  return (
    <AbsoluteFill>
      <div style={{ position: "absolute", left: margin, top: 300, display: "flex", flexDirection: "column", gap: 34 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 30, fontSize: 250 }}>
          <span style={{ ...sans, fontWeight: 900, letterSpacing: "-0.05em", lineHeight: 0.8, marginLeft: "-0.045em", color: "var(--text-primary)" }}>
            <Rise at={enter + sec(0.15)} frame={frame} distance={1.7}>
              IRIS
            </Rise>
          </span>
          <Logo size={214} frame={frame} start={enter} />
        </div>
        <div
          style={{
            ...mono,
            alignSelf: "flex-start",
            marginTop: 30,
            fontSize: 32,
            padding: "24px 32px",
            color: "var(--text-secondary)",
            backgroundColor: "var(--surface-1)",
            boxShadow: "inset 0 0 0 1px var(--border-default)",
            opacity: t(0.6),
            transform: `translateY(${(1 - t(0.6)) * 16}px)`,
          }}
        >
          <span style={{ color: "var(--text-tertiary)" }}>$ </span>curl -fsSL https://iris-lang.com/install.sh | sh
        </div>
        <div style={{ ...sans, fontSize: 30, fontWeight: 500, color: "var(--text-tertiary)", opacity: t(1.0) }}>
          iris-lang.com/docs/language-server
        </div>
      </div>
    </AbsoluteFill>
  );
}

export function Trailer({ manifest }: { manifest: Manifest }) {
  const { scenes, track, markers } = useMemo(() => plan(manifest), [manifest]);
  // Captions clear before the beat that follows them.
  const captions = useMemo(
    () =>
      manifest.take.captions.map((caption) => ({
        ...caption,
        until: Math.min(...manifest.take.beats.map((b) => b.t).filter((t) => t > caption.t)),
      })),
    [manifest],
  );
  // Ripples cross the lattice as the logo lands, at the start and the end.
  const ripples = useMemo<Ripple[]>(
    () =>
      scenes.flatMap((scene) =>
        scene.kind === "open" ? [{ x: 820, y: 400, frame: sec(0.5) }] : [{ x: 820, y: 400, frame: scene.from + sec(0.6) }],
      ),
    [scenes],
  );
  // The lattice grows out from the logo as the trailer opens.
  const frame = useCurrentFrame();
  const reveal = useCallback(
    (x: number, y: number) => {
      const radius = interpolate(frame, [sec(0.3), sec(2.4)], [0, 2400], { easing: out, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      const distance = Math.hypot(x - 820, y - 400);
      return Math.min(1, Math.max(0, (radius - distance) / 260));
    },
    [frame],
  );
  return (
    <AbsoluteFill style={{ background: "var(--canvas-texture), var(--bg-canvas)", color: "var(--text-primary)" }}>
      <Lattice ripples={ripples} reveal={frame < sec(3) ? reveal : undefined} />
      <Take src={manifest.take.src} track={track} captions={captions} scale={width / (manifest.take.width ?? width)} />
      {markers.map((marker) => (
        <Sequence key={marker.feature.slug} from={marker.from} durationInFrames={marker.duration} layout="none">
          <FeatureCaption marker={marker} />
        </Sequence>
      ))}
      {scenes.map((scene) => (
        <Sequence key={scene.kind} from={scene.from} durationInFrames={scene.duration} layout="none">
          {scene.kind === "open" ? <OpenScene duration={scene.duration} /> : <EndScene />}
        </Sequence>
      ))}
    </AbsoluteFill>
  );
}
