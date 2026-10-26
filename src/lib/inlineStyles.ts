import { createHash } from "node:crypto";

export const layerOrder = "@layer reset, priority1, priority2, priority3, priority4;";

export const pressableStyleId = "react-aria-pressable-style";
export const pressableStyle = `@layer {
  [data-react-aria-pressable] {
    touch-action: pan-x pan-y pinch-zoom;
  }
}`;

export const inlineStyleHashes = [layerOrder, pressableStyle].map(
  (style) => `sha256-${createHash("sha256").update(style).digest("base64")}`,
);
