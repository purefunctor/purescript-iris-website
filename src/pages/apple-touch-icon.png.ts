import type { APIRoute } from "astro";
import sharp from "sharp";
import { renderFavicon } from "#src/lib/favicon";

export const prerender = true;

export const GET: APIRoute = async () =>
  new Response(
    await sharp(Buffer.from(await renderFavicon()), { density: (180 / 32) * 72 }).resize(180, 180).png().toBuffer(),
    { headers: { "Content-Type": "image/png" } },
  );
