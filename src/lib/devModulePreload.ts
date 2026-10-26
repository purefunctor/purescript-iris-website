import type { AstroIntegration } from "astro";
import type { DevEnvironment, TransformResult } from "vite";
import { init, parse } from "es-module-lexer";

const serverKey = Symbol.for("iris-website.dev-module-preload");

type Global = typeof globalThis & { [serverKey]?: DevEnvironment };

export function devModulePreload(): AstroIntegration {
  return {
    name: "iris-website:dev-module-preload",
    hooks: {
      "astro:config:setup": ({ command, addMiddleware }) => {
        if (command !== "dev") return;
        addMiddleware({ entrypoint: new URL("./devModulePreloadMiddleware.ts", import.meta.url), order: "post" });
      },
      "astro:server:setup": ({ server }) => {
        (globalThis as Global)[serverKey] = server.environments.client;
      },
    },
  };
}

const importsOf = new WeakMap<TransformResult, string[]>();

function staticImports(url: string, result: TransformResult): string[] {
  let imports = importsOf.get(result);
  if (!imports) {
    const base = new URL(url, "http://localhost");
    imports = [];
    for (const { n, d } of parse(result.code)[0]) {
      if (d !== -1 || !n || /^(?:[a-z]+:|\/\/)/i.test(n)) continue;
      const resolved = new URL(n, base);
      imports.push(resolved.pathname + resolved.search);
    }
    importsOf.set(result, imports);
  }
  return imports;
}

function requestId(url: string): string {
  const [pathname, query = ""] = url.split("?", 2);
  const params = new URLSearchParams(query);
  params.delete("t");
  params.delete("import");
  const search = params.toString().replace(/=(?=&|$)/g, "");
  const id = pathname.startsWith("/@id/") ? pathname.slice("/@id/".length).replace("__x00__", "\0") : pathname;
  return search ? `${id}?${search}` : id;
}

export async function modulePreloads(entries: string[]): Promise<string[]> {
  const environment = (globalThis as Global)[serverKey];
  if (!environment) return [];
  await init;
  const seen = new Set(entries);
  let level = entries;
  while (level.length) {
    const next: string[] = [];
    await Promise.all(
      level.map(async (url) => {
        const result = await environment.transformRequest(requestId(url)).catch(() => null);
        if (!result) return;
        for (const imported of staticImports(url, result)) {
          if (seen.has(imported)) continue;
          seen.add(imported);
          next.push(imported);
        }
      }),
    );
    level = next;
  }
  return [...seen];
}
