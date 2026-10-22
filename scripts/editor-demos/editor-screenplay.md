# Editor trailer screenplay

One continuous VS Code take, recorded with Cap, in which twelve language server features come up
while working on real code in this website. The take plays full screen from the opening card to
the end card without cutting, at recorded speed. Remotion draws only the semantic highlighting captions
over it; feature names are left to the landing page's chapter list, which already names each one.
There are no divider screens; the two acts below only group the features.

## Premise

The take follows the landing page's editor demo. It starts at the landing page's root component,
steps into the demo section that plays this trailer, follows the layout's breakpoints out to the
benchmark chart, tidies a type and a constructor, and then writes the demo section's chapter
selection handler.

- Files: `Website.Landing.Index` → `Website.Landing.Demos` → `Website.Landing.Benchmarks` →
  `Website.Components.CopyButton` → back to `Website.Landing.Demos`.
- Every edit happens in the disposable seed workspace.

## Staging

Before the take starts, the seed workspace's `Demos.purs` is patched:

1. `select number = for_ (index chapters number) \{ at } -> do …` (four lines) becomes
   `select _ = pure unit`.
2. `import Data.Foldable (for_)` is removed.

The editor opens fullscreen with the Explorer closed, `Index.purs` in the only tab scrolled to
lines 24–48, so that line 47 stays clear of the horizontal scrollbar, and semantic highlighting
**off**.

After the capture stops, the script saves every file and checks them against the repository's,
with the take's renames applied: `Demos.purs`, `Benchmarks.purs`, `CopyButton.purs`,
`Terminal.purs`, `CodeBlock.purs`, and `Button.purs`, whose own `Small` and `Medium` must be
untouched. Iris appends the automatic import after the existing ones, so imports compare in either
order. It then restores the seed files.

## Act I: Reading code

| # | Feature | What happens on screen | Where |
|---|---------|------------------------|-------|
| 1 | Semantic highlighting | `Index.purs` sits in TextMate colours, then recolours by role. Four captions point out what changed: **Declarations** at `styles`, **Record labels** at the style keys and `onInstall`, **Module qualifiers** at `Hooks` and `DOM`, and **Bindings** at `install`, `ripples` and `setRipples`. | `Landing/Index.purs:24–48` |
| 2 | Go to definition | Click `Demos.component` and press F12. `Demos.purs` opens at `component =`. The camera stays on the whole editor; hover zooms in. | `Index.purs:47` → `Demos.purs` |
| 3 | Hover | Hover `time` → `Number`; `/\` → `forall @t0 @t1. t0 -> t1 -> Tuple t0 t1` with its documentation; `seek` → `{ request :: Int, time :: Number }`; `<=` → `forall a. Ord a => a -> a -> Boolean`; `chapter` → `Maybe { at :: Number, description :: String, title :: String }`. | `Demos.purs` component |
| 4 | Document highlights | Click the lambda's `chapter` in `findLastIndex (\chapter -> chapter.at <= time)`. Only the parameter and its use light up; the `chapter` bound on the next line stays dark. | `Demos.purs` component |
| 5 | Document symbols | Ctrl+Shift+O, `@styles`. The editor jumps and scrolls on to bring `breakpoints.from960` into view, while the camera moves from the quick input to the style table without zooming out. | `Demos.purs` styles |
| 6 | Find references | Shift+F12 on `breakpoints`. The peek view lists its uses across nine modules. Open the `Code.purs` and `JavaScript.purs` entries in turn and step onto their first reference, so the preview shows each. | `Demos.purs` styles |
| 7 | Workspace symbols | Ctrl+T, `#Measured`. The camera zooms out and `Benchmarks.purs` opens at `type Measured a = { cold :: a, hot :: a }`. | `Landing/Benchmarks.purs` |

## Act II: Writing code

| # | Feature | What happens on screen | Where |
|---|---------|------------------------|-------|
| 8 | Rename | F2 on the type variable in `type Measured a` and type `value`: `type Measured value = { cold :: value, hot :: value }`. This happens where workspace symbols landed, in the same framing. | `Benchmarks.purs` |
| | | Quick open `CopyButton.purs`. F2 on `Small` in `data Size = Small \| Medium` and type `Compact`; the pattern in `sizeStyle` follows. Shift+F12 on `Compact`, then open the `CodeBlock.purs` and `Terminal.purs` entries: each preview shows `CopyButton.Compact`. `Button.purs` has its own `Small`, which stays. | `Components/CopyButton.purs` |
| 9 | Automatic imports | Back on the `Demos.purs` tab, the editor scrolls down to the stub under the whole-editor view. Select `_ = pure unit`, type `number = for_`, and accept `for_` (Data.Foldable) from completion. The editor scrolls up to show `import Data.Foldable (for_)` after the other imports, then back. The line finishes as `(index chapters number) \{ at } -> do`. | `Demos.purs` handler |
| 10 | Completion | On the next line, `setSee…` offers the local `setSeek` from the component's hook. | `Demos.purs` handler |
| 11 | Typed holes | Finish the update as `{ request: request + 1, time: ?time }`. Quick Fix on the hole lists `Replace hole with 'at'` above `time`, `mempty` and `zero`. Pick `at`. | `Demos.purs` handler |
| 12 | Diagnostics | The script turns on Iris's opt-in on-change diagnostics. Type `setTime at`, then `setPlaying true`: `true` is underlined before saving, and hovering it reads `Cannot unify 'Boolean' with 'Boolean -> Boolean'`. Change it to `(const true)` and the error clears. Ctrl+S. | `Demos.purs` handler |

## Pacing and camera

- `editor.mjs trailer` logs each feature's beat. Beats do not move the camera; each feature's
  result holds for half a second before the next one starts.
- Cap's zoom planner holds a framing for three seconds and keeps it across pauses of up to two
  seconds, so the camera pans between nearby work instead of zooming out and back in. Typing is
  framed on the text cursor. Workspace symbols zooms out for its jump to another file; document
  symbols stays zoomed from the quick input to the style table. Rename continues in workspace
  symbols' framing.
- From automatic imports to the end, the handler is written in place under one fixed 1.3× framing
  of the gutter and the handler's lines; the import is scrolled into the same framing and back, and
  diagnostics stays in it too.
- Each scroll is one swift, eased scroll. Quick input is framed as it opens,
  before anything is typed into it.
- Iris reports diagnostics on open and save by default, and the take keeps that default until the
  diagnostics beat, so half-typed lines elsewhere do not flash parse errors.
- Every beat asserts its result, so a failed beat fails the take instead of producing a misleading
  trailer.
