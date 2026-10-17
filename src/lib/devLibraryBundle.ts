import { access, readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { init, parse } from "es-module-lexer";
import { rolldown } from "rolldown";
import type { DevEnvironment, Logger, Plugin } from "vite";

const bundleId = "virtual:iris-library";
const resolvedBundleId = `\0${bundleId}`;
const entryId = "\0iris-library-entry";

/** The bundle export for a PureScript module; `$` cannot occur in module names. */
const exportName = (module: string) => module.replaceAll(".", "$");

/** The fields of Iris's `output/<Module>/metadata.json` record that the bundle reads. */
type ModuleMetadata = { version: number; editable: boolean; source: string };

const namespaceImport = /^import\s*\*\s*as\s+([\w$]+)\s+from\s*["'][^"']+["']\s*;?$/;
const namedImport = /^import\s*\{([^}]*)\}\s*from\s*["'][^"']+["']\s*;?$/;

/**
 * Development only: serves every library module that the client reaches from
 * editable modules as one bundle instead of ~170 requests. Iris's module
 * metadata says which modules come from editable workspace packages and which
 * from Registry or git packages. Library output only changes with dependencies
 * or the compiler, in which case the bundle is rebuilt and the page reloaded.
 * Editable modules keep HMR.
 */
export function devLibraryBundle(): Plugin {
  let output = "";
  let logger: Logger | undefined;
  let bundled: Set<string> | undefined;
  let building: Promise<string> | undefined;
  const warned = new Set<string>();
  const metadata = new Map<string, Promise<ModuleMetadata | undefined>>();

  /** The PureScript module that owns `file`, if it is in the output directory. */
  const moduleOf = (file: string) => {
    const relative = path.relative(output, file.split("?", 1)[0]);
    const [module, ...rest] = relative.split(path.sep);
    return rest.length && !module.startsWith(".") ? module : undefined;
  };

  /** The module's metadata record, or `undefined` if Iris hasn't written one. */
  const metadataOf = (module: string) => {
    let record = metadata.get(module);
    if (!record) {
      record = readFile(path.join(output, module, "metadata.json"), "utf8").then(
        (content) => {
          const parsed = JSON.parse(content) as ModuleMetadata;
          if (parsed.version !== 1) throw new Error(`${module} has metadata version ${parsed.version}; expected 1.`);
          return parsed;
        },
        () => {
          // Only a missing record is retried; Iris writes it after the module's JavaScript.
          metadata.delete(module);
          if (!warned.has(module)) {
            warned.add(module);
            logger?.warn(`${module} has no metadata.json, so the library bundle ignores it. Iris 0.1.8 and later write it.`);
          }
          return undefined;
        },
      );
      metadata.set(module, record);
    }
    return record;
  };
  const isLibrary = async (module: string) => (await metadataOf(module))?.editable === false;
  const isEditableIndex = async (file: string) => {
    const module = moduleOf(file);
    return !!module && path.basename(file.split("?", 1)[0]) === "index.js" && (await metadataOf(module))?.editable === true;
  };

  /** Library modules imported by generated editable code, with each import statement. */
  const libraryImports = async (file: string, code: string) => {
    const imports = await Promise.all(
      parse(code)[0].map(async (entry) => {
        if (entry.d !== -1 || !entry.n?.startsWith(".")) return [];
        const target = path.resolve(path.dirname(file), entry.n);
        const module = moduleOf(target);
        if (!module || path.basename(target) !== "index.js" || !(await isLibrary(module))) return [];
        return [{ ...entry, module }];
      }),
    );
    return imports.flat();
  };

  /**
   * Library modules imported by current editable modules. Iris never deletes
   * output, so a module whose source file is gone is a stale leftover.
   */
  const frontier = async () => {
    await init;
    const modules = new Set<string>();
    await Promise.all(
      (await readdir(output, { withFileTypes: true })).map(async (entry) => {
        if (!entry.isDirectory() || entry.name.startsWith(".")) return;
        const directory = entry.name;
        const record = await metadataOf(directory);
        if (!record?.editable || !(await access(record.source).then(() => true, () => false))) return;
        const file = path.join(output, directory, "index.js");
        const code = await readFile(file, "utf8").catch(() => "");
        for (const { module } of await libraryImports(file, code)) modules.add(module);
      }),
    );
    return [...modules].sort();
  };

  const build = async () => {
    const modules = await frontier();
    const entry = modules
      .map((module) => `export * as ${exportName(module)} from ${JSON.stringify(path.join(output, module, "index.js"))};`)
      .join("\n");
    const bundle = await rolldown({
      input: entryId,
      // Bare imports such as `react` stay external so Vite resolves them to its optimized dependencies.
      external: (id) => !id.startsWith("\0") && !id.startsWith(".") && !path.isAbsolute(id),
      plugins: [
        {
          name: "iris-library-entry",
          resolveId: (id) => (id === entryId ? id : null),
          load: (id) => (id === entryId ? entry : null),
        },
      ],
    });
    try {
      const { output: chunks } = await bundle.generate({ format: "es" });
      if (chunks.length !== 1 || chunks[0].type !== "chunk") throw new Error("Expected a single library chunk");
      bundled = new Set(modules);
      return chunks[0].code;
    } finally {
      await bundle.close();
    }
  };

  const reload = (environment: DevEnvironment) => {
    building = undefined;
    bundled = undefined;
    const module = environment.moduleGraph.getModuleById(resolvedBundleId);
    if (module) environment.moduleGraph.invalidateModule(module);
    environment.hot.send({ type: "full-reload" });
  };

  return {
    name: "iris-website:dev-library-bundle",
    apply: "serve",
    applyToEnvironment: (environment) => environment.name === "client",
    configResolved(config) {
      output = path.join(config.root, "output");
      logger = config.logger;
    },
    resolveId(id) {
      return id === bundleId ? resolvedBundleId : null;
    },
    load(id) {
      if (id === resolvedBundleId) {
        building ??= build();
        // The bundle is served as-is; a source map would only point back into itself.
        return building.then((code) => ({ code, map: { mappings: "" } }));
      }
      const module = moduleOf(id);
      if (!module) return null;
      return isLibrary(module).then((library) => {
        if (library && !warned.has(id)) {
          warned.add(id);
          this.warn(`${module} was imported outside the library bundle and will be instantiated twice.`);
        }
        return null;
      });
    },
    // Rewrite before StyleX, which loads each import of a module it transforms.
    transform: {
      order: "pre",
      async handler(code, id) {
        if (!moduleOf(id) || !/\.js(?:\?|$)/.test(id)) return null;
        let rewritten = code;
        if (await isEditableIndex(id)) {
          await init;
          const imports = await libraryImports(id, code);
          if (bundled && imports.some(({ module }) => !bundled!.has(module))) reload(this.environment as DevEnvironment);
          for (const { ss, se, module } of imports.reverse()) {
            const statement = code.slice(ss, se);
            const local = `$iris_${exportName(module)}`;
            const source = `import { ${exportName(module)} as ${local} } from "${bundleId}";`;
            const namespace = namespaceImport.exec(statement);
            const named = namedImport.exec(statement);
            // Keep each replacement on one line so later source maps stay aligned.
            const replacement = namespace
              ? `import { ${exportName(module)} as ${namespace[1]} } from "${bundleId}";`
              : named
                ? `${source} const { ${named[1]
                    .split(",")
                    .map((binding) => binding.trim())
                    .filter(Boolean)
                    .map((binding) => binding.replace(/\s+as\s+/, ": "))
                    .join(", ")} } = ${local};`
                : undefined;
            if (!replacement) {
              this.warn(`Unrecognized import of ${module}; it will be instantiated outside the library bundle.`);
              continue;
            }
            rewritten = rewritten.slice(0, ss) + replacement + rewritten.slice(se);
          }
        }
        // Iris output is its own source. Skip Vite's fallback identity source map,
        // which is larger than the module, unless StyleX will transform the code.
        const map = code.includes("@stylexjs/stylex") ? null : { mappings: "" };
        return rewritten === code && map === null ? null : { code: rewritten, map };
      },
    },
    async hotUpdate({ file }) {
      const module = moduleOf(file);
      if (!module) return;
      let library = await isLibrary(module);
      if (path.basename(file) === "metadata.json") {
        // A package that moves between editable and library changes the bundle.
        metadata.delete(module);
        library ||= await isLibrary(module);
      }
      if (bundled && library) {
        reload(this.environment);
        return [];
      }
    },
  };
}
