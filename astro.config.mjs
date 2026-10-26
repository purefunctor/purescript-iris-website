import react from "@astrojs/react";
import stylex from "@stylexjs/unplugin";
import icons from "unplugin-icons/vite";
import { defineConfig } from "astro/config";
import { readFileSync } from "node:fs";
import { devLibraryBundle } from "./src/lib/devLibraryBundle.ts";
import { devModulePreload } from "./src/lib/devModulePreload.ts";
import { inlineStyleHashes } from "./src/lib/inlineStyles.ts";
import { monacoStyles } from "./src/lib/monacoStyles.ts";

const monacoModules = Array.from(
  readFileSync(new URL("./playground/client/monaco.js", import.meta.url), "utf8").matchAll(
    /^import (?:\* as \w+ from |\{[^}]*\} from )?"(monaco-editor\/[^"?]+\.js)";$/gm,
  ),
  (match) => match[1],
);

const development = process.env.NODE_ENV === "development";

export default defineConfig({
  site: "https://iris-lang.com",
  integrations: [react(), devModulePreload()],
  devToolbar: { enabled: false },
  output: "static",
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
    cacheDir: development
      ? "node_modules/.vite-dev"
      : "node_modules/.vite-build",
    optimizeDeps: {
      include: [
        "@stylexjs/stylex",
        "react-aria-components/Button",
        "react-aria-components/Dialog",
        "react-aria-components/Link",
        "react-aria-components/Modal",
        "react-aria-components/Popover",
        "react-aria-components/Tabs",
        "react-aria-components/Tooltip",
        "es-module-lexer/js",
        "@jridgewell/trace-mapping",
        ...monacoModules,
      ],
    },
    build: { cssCodeSplit: false },
    plugins: [
      devLibraryBundle(),
      monacoStyles(),
      icons({ compiler: "jsx", jsx: "react" }),
      stylex.vite({
        dev: development,
        runtimeInjection: false,
        useCSSLayers: true,
        babelConfig: { presets: [() => ({ sourceMaps: true })] },
      }),
    ],
    server: {
      strictPort: process.env.PORT !== undefined,
      watch: { ignored: ["**/.spago/**", "**/output/.iris-watch*", "**/*.purs"] },
    },
  },
});
