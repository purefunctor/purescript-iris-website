// The pieces that every trailer composes: the opening and closing lockups, the hero's dot lattice
// behind them, and a take placed in the frame. They use the site's tokens, fonts and logo.
import type { CSSProperties, ReactNode } from "react";
import { useCallback, useMemo } from "react";
import {
  AbsoluteFill,
  Easing,
  Freeze,
  OffthreadVideo,
  continueRender,
  delayRender,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
// The logo's dots, as the site's header and favicon draw them.
import { marks } from "../../../../src/Website/Components/Logo.js";
import { Lattice, type Ripple } from "./Lattice";
import { fps, height, margin, sec, timing, width } from "./takes";

const fonts = delayRender("Loading Geist");
Promise.all(
  ["500", "700", "900"].map((weight) => document.fonts.load(`${weight} 100px "Geist Variable"`)).concat(
    document.fonts.load(`500 100px "Geist Mono Variable"`),
  ),
).then(() => continueRender(fonts));

// The site's --ease-out, and a symmetric curve for moves that start and stop on screen.
export const out = Easing.bezier(0.2, 0.7, 0.2, 1);
export const inOut = Easing.bezier(0.75, 0, 0.2, 1);
export const progress = (frame: number, start: number, duration: number, easing = out) =>
  interpolate(frame, [start, start + duration], [0, 1], { easing, extrapolateLeft: "clamp", extrapolateRight: "clamp" });

export const sans: CSSProperties = { fontFamily: "var(--font-sans)" };
export const mono: CSSProperties = { fontFamily: "var(--font-mono)" };

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


// The opening lockup. The playground trailer passes its own line and command.
export function OpenScene({
  duration,
  subtitle = "Language analysis for PureScript, in the editor.",
  command = "iris lsp --stdio",
  prompt = true,
}: {
  duration: number;
  subtitle?: string;
  command?: string;
  prompt?: boolean;
}) {
  const frame = useCurrentFrame();
  const leave = duration - sec(timing.crossfade);
  const gone = progress(frame, leave, sec(0.4), inOut);
  const subtitleAt = sec(1.55);
  const typing = sec(2.35);
  const typed = Math.floor(interpolate(frame, [typing + sec(0.3), typing + sec(1.1)], [0, command.length + 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }));
  // The caret holds while typing, then blinks from the last keystroke: on, off, and on again as the
  // opening leaves, which timing.open allows for.
  const typedAt = typing + sec(1.1);
  const caret = frame < typing + sec(0.15) ? 0 : frame < typedAt || Math.floor((frame - typedAt) / sec(0.5)) % 2 === 0 ? 1 : 0;
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
          <Words text={subtitle} at={subtitleAt} frame={frame} />
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
            opacity: progress(frame, typing, sec(0.35)),
            transform: `translateY(${(1 - progress(frame, typing, sec(0.5))) * 16}px)`,
          }}
        >
          {prompt && <span style={{ color: "var(--text-tertiary)" }}>$ </span>}
          {command.slice(0, typed)}
          <span style={{ display: "inline-block", width: "0.6em", height: "1.1em", marginLeft: 2, verticalAlign: "-0.2em", backgroundColor: "var(--accent)", opacity: caret }} />
        </div>
      </div>
    </AbsoluteFill>
  );
}

// The closing lockup. The playground trailer passes its own command and link.
export function EndScene({
  command = "curl -fsSL https://iris-lang.com/install.sh | sh",
  link = "iris-lang.com/docs/language-server",
  prompt = true,
}: {
  command?: string;
  link?: string;
  prompt?: boolean;
}) {
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
          {prompt && <span style={{ color: "var(--text-tertiary)" }}>$ </span>}
          {command}
        </div>
        <div style={{ ...sans, fontSize: 30, fontWeight: 500, color: "var(--text-tertiary)", opacity: t(1.0) }}>
          {link}
        </div>
      </div>
    </AbsoluteFill>
  );
}

// The hero's dot lattice behind everything. It grows out from the logo as the trailer opens, and
// ripples cross it as the logo lands, at the start and at the end card, which starts at `endFrom`.
export function Backdrop({ endFrom }: { endFrom: number }) {
  const ripples = useMemo<Ripple[]>(() => [{ x: 820, y: 400, frame: sec(0.5) }, { x: 820, y: 400, frame: endFrom + sec(0.6) }], [endFrom]);
  const frame = useCurrentFrame();
  const reveal = useCallback(
    (x: number, y: number) => {
      const radius = interpolate(frame, [sec(0.3), sec(2.4)], [0, 2400], { easing: out, extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      const distance = Math.hypot(x - 820, y - 400);
      return Math.min(1, Math.max(0, (radius - distance) / 260));
    },
    [frame],
  );
  return <Lattice ripples={ripples} reveal={frame < sec(3) ? reveal : undefined} />;
}

// One take at a frame of the trailer, placed by `box` in the composition's pixels.
export function Clip({ src, pose, box }: { src: string; pose?: { source: number; opacity: number }; box: { x: number; y: number; scale: number } }) {
  if (!pose) return null;
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width,
        height,
        opacity: pose.opacity,
        transform: `translate(${box.x}px, ${box.y}px) scale(${box.scale})`,
        transformOrigin: "0 0",
        // The split's panels read as two windows, with a hard edge against the lattice.
        boxShadow: box.scale < 1 ? "0 0 0 2px var(--border-default), 0 30px 80px oklch(0% 0 0 / 55%)" : "none",
        overflow: "hidden",
      }}
    >
      <Freeze frame={Math.round(pose.source * fps)}>
        <OffthreadVideo src={staticFile(src)} muted style={{ width, height, display: "block" }} />
      </Freeze>
    </div>
  );
}
