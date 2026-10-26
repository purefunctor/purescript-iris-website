import type { Plugin } from "vite";

const prefix = "\0iris-website:monaco-style:";

export function monacoStyles(): Plugin {
  return {
    name: "iris-website:monaco-styles",
    apply: "build",
    enforce: "pre",
    async resolveId(source, importer, options) {
      if (!importer?.includes("/node_modules/monaco-editor/") || !source.endsWith(".css")) return null;
      const resolved = await this.resolve(source, importer, { ...options, skipSelf: true });
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
