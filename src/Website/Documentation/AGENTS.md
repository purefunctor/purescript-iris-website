# Documentation pages

The documentation pages under `/docs/` follow the root [`AGENTS.md`](../../../AGENTS.md) and the rules below.

## Pages and links

Each documentation page is a `Website.Documentation` module with a prerendered route in `src/pages/docs` that uses `DocumentationLayout`. Add each page to `Page` in `Website.Components.Documentation`, which orders the header navigation and the previous and next links, and build its body from `Website.Documentation.Prose`.

- Link to documentation pages by their trailing-slash URLs, such as `/docs/installation/`. Production serves each page's `index.html` there and answers the bare form with an uncacheable 307, which would add a round trip to every swap.
- The compiler README links to these routes. Keep their slugs stable, or update those links when you rename a page.

## Switching pages

Switching between documentation pages should be as fast as on sites such as react.dev. `DocumentationLayout` adds Astro's `<ClientRouter />`, so a link to another documentation page swaps in the next document and hydrates its island without a full reload. Swaps cut straight to the next page without an animation. In production, [`documentationPageCache`](../../lib/documentationPageCache.ts) keeps pages in memory for the rest of a visit and fetches linked pages and their island modules ahead of time, so most swaps make no request. Astro's `prefetch` stays disabled so that pages are not fetched twice.

In development, the StyleX runtime fills `#__stylex_virtual__` once and disables the `/virtual:stylex.css` link, so `DocumentationLayout` keeps that element across swaps with `transition:persist`. Without it, swapped pages lose their StyleX rules until the next HMR update.

The root guide's section on static output and the CSP explains why these pages must not add page-specific inline scripts or styles.

## Verification

Use the running watch-mode preview for documentation changes, with targeted browser checks and visual inspection. Do not run production builds or add a documentation-specific test harness for visual tweaks. Check router changes in the production preview, and verify changes to onboarding commands in a disposable workspace.
