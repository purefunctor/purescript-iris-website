import type { APIRoute } from "astro";
import { bundlePlaygroundModules } from "#src/lib/playgroundModules";

export const prerender = true;

export const GET: APIRoute = async () =>
  new Response(JSON.stringify(await bundlePlaygroundModules()), { headers: { "Content-Type": "application/json" } });
