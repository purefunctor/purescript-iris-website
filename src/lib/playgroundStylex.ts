// Bundles the StyleX compiler for the playground page. Iris compiles Iris.StyleX to
// `@stylexjs/stylex` calls that the StyleX Babel plugin must compile to CSS, as
// @stylexjs/unplugin does for the site. The runner loads this module only when a program imports
// StyleX, and runs it on the generated modules before linking them.
//
// The plugin's browser build runs on @babel/standalone, Babel's own build for browsers, which
// also runs the plugin here.

import { rolldown } from "rolldown";

const ENTRY = "\0playground-stylex";

const SOURCE = `import { transform } from "@babel/standalone";
import stylex from "@stylexjs/babel-plugin";

// The site's settings in astro.config.mjs, without the bundler's development mode.
const options = { dev: false, runtimeInjection: false };

/** Compiles one generated module, returning its code and the StyleX rules it defines. */
export function compile(code, filename) {
  const result = transform(code, {
    babelrc: false,
    configFile: false,
    filename,
    sourceType: "module",
    plugins: [[stylex, options]],
  });
  return { code: result.code, rules: result.metadata.stylex ?? [] };
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
