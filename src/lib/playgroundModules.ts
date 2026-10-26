
import { createRequire } from "node:module";
import { rolldown } from "rolldown";

const require = createRequire(import.meta.url);

const ENTRIES: Record<string, { file: string; source: string; esm?: boolean }> = {
  react: { file: "react.js", source: "react" },
  "react-dom": { file: "react-dom.js", source: "react-dom" },
  "react-dom/client": { file: "react-dom-client.js", source: "react-dom/client" },
  "react-dom/server": { file: "react-dom-server.js", source: "react-dom/server.browser" },
  "@stylexjs/stylex": { file: "stylex.js", source: "@stylexjs/stylex", esm: true },
};

export type PlaygroundModules = {
  entries: Record<string, string>;
  files: Record<string, string>;
};

export async function bundlePlaygroundModules(): Promise<PlaygroundModules> {
  const virtual = (file: string) => `\0playground-modules:${file}`;
  const sources = new Map(
    Object.values(ENTRIES).map(({ file, source, esm }) => {
      if (esm) return [virtual(file), `export * from ${JSON.stringify(source)};`];
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
        name: "playground-module-entries",
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
      entries: Object.fromEntries(Object.entries(ENTRIES).map(([specifier, { file }]) => [specifier, file])),
      files,
    };
  } finally {
    await bundle.close();
  }
}
