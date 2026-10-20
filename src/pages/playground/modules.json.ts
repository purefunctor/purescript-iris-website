import type { APIRoute } from "astro";
import { bundlePlaygroundModules } from "#src/lib/playgroundModules";

export const prerender = true;

// The runner fetches this only when a program imports one of its modules.
export const GET: APIRoute = async () =>
  new Response(JSON.stringify(await bundlePlaygroundModules()), { headers: { "Content-Type": "application/json" } });
