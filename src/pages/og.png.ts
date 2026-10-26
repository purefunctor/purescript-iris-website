import type { APIRoute } from "astro";
import { renderOpenGraphImage } from "#src/lib/openGraphImage";

export const prerender = true;

const evenCoverageSeed = 5138;

export const GET: APIRoute = async () =>
  new Response(await renderOpenGraphImage({ seed: evenCoverageSeed }), { headers: { "Content-Type": "image/png" } });
