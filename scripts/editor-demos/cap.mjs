// Cap (https://cap.so), the default capture backend for record.mjs.
// Cap renders its own smoothed cursor, click ripples and zoom from the recorded pointer data.
// Its CLI writes a default project configuration, so the zoom segments come from the action
// timeline that record.mjs logs: pointer positions and the overlays visible at each check. cap-setup.sh installs the CLI as $IRIS_DEMO_HOME/cap-cli; IRIS_DEMO_CAP
// overrides it, for example with `cap-cli` where Cap's packages install natively.
//
// Re-export a recorded take with different effects, without re-recording it:
//   node scripts/editor-demos/cap.mjs <clip> [--zoom 1.5] [--no-zoom] [--no-ripple]
import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const width = 1920, height = 1080;
const tools = process.env.IRIS_DEMO_HOME || '/tmp/iris-editor-tools';
const command = (process.env.IRIS_DEMO_CAP || `${tools}/cap-cli`).split(' ');
// Takes play at 85% of captured speed, against 75% for FFmpeg takes without zoom. Zoom and motion
// blur change every pixel, so CRF 28 keeps files near FFmpeg's size without visible loss in text.
export const speed = 0.85;
export const crf = 28;

function cap(...args) {
  const out = execFileSync(command[0], [...command.slice(1), ...args, '--json'],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 1 << 26 });
  const last = out.trim().split('\n').filter(Boolean).map(line => JSON.parse(line)).at(-1);
  if (!last || 'error' in last) throw new Error(`cap ${args.slice(0, 2).join(' ')}: ${last?.error ?? 'no result'}`);
  return last;
}

export function start(project) {
  rmSync(project, { recursive: true, force: true });
  mkdirSync(dirname(project), { recursive: true });
  return cap('record', 'start', '--screen', '0', '--fps', '60', '--path', project, '--detach').recordingId;
}

export const stop = id => cap('record', 'stop', '--id', id);

// Script time starts when `record start` returns. Align it with Cap's pointer log by the first
// moment Cap saw the pointer at the first logged action.
function offset(actions, moves) {
  const first = actions.find(a => a.x !== undefined);
  if (!first) return 0;
  const hit = moves.find(m => Math.abs(m.x * width - first.x) <= 2 && Math.abs(m.y * height - first.y) <= 2
    && m.time_ms / 1000 > first.t - 2);
  return hit ? hit.time_ms / 1000 - first.t : 0;
}

// Manual centres are in Cap's travel space: 0 is flush left/top and 1 flush right/bottom.
const travel = (p, amount) => Math.min(1, Math.max(0, (p - 0.5 / amount) / (1 - 1 / amount)));

// What an action needs in view: the pointer and any overlays logged with it, as [left, top, right, bottom].
function box(action) {
  const boxes = [...action.boxes ?? []];
  if (action.x !== undefined) boxes.push([action.x - 24, action.y - 24, action.x + 24, action.y + 24]);
  if (!boxes.length) return undefined;
  const [left, top] = [0, 1].map(i => Math.max(0, Math.min(...boxes.map(b => b[i]))));
  return [left, top, Math.min(width, Math.max(...boxes.map(b => b[2]))), Math.min(height, Math.max(...boxes.map(b => b[3])))];
}
const union = (a, b) => [Math.min(a[0], b[0]), Math.min(a[1], b[1]), Math.max(a[2], b[2]), Math.max(a[3], b[3])];

// Zoom segments that keep each action's pointer and overlays in frame. An action extends the
// current framing for `hold` seconds when the framing can include it without zooming out, or
// widens it from the start when its own framing contains the current one; otherwise the camera
// moves to a framing of its own. Framings that cannot zoom past `minimum`
// show the whole editor, as does an action with nothing to show. The last segment ends early
// enough for the zoom out to settle.
export function zoomSegments(actions, duration, { amount = 1.5, minimum = 1.2, margin = 48, hold = 2.4, settle = 1 } = {}) {
  const zoom = b => Math.min(amount, width / (b[2] - b[0] + 2 * margin), height / (b[3] - b[1] + 2 * margin));
  const runs = [];
  for (const a of actions) {
    const last = runs.at(-1);
    const b = box(a);
    if (!b) {
      if (last) last.end = Math.min(last.end, a.t);
      continue;
    }
    // Overlays are logged once visible; the pointer is logged on arrival, after its move began.
    const start = a.t - (a.action === 'ui' ? 0.2 : 0.5);
    const joined = last && start < last.end && union(last.box, b);
    if (joined && zoom(joined) >= last.zoom - 0.05) {
      Object.assign(last, { box: joined, zoom: zoom(joined), end: Math.max(last.end, a.t + hold) });
      continue;
    }
    // A wider framing that still shows everything the current one does replaces it from its start,
    // so the camera settles once instead of moving out partway.
    const contains = last && start < last.end && b[0] <= last.box[0] && b[1] <= last.box[1]
      && b[2] >= last.box[2] && b[3] >= last.box[3];
    if (contains) {
      Object.assign(last, { box: b, zoom: zoom(b), end: Math.max(last.end, a.t + hold) });
      continue;
    }
    if (last) last.end = Math.min(last.end, start);
    runs.push({ start, end: a.t + hold, box: b, zoom: zoom(b) });
  }
  return runs
    .map(r => ({ ...r, start: Math.max(0.05, r.start), end: Math.min(duration - settle, r.end) }))
    .filter(r => r.zoom >= minimum && r.end - r.start > 0.4)
    .map(r => ({
      start: r.start, end: r.end, amount: r.zoom,
      mode: { manual: {
        x: travel((r.box[0] + r.box[2]) / 2 / width, r.zoom),
        y: travel((r.box[1] + r.box[3]) / 2 / height, r.zoom),
      } },
      glideDirection: 'none', glideSpeed: 0.5, instantAnimation: false, edgeSnapRatio: 0.25,
    }));
}

