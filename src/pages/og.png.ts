import type { APIRoute } from "astro";
import { renderOpenGraphImage } from "#src/lib/openGraphImage";

export const prerender = true;

// Chosen for its even coverage around the centred lockup.
const seed = 5138;

export const GET: APIRoute = async () =>
  new Response(await renderOpenGraphImage({ seed }), { headers: { "Content-Type": "image/png" } });
