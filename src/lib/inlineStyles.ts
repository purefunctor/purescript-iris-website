import { createHash } from "node:crypto";

/** Declares the order of StyleX's cascade layers before any stylesheet uses them. */
export const layerOrder = "@layer reset, priority1, priority2, priority3, priority4;";

/**
 * React Aria's `usePress` injects this style at runtime unless an element with its ID already
 * exists. The CSP blocks that injection, so `SiteLayout` renders the same rule. Keep it in sync
 * with `react-aria/dist/private/interactions/usePress.mjs` when upgrading React Aria.
 */
export const pressableStyleId = "react-aria-pressable-style";
export const pressableStyle = `@layer {
  [data-react-aria-pressable] {
    touch-action: pan-x pan-y pinch-zoom;
  }
}`;

/** Astro does not hash `is:inline` styles, so the CSP allows these by their hashes. */
export const inlineStyleHashes = [layerOrder, pressableStyle].map(
  (style) => `sha256-${createHash("sha256").update(style).digest("base64")}`,
);