// Cap replaces a last cursor shape held under a second until the last move. record.mjs ends each take
// with an invisible move that logs the shape the pointer rests in, so date that shape from the last
// scripted action when the pointer stayed put after it, such as a dialog closing under the pointer.
function holdRestingShape(path, since) {
  const events = JSON.parse(readFileSync(path, 'utf8'));
  const last = events.moves.at(-1);
  const time = Math.round(since * 1000);
  const rested = m => Math.abs(m.x - last.x) * width <= 2 && Math.abs(m.y - last.y) * height <= 2;
  if (!last || !events.moves.filter(m => m.time_ms > time).every(rested)) return;
  if (events.moves.findLast(m => m.time_ms <= time)?.cursor_id === last.cursor_id) return;
  events.moves.push({ ...last, time_ms: time });
  events.moves.sort((a, b) => a.time_ms - b.time_ms);
  writeFileSync(path, JSON.stringify(events, null, 2));
}

export function render(project, actions, output, { zoom = true, ripple = true, amount } = {}) {
  const json = path => JSON.parse(readFileSync(`${project}/${path}`, 'utf8'));
  const meta = json('recording-meta.json');
  const config = json('project-config.json');
  const moves = (meta.segments ?? [meta.segment]).flatMap(s => s.cursor ? json(s.cursor).moves : []);
  const duration = config.timeline.segments.reduce((sum, s) => sum + (s.end - s.start) / s.timescale, 0);
  const shift = offset(actions, moves);
  const aligned = actions.map(a => ({ ...a, t: a.t + shift }));
  const cursor = (meta.segments ?? [meta.segment]).at(-1).cursor;
  if (cursor && aligned.length) holdRestingShape(`${project}/${cursor}`, aligned.at(-1).t);
  config.timeline.zoomSegments = zoom ? zoomSegments(aligned, duration, amount ? { amount } : {}) : [];
  config.cursor.ripple = { ...config.cursor.ripple, enabled: ripple };
  writeFileSync(`${project}/project-config.json`, JSON.stringify(config, null, 2));
  cap('export', project, '--output', output, '--fps', '60', '--resolution', `${width}x${height}`, '--quality', 'maximum');
  return { shift, zoomSegments: config.timeline.zoomSegments };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const { positionals: [name], values } = parseArgs({ allowPositionals: true, options: {
    zoom: { type: 'string' }, 'no-zoom': { type: 'boolean' }, 'no-ripple': { type: 'boolean' },
  } });
  const project = `${tools}/cap/${name}.cap`;
  const raw = `${tools}/${name}-raw.mp4`;
  const output = process.env.IRIS_DEMO_OUTPUT || `${tools}/recordings`;
  const actions = JSON.parse(readFileSync(`${project}/iris-actions.json`, 'utf8'));
  console.log(JSON.stringify(render(project, actions, raw, {
    zoom: !values['no-zoom'], ripple: !values['no-ripple'], amount: values.zoom && Number(values.zoom),
  })));
  // The same retime and final hold as record.mjs, applied to the normal-speed export.
  mkdirSync(output, { recursive: true });
  execFileSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-an',
    '-vf', `setpts=(PTS-STARTPTS)/${speed},fps=60,tpad=stop_mode=clone:stop_duration=1`,
    '-c:v', 'libx264', '-preset', 'slow', '-crf', String(crf), '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', `${output}/${name}.mp4`]);
  console.log(`Exported ${output}/${name}.mp4`);
}
