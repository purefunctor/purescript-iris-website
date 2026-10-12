import { defineMiddleware } from "astro:middleware";
import { modulePreloads } from "#src/lib/devModulePreload";

const entryAttributes = /\s(?:component-url|renderer-url|before-hydration-url)="([^"]+)"|<script type="module" src="([^"]+)"/g;

export const onRequest = defineMiddleware(async (_context, next) => {
  const response = await next();
  if (!response.headers.get("content-type")?.startsWith("text/html")) return response;
  const html = await response.text();
  const entries = [...new Set([...html.matchAll(entryAttributes)].map((match) => (match[1] ?? match[2]).replaceAll("&amp;", "&")))];
  const preloads = (await modulePreloads(entries)).map((url) => `<link rel="modulepreload" href="${url.replaceAll("&", "&amp;")}">`);
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  return new Response(html.replace("</head>", `${preloads.join("")}</head>`), { status: response.status, headers });
});
