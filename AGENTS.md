# Agent guide

The repository contains the iris-lang.com website. It uses Astro, React, and PureScript compiled
with Iris, and Cloudflare Workers serves it.

## Ethos

### Truthfulness

- Check every claim on the site against the compiler.
- Demonstrate Iris with real output rather than describing it.
- Check a claim before you weaken it.

### Speed

- Keep page loads and page switches as fast as static files allow.
- Add client modules and dependencies only when a page needs them.
- Keep the development server as fast as the site it serves.

### Posterity

- Write code for future contributors, reviewers, and maintainers.
- Write code that you will understand 10 years later.
- Write code that you will not hate 10 years later.

### Simplicity

- Avoid abstractions for their own sake.
- Write abstractions if they remove real duplication across pages or components.
- Prefer PureScript over JavaScript FFI, and FFI over configuration.

## In context of work

Fix the root cause. When a component renders incorrectly, a page hydrates slowly, or a page breaks
under the CSP, find the stage that introduced the fault. The stages are the PureScript source, the
Iris output, the Vite and Astro build pipeline, and the static headers. Fix the fault in the stage
that introduced it. Before you change the site's architecture, hosting model, or build pipeline,
tell the user and wait for their decision.

## Sources of truth

- `purefunctor/purescript-iris` is the source of truth for compiler behaviour, architecture,
  compatibility, and performance claims.
- Measure build speed claims with the build benchmark in the `verifying-iris-website` skill. `purs`
  cannot compile this website, because the website uses Iris StyleX.
- Claims that Iris compiles existing PureScript libraries and projects refer to compatibility
  testing against the PureScript Registry package set. The `tests-compatibility` crate in the
  compiler repository and its CI workflows define what that testing covers.

## Exploring the project

For frontend work, start from the route. Each Astro page in `src/pages` renders the `component` of a
PureScript module as an island. Find the module from the page, then use the queries in
`iris skills get watch` alongside the source files. Website modules use the `Website.` prefix and
live in `src/Website`.

## Code conventions

In addition to the ethos, follow the project's existing conventions for names, module organisation,
and formatting.

For example:

```purescript
-- Yes: Export the module's main component as `component` and use it qualified.
import Website.Landing.Index as Index

Index.component

-- No: Do not rename the main component after its module.
import Website.Landing.Index (landingPage)
```

### Comments

Agents must not write new comments in any form: `--` and `{- -}` comments in PureScript, `-- |`
documentation, or `//` and `/* */` comments in JavaScript, TypeScript, and Astro files. Humans write
the website's comments and documentation.

### Imports and dependencies

- Use the package import aliases `#src/*` and `#output/*` for imports across directories.
- In an FFI module, import colocated JavaScript through `#src/Website/...`. Iris copies FFI modules
  into `output/`, where relative paths break.
- Import `react-aria-components` by component subpath, such as `react-aria-components/Button`.
- When an FFI module imports a new npm package or `react-aria-components` subpath, add it to
  `optimizeDeps.include` in `astro.config.mjs`. Otherwise the dev server reloads the page on the
  first visit that uses it.

### Styles

- Write component styles in PureScript with `Iris.StyleX`, following `iris skills get stylex`.
- Move styles into a colocated module only when three or more components share them.
- Render dynamic styles only on the client. They emit inline CSS variables, and the CSP blocks those
  in server-rendered HTML.
- Use the viewport breakpoints in `Website.Breakpoints`, and keep their exact bounds.

### Component exports

- Name a module's main `ReactComponent` `component`, and import it qualified, as in
  `Index.component`. Astro pages and JavaScript consumers depend on this name.
- Name effectful `Component props` constructors after their content, such as `header`.
- Name each `ReactComponent` descriptively when the module exports several components.

### Static output and the CSP

- Export `prerender = true` from every page and endpoint. Cloudflare serves the build as static
  assets, so no code runs per request. The [README](README.md#publishing) lists the limits.
- Play media through `Website.Components.VideoPlayer`. Static assets ignore Range requests, so
  streamed media cannot seek and Safari does not play it.
- Set security and cache headers in `public/_headers`, and the CSP in `security.csp` in
  `astro.config.mjs`.
- Allow inline styles only on the playground page, where Monaco creates them at run time.
- Give every documentation page the same inline scripts and styles. The client router keeps the
  first page's CSP, so a page with its own hashes breaks after a swap.
- Check media seeking, headers, and router changes in the production preview from the
  `verifying-iris-website` skill. The dev server does not enforce the CSP, and it answers Range
  requests.

## Taste

- Inspired by 2000s web and graphic design, made responsive and accessible.
- Edgy, square geometry where rounding is reserved for emphasis.
- Subtle neumorphism modelled after 90s and early 2000s audio equipment.
- Single strong accent colour, quiet motion that guides the user, and plain copy.
- Kerning over tracking when designing custom wordmarks.

## Commits

Make each commit one atomic unit of work. Before you publish a branch, arrange its commits into a
sequence that a reviewer can follow. Run `iris format` before you merge a branch, and squash the
formatting changes into the commits they belong to.

### Commit format

Write commit titles that are short, imperative, and in sentence case. Describe the change that
readers or contributors see:

```text
Drop the documentation page footer
Rewrite getting started for existing PureScript users
Load every active package source in the playground server
```

### Merge commit format

Title merge commits `[category] description`, where the category names the area that changed. Use
one of these categories, and check recent history on `main` when you are unsure:

- `landing` for the landing page and its trailer
- `docs` for documentation pages
- `playground` for the playground
- `dev` for the development server and tooling
- `agents` for agent configuration
- `meta` for repository-wide maintenance
- `ci` for workflows

Conventional commit types such as `fix` and `feat` describe the kind of change, so they are not
categories.

Good merge commit subjects:

```text
[playground] Download only the packages a template needs
[docs] Move documentation pages into a left rail and sections to the right
[dev] Keep Iris source maps working in the dev server
```

Bad merge commit subjects:

```text
Download only the packages a template needs   # Missing category
[feat] Add the playground                     # Describes the change type, not the area
[docs/playground] Share the code block        # Lists multiple categories
[misc] Update styles                          # Uses a vague category despite a clear area
```
