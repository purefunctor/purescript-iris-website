import { readColorTokens } from "#src/lib/colorTokens";
import { marks } from "#src/Website/Components/Logo.js";

/** The site icon: the logo's marks on a disc of the page canvas. Without `disc`, the marks stand alone. */
export async function renderFavicon({ disc = true } = {}): Promise<string> {
  const color = await readColorTokens();
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">${disc ? `<circle cx="16" cy="16" r="16" fill="${color["loam-950"]}"/>` : ""}${marks
    .map(({ x, y, radius, color: name }) =>
      `<circle cx="${x.toFixed(2)}" cy="${y.toFixed(2)}" r="${radius}" fill="${color[`spectrum-${name}`]}"/>`,
    )
    .join("")}</svg>`;
}
