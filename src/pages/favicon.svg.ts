import type { APIRoute } from "astro";
import { renderFavicon } from "#src/lib/favicon";

export const prerender = true;

export const GET: APIRoute = async () =>
  new Response(await renderFavicon(), { headers: { "Content-Type": "image/svg+xml" } });
