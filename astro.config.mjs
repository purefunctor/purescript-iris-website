import react from "@astrojs/react";
import stylex from "@stylexjs/unplugin";
import icons from "unplugin-icons/vite";
import { defineConfig } from "astro/config";

// Astro sets NODE_ENV before loading config.
const development = process.env.NODE_ENV === "development";

export default defineConfig({
  integrations: [react()],
  output: "static",
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
        "react-aria-components",
        "react-aria-components/Modal",
      ],
    },
    // StyleX aggregates all rules into one CSS asset.
    build: { cssCodeSplit: false },
    plugins: [
      icons({ compiler: "jsx", jsx: "react" }),
      stylex.vite({
        dev: development,
        runtimeInjection: false,
        useCSSLayers: true,
      }),
    ],
    server: {
      strictPort: process.env.PORT !== undefined,
    },
  },
});
