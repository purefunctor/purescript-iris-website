// Bundles the site's React for playground programs, which run in a sandbox without network access
// and so cannot load npm packages. The Registry's React bindings import only these specifiers.
// Each entry re-exports one CommonJS package as an ES module with a default export, which the
// bindings import, and its named exports, which a project's own FFI may import. The entries share
// one React through common chunks, which import each other by relative path, as generated
// PureScript does, so the runner links them the same way.

import { createRequire } from "node:module";
import { rolldown } from "rolldown";

const require = createRequire(import.meta.url);

// The browser build of the server renderer needs no Node streams.
const ENTRIES = {
  react: { file: "react.js", source: "react" },
  "react-dom": { file: "react-dom.js", source: "react-dom" },
  "react-dom/client": { file: "react-dom-client.js", source: "react-dom/client" },
  "react-dom/server": { file: "react-dom-server.js", source: "react-dom/server.browser" },
};

export type PlaygroundReact = {
  version: string;
  /** The file under `files` that each specifier resolves to. */
  entries: Record<string, string>;
  files: Record<string, string>;
};

export async function bundlePlaygroundReact(): Promise<PlaygroundReact> {
  const virtual = (file: string) => `\0playground-react:${file}`;
  const sources = new Map(
    Object.values(ENTRIES).map(({ file, source }) => {
      const names = Object.keys(require(source)).filter((name) => /^[A-Za-z_$][\w$]*$/.test(name) && name !== "default");
      const code = [
        `import module from ${JSON.stringify(source)};`,
        "export default module;",
        ...names.map((name) => `export const ${name} = module.${name};`),
      ].join("\n");
      return [virtual(file), code];
    }),
  );
  const bundle = await rolldown({
    input: Object.fromEntries(Object.values(ENTRIES).map(({ file }) => [file.slice(0, -".js".length), virtual(file)])),
    platform: "browser",
    transform: { define: { "process.env.NODE_ENV": JSON.stringify("production") } },
    plugins: [
      {
        name: "playground-react-entries",
        resolveId: (id) => (sources.has(id) ? id : null),
        load: (id) => sources.get(id) ?? null,
      },
    ],
  });
  try {
    const { output } = await bundle.generate({
      format: "es",
      minify: true,
      entryFileNames: "[name].js",
      chunkFileNames: "[name]-[hash].js",
    });
    const files: Record<string, string> = {};
    for (const chunk of output) if (chunk.type === "chunk") files[chunk.fileName] = chunk.code;
    return {
      version: require("react/package.json").version,
      entries: Object.fromEntries(Object.entries(ENTRIES).map(([specifier, { file }]) => [specifier, file])),
      files,
    };
  } finally {
    await bundle.close();
  }
}
