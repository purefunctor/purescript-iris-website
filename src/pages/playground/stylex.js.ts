import type { APIRoute } from "astro";
import { bundlePlaygroundStylex } from "#src/lib/playgroundStylex";

export const prerender = true;

// The runner imports this only when a program imports StyleX.
export const GET: APIRoute = async () =>
  new Response(await bundlePlaygroundStylex(), { headers: { "Content-Type": "text/javascript" } });
