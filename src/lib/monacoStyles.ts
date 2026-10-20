import type { Plugin } from "vite";

const prefix = "\0iris-website:monaco-style:";

/**
 * Build only: Monaco's modules import their own CSS, which the build would merge into the
 * stylesheet that every page links. Each import becomes a module that adds the CSS as a style
 * element when the playground loads Monaco, so other pages never download it. The playground's
 * CSP allows style elements for Monaco already.
 */
export function monacoStyles(): Plugin {
  return {
    name: "iris-website:monaco-styles",
    apply: "build",
    enforce: "pre",
    async resolveId(source, importer, options) {
      if (!importer?.includes("/node_modules/monaco-editor/") || !source.endsWith(".css")) return null;
      const resolved = await this.resolve(source, importer, { ...options, skipSelf: true });
      // The suffix keeps Vite's CSS plugin from treating the module as a stylesheet.
      return resolved ? `${prefix}${resolved.id}.js` : null;
    },
    load(id) {
      if (!id.startsWith(prefix)) return null;
      const css = JSON.stringify(`${id.slice(prefix.length, -".js".length)}?inline`);
      return `import css from ${css};
const style = document.createElement("style");
style.textContent = css;
document.head.append(style);
`;
    },
  };
}
