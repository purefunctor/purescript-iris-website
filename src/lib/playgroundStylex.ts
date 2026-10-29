
import { rolldown } from "rolldown";

const ENTRY = "\0playground-stylex";

const SOURCE = `import { transform } from "@babel/standalone";
import stylex from "@stylexjs/babel-plugin";

// The site's settings in astro.config.mjs, without the bundler's development mode.
const options = { dev: false, runtimeInjection: false };

/** Compiles one generated module, composing Iris's map through Babel's printed output. */
export function compile(code, filename, inputSourceMap) {
  const result = transform(code, {
    babelrc: false,
    configFile: false,
    filename,
    sourceType: "module",
    inputSourceMap: inputSourceMap ?? false,
    sourceMaps: !!inputSourceMap,
    plugins: [[stylex, options]],
  });
  return { code: result.code, map: result.map, rules: result.metadata.stylex ?? [] };
}

/** The style sheet for the rules of every compiled module, in the site's cascade layers. */
export function styleSheet(rules) {
  return stylex.processStylexRules(rules, { useLayers: true });
}
`;

export async function bundlePlaygroundStylex(): Promise<string> {
  const bundle = await rolldown({
    input: ENTRY,
    platform: "browser",
    transform: { define: { "process.env.NODE_ENV": JSON.stringify("production") } },
    plugins: [
      {
        name: "playground-stylex",
        resolveId: (id) => (id === ENTRY ? id : null),
        load: (id) => (id === ENTRY ? SOURCE : null),
      },
    ],
  });
  try {
    const { output } = await bundle.generate({ format: "es", minify: true, codeSplitting: false });
    return output[0].code;
  } finally {
    await bundle.close();
  }
}
