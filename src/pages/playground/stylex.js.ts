import type { APIRoute } from "astro";
import { bundlePlaygroundStylex } from "#src/lib/playgroundStylex";

export const prerender = true;

export const GET: APIRoute = async () =>
  new Response(await bundlePlaygroundStylex(), { headers: { "Content-Type": "text/javascript" } });
