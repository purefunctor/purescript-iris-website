# Playground trailer screenplay

Two takes of the playground at iris-lang.com, recorded with Cap in Helium by
[`playground.mjs`](playground.mjs), and a Remotion composition, `Playground`, that plays them
between the opening and end cards. Like the editor trailer, it captions each feature as it starts,
with no divider screens.

## Premise

A new visitor opens the playground, runs the example, then builds up to a two-module React app
that uses a Registry package, and shares it. The trailer ends by opening the share link in a fresh
incognito window, where the same project loads and runs.

## Staging

Helium runs fullscreen at 100% on the 1920 × 1080 recording display, and Cap's zoom enlarges the
work as it happens. Before the take, the script visits the playground once with the take's packages
activated, so that switching templates and activating `heckin` do not wait on downloads, then
clears local storage, so the take starts on the Console template like a first visit. The
incognito window shares no cache, so it downloads the shared project's packages itself.

## Take 1: the playground

| # | Feature | What happens on screen |
|---|---------|------------------------|
| 1 | Run in the browser | Run. The Output panel prints `Hello, Iris!` and the sum. |
| 2 | Edit and run again | Select `Iris` in `log (greet "Iris")`, type `PureScript`, Run: `Hello, PureScript!`. |
| 3 | React templates | Open the React counter template and run it; click `+` three times and `−` once. |
| 4 | Completion with imports | Change the button's `onClick` to a `do` block, indented past `onClick`, complete `log` from `Effect.Console`, which adds its import, and log the count before `setCount change`. |
| 5 | Console | Run, click `+` five times: the console over the program lists each count. Drag its edge up over the program and back down, collapse it from its bar, and bring it back. |
| 6 | React todos | Open the React todos template and run it. Add `share the playground` and tick `Write some PureScript`. |
| 7 | Registry packages | In Packages, show all 631, search `heckin` and switch it on; the server restarts with it. |
| 8 | Imports from packages | In `add`, change `text` to `text: toTitleCase text`, completing `toTitleCase` from `Data.String.Casing`. Run and add the same todo: it reads `Share The Playground`. |
| 9 | StyleX | Set the title's `fontSize` to `32` and `fontWeight` to `800, color: colors.accent`, and run: the heading grows and turns orange. |
| 10 | Multiple modules | New file, renamed to `src/Styles.purs`, which renames its module. Import `Iris.StyleX`, cut the colors and styles from `Main.purs` into it, import `Styles (styleProps, styles)` in `Main`, and run. |
| 11 | Share by link | Share: the key reads Copied, and the address holds the project. |

After the take, the script decodes the share link and checks that it carries both modules, the
edits and `heckin`, and saves it as `playground.link` beside the recordings.

## Take 2: the share link

| # | Feature | What happens on screen |
|---|---------|------------------------|
| 12 | Open the link anywhere | The camera zooms in on an incognito window's address bar as the link is pasted, then shows the whole window. The project loads with its packages, both tabs open, and it runs; a new todo is title-cased there too. |

## The cut

The first take plays full screen at recorded speed. Once Share has copied the link, it shrinks
into the left half while the incognito window slides in on the right, and the two play side by
side. The incognito window's package download plays six times as fast, and both fade under the
end card.
