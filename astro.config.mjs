import react from "@astrojs/react";
import stylex from "@stylexjs/unplugin";
import icons from "unplugin-icons/vite";
import { defineConfig } from "astro/config";
import { readFileSync } from "node:fs";
import { devLibraryBundle } from "./src/lib/devLibraryBundle.ts";
import { devModulePreload } from "./src/lib/devModulePreload.ts";
import { inlineStyleHashes } from "./src/lib/inlineStyles.ts";

// The playground imports Monaco's editor features one module at a time. Prebundle each module it
// lists, so that opening the playground never makes Vite reoptimize and reload the page.
const monacoModules = Array.from(
  readFileSync(new URL("./playground/client/monaco.js", import.meta.url), "utf8").matchAll(
    /^import (?:\* as \w+ from )?"(monaco-editor\/[^"?]+\.js)";$/gm,
  ),
  (match) => match[1],
);

// Astro sets NODE_ENV before loading config.
const development = process.env.NODE_ENV === "development";

export default defineConfig({
  site: "https://iris-lang.com",
  integrations: [react(), devModulePreload()],
  // The toolbar adds about 1.3 MB of client modules to every development page.
  devToolbar: { enabled: false },
  output: "static",
  // DocumentationLayout prefetches and caches documentation pages itself.
  prefetch: false,
  session: false,
  security: {
    csp: {
      directives: [
        "default-src 'self'",
        "base-uri 'none'",
        "object-src 'none'",
        "frame-src 'self'",
        "frame-ancestors 'none'",
        "form-action 'none'",
        "connect-src 'self'",
        "img-src 'self' data:",
        "media-src 'self' blob:",
      ],
      scriptDirective: { resources: ["'self'"] },
      styleDirective: { hashes: inlineStyleHashes },
    },
  },
  server: {
    host: process.env.AMP_ORB === "1",
    allowedHosts: process.env.AMP_ORB ? [".onamp.dev"] : [],
    port: process.env.PORT ? Number(process.env.PORT) : 4321,
  },
  vite: {
    // A production build/sync must not replace a live dev server's prebundles.
    cacheDir: development
      ? "node_modules/.vite-dev"
      : "node_modules/.vite-build",
    // Generated PureScript is not all visible to the initial dependency scan.
    optimizeDeps: {
      include: [
        "@stylexjs/stylex",
        "react-aria-components/Button",
        "react-aria-components/Dialog",
        "react-aria-components/Modal",
        "react-aria-components/Popover",
        "react-aria-components/Tabs",
        "react-aria-components/Tooltip",
        "es-module-lexer/js",
        ...monacoModules,
      ],
    },
    // StyleX aggregates all rules into one CSS asset.
    build: { cssCodeSplit: false },
    plugins: [
      devLibraryBundle(),
      icons({ compiler: "jsx", jsx: "react" }),
      stylex.vite({
        dev: development,
        runtimeInjection: false,
        useCSSLayers: true,
        // The plugin reprints modules with Babel but requests no source map and
        // returns `map: null`, which Vite reads as unchanged positions. That would
        // apply Iris's map to shifted code, so ask Babel for a map to chain.
        babelConfig: { presets: [() => ({ sourceMaps: true })] },
      }),
    ],
    server: {
      strictPort: process.env.PORT !== undefined,
      // Iris watches PureScript sources; Vite only needs the JavaScript it emits.
      watch: { ignored: ["**/.spago/**", "**/output/.iris-watch*", "**/*.purs"] },
    },
  },
});
