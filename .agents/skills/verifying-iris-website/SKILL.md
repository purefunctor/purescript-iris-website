---
name: verifying-iris-website
description:
  "Chooses and runs checks for changes to iris-lang.com: the development portal, the production
  preview, the development cache check, and the build benchmark. Use before reporting a change as
  done, or when a change touches styles, headers, the CSP, routing, media, the Vite configuration,
  or build speed claims."
---

# Verifying the Iris website

Pick checks by the files that a change touches. Add an automated check only for behaviour that can
break without a visible symptom, such as hydration, the development cache, and the CSP. A test that
repeats copy, styles, or constants fails on every intended edit and catches nothing else.

## Choose the checks

- If the change affects how a page looks, open the running Website portal and capture mobile and
  desktop viewports. Keep design choices out of browser test scripts, because the design changes
  often.
- If the change touches generated assets, `public/_headers`, the CSP, the documentation router, or
  video seeking, check it in the production preview.
- If the change touches the Vite configuration or a development plugin, run the development cache
  check.
- If the change touches a build speed claim, run the build benchmark.

## Check production-only behaviour

The dev server runs Astro on Node.js. Production serves static files through Wrangler, which applies
`public/_headers`. `astro preview` ignores that file. To check production-only behaviour, build the
site and serve it with Wrangler:

```sh
pnpm build
amp orb service start website-production --command 'pnpm preview' --port 8787 --portal --title 'Website (Production)'
```

When you finish, run `amp orb service stop website-production`. Start the preview only for the
changes listed above, and keep it out of `.amp/services.yaml`.

## Check the development cache

`scripts/test-dev-cache.mjs` runs a production build beside the running dev server. It then checks
that the build left the dev server's prebundles in place and that the landing page hydrates without
reoptimisation. The script needs agent-browser and a running dev server:

```sh
node scripts/test-dev-cache.mjs http://localhost:4321
```

## Run the build benchmark

`scripts/benchmark-builds.ts` measures the build times on the landing page. Its header describes the
method. The first run needs Bun, Spago, and network access. Pass the `purs` binary from an official
release and the Iris release that the landing page names:

```sh
bun scripts/benchmark-builds.ts --purs node_modules/purescript/purs.bin --iris "$(command -v iris)"
```

Copy the figures, versions, and bar widths from the output into
`src/Website/Landing/Benchmarks.purs`. Report compiler time separately from Spago and Vite overhead.
