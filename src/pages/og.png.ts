import type { APIRoute } from "astro";
import { renderOpenGraphImage } from "#src/lib/openGraphImage";

export const prerender = true;

export const GET: APIRoute = async () =>
  new Response(
    await renderOpenGraphImage("Functional programming\nfor the browser, the server,\nand everywhere in between."),
    { headers: { "Content-Type": "image/png" } },
  );
