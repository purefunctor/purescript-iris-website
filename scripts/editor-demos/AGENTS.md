# Editor demo recordings

This directory records demo videos in one style: continuous takes captured with Cap, whose zoom follows the scripted work, and a Remotion project that renders each trailer over its takes between the site's opening and end cards. It holds the landing page's editor trailer, a VS Code take, and the playground trailer, two Helium takes. These notes extend the repository's [`AGENTS.md`](../../AGENTS.md), whose design constraints and color token rules apply to the trailers too.

Each video has its own files, named after it: `<video>-setup.sh` and `<video>-launch.sh` for its app, `<video>.mjs` for its takes, `<video>-screenplay.md` for what they show, and `trailer/render-<video>.mjs`, `trailer/src/<video>.ts` and `trailer/src/<Video>Trailer.tsx` for its trailer. Published names stay as they are: the editor trailer is still the `trailer` take, the `Trailer` composition and `public/editor-demos/trailer*`.

## Recording environment

Commands below run from the repository root. The Linux recording environment needs `agent-browser`, FFmpeg, curl, unzip, fontconfig, Xvfb, Openbox, xdotool, the native Electron libraries and Cap. On Debian:

```sh
sudo apt-get install -y xvfb openbox xdotool bibata-cursor-theme \
  libnss3 libxss1 libasound2 libgtk-3-0 libgbm1 libxkbfile1 libsecret-1-0 xauth
bash scripts/editor-demos/cap-setup.sh
```

- [`cap-setup.sh`](cap-setup.sh) installs Cap 0.6.0 in an Ubuntu 24.04 chroot, because its Linux binaries need glibc 2.39, and writes the `/tmp/iris-editor-tools/cap-cli` wrapper that [`cap.mjs`](cap.mjs) runs (`IRIS_DEMO_CAP` can override it). Setup and capture use `/tmp/iris-editor-tools` by default (`IRIS_DEMO_HOME` can override it).
- Every launch script sources [`display.sh`](display.sh), which starts the recording display `:94` with the Bibata cursor and Openbox without window decorations. Only one app can own the display, so stop one video's service before starting another's.
- Capture is native 1920×1080 at 60 fps through Cap's CLI, which renders a smoothed cursor, click ripples and zoom, and exports H.264/yuv420p MP4 with fast start and no audio. On this CPU-only display Cap drops frames above 1080p (55 fps at 1440p, 11 fps at 4K).

## Recorder

[`recorder.mjs`](recorder.mjs) holds what every take shares. A video's script calls `recorder` once with its app's agent-browser session and CDP port, the overlays its checks log, a page script for where keyboard work happens, the chrome around its page, and any zoom planner settings. The script keeps its own key presses, typing and staging, because those differ between apps in ways the take shows; copy the library's delays rather than adjusting them, because each one changes a take's rhythm or its zoom.

- The CLI does not generate zoom itself: `cap.mjs` writes zoom segments from the pointer and keyboard actions that the recorder logs. Each passing `expect` also logs the uncovered overlays, such as hovers, suggestions, peek views and quick input, and the zoom frames the pointer and those boxes together, zooming less or not at all when they would not fit. A wider framing that contains the current one replaces it from its start, so the camera does not pull back partway through an action. A check whose subject is something else, such as highlighted references, a setting or recoloured code, names it with `shows`, a script returning elements, and is framed on that instead of the pointer. Clicks are held for 50 ms because Cap polls the pointer every 16 ms.
- `beat` marks where a feature starts, after holding the previous result for 500 ms. It does not move the camera itself, but Cap's zoom planner starts a new framing there, so one feature's framing never widens to take in the next; the camera pans between them instead. `beat(slug, { continues: true })` starts a feature without a new framing, for one that carries on where the previous ended. By default the planner holds each framing for three seconds and across pauses of up to two seconds. A check that finds nothing in view leaves the framing as it is; only `overview` zooms out, so wrap stretches that should stay unzoomed in it. `steadily` holds one fixed framing over a stretch, whatever moves inside it.
- Keyboard work is framed on the caret, and without one on the last pointer action. Scenarios leave the pointer where the work is rather than parking it, except that typing first moves it with `aside` into nearby negative space, preferably below and to the right, because the recording keeps it visible while typing.
- Scroll with `smoothScroll`, one swift ease-in-out that the page animates itself, a synthetic wheel event per frame, so it lands exactly where it should. Turn off the editor's own smooth scrolling, because it animates each event separately and stutters against the per-frame events; dragging the scrollbar and turning the wheel notch by notch both look choppy in the recording.
- `capture` records one take: the raw Cap export at recorded speed, which the trailer is cut from, and beside it `<take>.pace.json` on the raw export's timeline (where the scripted work starts and ends, each feature's beat, and the captions), a review copy at 85% speed with a one-second final-frame hold and CRF 28, which is not published, and the app's accessibility snapshot. It saves the actions and planner settings in the Cap project, so `node scripts/editor-demos/cap.mjs <take> --zoom 2` re-exports a take with different effects without re-recording it. `IRIS_DEMO_RECORDER=ffmpeg` captures the X display with FFmpeg instead, with the system cursor and no zoom.
- Every beat asserts its result, and each video checks the artefact its takes produce afterwards, so a take that passes shows what its screenplay describes.

