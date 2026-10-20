import type { APIRoute } from "astro";
import { bundlePlaygroundReact } from "#src/lib/playgroundReact";

export const prerender = true;

// The runner fetches this only when a program imports React.
export const GET: APIRoute = async () =>
  new Response(JSON.stringify(await bundlePlaygroundReact()), { headers: { "Content-Type": "application/json" } });