## Editor trailer

[`editor.mjs`](editor.mjs) records the landing page's trailer, one continuous take in native VS Code that follows [`editor-screenplay.md`](editor-screenplay.md). It reproduces the native VS Code workflow from the [original recording thread](https://ampcode.com/threads/T-01a0cf38-55ca-765a-a413-2e7de30fe101), and seeds a disposable `iris-website` workspace from this checkout's `src`, `spago.yaml`, and `spago.lock`, using its installed dependencies and Iris on PATH. Never perform recording edits in the website checkout itself.

```sh
bash scripts/editor-demos/editor-setup.sh
amp orb service start iris-demo-code --command 'bash scripts/editor-demos/editor-launch.sh'
agent-browser --session iriscode --cdp 9223 press F11
node scripts/editor-demos/editor.mjs trailer
(cd scripts/editor-demos/trailer && pnpm install --frozen-lockfile && node render-editor.mjs)
```

- [`editor-setup.sh`](editor-setup.sh) pins VS Code 1.139.0, Iris extension 0.1.0, PureScript syntax extension 0.2.10 and Geist 1.7.2. The current take uses Iris 0.1.10. It selects Geist for the workbench and Geist Mono for code, and keeps Iris's diagnostics defaults; the take turns on-change diagnostics on only for its live-diagnostics beat, so half-typed code elsewhere does not flash parse errors. Setup resets only the disposable workspace and profile; stop VS Code before rerunning it, and rerun it so that the seed matches the checkout.
- [`theme.ts`](theme.ts) generates the editor colors from the site's tokens in `src/global.css` and layers them over Default Dark Modern through the profile's color customization settings, so recordings match the site. Change the tokens or the mapping there rather than editing the profile, then rerun setup and record again.
- Electron's scale factor is 150% by default; this scales the whole application, not just the editor font, and `IRIS_DEMO_SCALE=200` or `300` sizes the display for larger captures. Use VS Code's F11 fullscreen, not the window manager's fullscreen; the script presses F11 again if the display restarted. Do not apply browser viewport emulation to the Electron session.
- Act I reads `Website.Landing.Index`, `Website.Landing.Demos` and `Website.Landing.Benchmarks`, and Act II renames a type variable in `Benchmarks` and a `CopyButton` constructor across modules, then writes the demo section's chapter selection handler. Staging stubs that handler and its `for_` import in the seed. After the take the saved files must equal the repository's with the take's renames applied, so moving or renaming that code means updating the scenario and the screenplay together.
- Keys go to VS Code through CDP. Keys pressed with `pressWithoutFraming` rather than `press` are not framed, for keys whose text cursor is somewhere the camera should not go. `quickInput` frames quick input as it opens, before anything is typed into it. Rename continues workspace symbols' framing, and Act II writes the handler from automatic imports to diagnostics under one `steadily` 1.3× framing of the gutter and the handler, with the import scrolled into the same framing and back.
- Semantic highlighting is switched on by writing the profile's settings, and the script logs the screen boxes of the tokens it recolours, grouped by role, for the trailer's captions; it fails if a recoloured token has no caption.
- A failed take can leave unsaved edits, a refactor preview or a native dialog behind. Staging saves and closes editors and closes panels, and refuses to start while a native VS Code dialog is open, because those take all input and are invisible to CDP screenshots; capture the X display with FFmpeg to see one.

## Playground trailer

[`playground.mjs`](playground.mjs) records the playground trailer that [`playground-screenplay.md`](playground-screenplay.md) describes, in Helium. It drives the deployed site, https://iris-lang.com by default (`--site` overrides it), so the share link shows the real domain; record after the deploy that carries the playground you want to show.

```sh
bash scripts/editor-demos/playground-setup.sh
amp orb service start iris-demo-playground --command 'bash scripts/editor-demos/playground-launch.sh'
node scripts/editor-demos/playground.mjs
(cd scripts/editor-demos/trailer && node render-playground.mjs)
```

- [`playground-setup.sh`](playground-setup.sh) unpacks Helium's portable Linux build, because its .deb needs Ubuntu's `t64` libraries. [`playground-launch.sh`](playground-launch.sh) runs it fullscreen at 100% with a fresh profile and remote debugging on port 9224.
- The page renders at 100%, so the take zooms further than the editor take (1.8×), and as little as 1.1×, and holds a framing across pauses of up to six seconds, panning between places instead of zooming out. Typing is framed from where it starts to where it ends, so the caret stays near the middle of the frame. The camera moves to the code before each scroll, so the scroll plays in view, and frames Run together with the program it renders, zooming in only as far as both fit, so it does not pan to the program once it renders.
- Keys go to Helium through xdotool rather than CDP, because the incognito window and the program's sandboxed frame are reached only through X. The script finds the frame's elements through agent-browser's accessibility snapshot, which inlines the frame, and offsets them by the frame's position. Typing in Monaco opens suggestions, which Enter accepts, so the script presses Escape before new lines.
- The take ends by checking the share link's project. The incognito take zooms in on the address bar for the paste and shows the whole window while the project loads. `--share-only` records it again from the saved link, after Share copies it again, without recording the playground take.

## Trailers

[`trailer`](trailer) is a Remotion project with its own pnpm workspace and lockfile, so the site's install and deployment never fetch Remotion. It imports `src/global.css`, `Backdrop.js` and `Logo.js` from the site, so the cards use the site's tokens, Geist, the logo and the hero's dot lattice; change those there rather than copying values into the trailers.

- [`takes.ts`](trailer/src/takes.ts) holds what every trailer shares about its takes: the composition's size and rate, the cards' timing, the pacing type, and `beat`, `retime` and `chapters`. [`Scenes.tsx`](trailer/src/Scenes.tsx) holds the opening and closing lockups, the lattice backdrop and `Clip`, a take placed in the frame. Each trailer passes the lockups its own line, command and link, and the end card's lockup matches the opening's. [`Root.tsx`](trailer/src/Root.tsx) registers each composition in one line. Keep one plan and one component per trailer, and share a layout only once two trailers use it exactly.
- Each `render-<video>.mjs` names its trailer, composition, plan and takes, and runs the pipeline in [`renderer.mjs`](trailer/renderer.mjs). It copies the raw takes in, renders a 4K master at CRF 12 (twice the composition's size), and encodes from it at 1080p60 with fast start: `out/<name>-av1.mp4` (SVT-AV1, CRF 52, about 40% smaller), the `out/<name>.mp4` H.264 fallback (CRF 28, High profile, level 4.2), and the `out/<name>.webp` poster from the opening lockup. It prints each chapter's start time. `--scale 1` renders the master at 1080p instead, which takes about a third as long, for checking a take; publish only from a 4K master. `--encode` redoes only the encodes from the last master, and `--review rename,completion` cuts those features, by slug, from the last encode into `out/review`, so a change can be reviewed without the whole trailer. `--still 240,1200` renders single frames and `--frames 0-600` a range, for checking a design without a full render; `pnpm studio` opens Remotion Studio after one render has written the manifests to `public/`.
- Review a render frame by frame around every transition and the captions, check its dimensions, frame rate and decode with ffprobe/FFmpeg, and keep raw takes, Cap projects, rendered masters and diagnostic snapshots out of Git.

### Editor trailer

The landing page plays it from `public/editor-demos/`.

- [`chapters.ts`](trailer/src/chapters.ts) holds the running order and each feature's generic name, which must match the take's beats; its two acts group the landing page's chapter list. [`editor.ts`](trailer/src/editor.ts) plans the take as one continuous, full-screen shot between the opening and end cards, at recorded speed throughout. Cap's zoom stays as recorded.
- The only overlays on the take are the semantic highlighting captions in [`EditorTrailer.tsx`](trailer/src/EditorTrailer.tsx), which fade in place rather than sliding; there are no divider screens. Do not caption feature names over the take, because the landing page's chapter list and the caption under the player already name each feature.
- Copy the three encodes to `public/editor-demos/`, and update the `at` times in `Website.Landing.Demos`, whose chapter list seeks the trailer. The landing page's player lists the AV1 source first with its `codecs` string, so browsers that cannot decode AV1 fall back to H.264; keep those strings in step with the encodes' profiles and levels. Inspect playback and chapter seeking on the landing page at desktop and mobile widths. Production serves the trailer without Range support, so check seeking in the production preview as well as in development.

### Playground trailer

[`playground.ts`](trailer/src/playground.ts) plays the playground take full screen, then moves it into the left half as the incognito take slides in on the right, and hurries through the shared project's download. [`PlaygroundTrailer.tsx`](trailer/src/PlaygroundTrailer.tsx) captions each feature's name over the takes, because the trailer has no chapter list beside it; drop those captions if it is published with one.

## Adding a video

1. Write `<video>-screenplay.md`: the beats in order, and what each must show.
2. Reuse a setup and launch script if the app is the same; otherwise write `<video>-setup.sh`, and `<video>-launch.sh`, which sources `display.sh` and starts the app with its own CDP port. A second VS Code video can instead be another case in `editor.mjs`.
3. Write `<video>.mjs`: `recorder({ session, cdp, overlays, caret, chrome, planner })`, the app's own key presses and typing, staging, beats that each `expect` their result, a check of what the take produced, a check of the display's size and scale, and `browser('close')` when it ends.
4. Write `trailer/src/<video>.ts`, with its manifest type, features whose slugs match the beats, and `plan`, using `takes.ts`, and `trailer/src/<Video>Trailer.tsx` from `Scenes.tsx`. Register it in `Root.tsx`, and add `trailer/render-<video>.mjs` naming its takes and manifest file.
5. Add a section for it to this file, record it, and review a `--scale 1` render before rendering the 4K master.
