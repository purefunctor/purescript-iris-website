import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const displaySizeByScale = { 150: [1920, 1080], 200: [2560, 1440], 300: [3840, 2160] };
export const [width, height] = displaySizeByScale[process.env.IRIS_DEMO_SCALE || 150];
const tools = process.env.IRIS_DEMO_HOME || '/tmp/iris-editor-tools';
const command = (process.env.IRIS_DEMO_CAP || `${tools}/cap-cli`).split(' ');
export const reviewSpeed = 0.85;
export const reviewCrf = 28;
export const slowWithFinalFrameHold = speed => `setpts=(PTS-STARTPTS)/${speed},fps=60,tpad=stop_mode=clone:stop_duration=1`;

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

function offsetToPointerLog(actions, moves) {
  const firstPointerAction = actions.find(a => a.x !== undefined);
  if (!firstPointerAction) return 0;
  const firstSighting = moves.find(m => Math.abs(m.x * width - firstPointerAction.x) <= 2
    && Math.abs(m.y * height - firstPointerAction.y) <= 2 && m.time_ms / 1000 > firstPointerAction.t - 2);
  return firstSighting ? firstSighting.time_ms / 1000 - firstPointerAction.t : 0;
}

const travelSpaceCentre = (p, amount) => Math.min(1, Math.max(0, (p - 0.5 / amount) / (1 - 1 / amount)));

function boxInView(action) {
  const boxes = [...action.boxes ?? []];
  const pointerReach = 24 * width / 1920;
  if (action.x !== undefined) boxes.push([action.x - pointerReach, action.y - pointerReach, action.x + pointerReach, action.y + pointerReach]);
  if (!boxes.length) return undefined;
  const [left, top] = [0, 1].map(i => Math.max(0, Math.min(...boxes.map(b => b[i]))));
  return [left, top, Math.min(width, Math.max(...boxes.map(b => b[2]))), Math.min(height, Math.max(...boxes.map(b => b[3])))];
}
const union = (a, b) => [Math.min(a[0], b[0]), Math.min(a[1], b[1]), Math.max(a[2], b[2]), Math.max(a[3], b[3])];
const overlayLoggedAfterAppearing = 0.2;
const pointerLoggedAfterMoveStarted = 0.5;

export function zoomSegments(actions, duration, { amount = 1.5, minimum = 1.2, margin = 48 * width / 1920, hold = 3, settle = 1, bridge = 2 } = {}) {
  const zoom = b => Math.min(amount, width / (b[2] - b[0] + 2 * margin), height / (b[3] - b[1] + 2 * margin));
  const runs = [];
  const endFramingBefore = (last, start) => {
    const bridgesPause = last && !last.closed && start - last.end < bridge;
    if (bridgesPause) last.end = start;
    else if (last) last.end = Math.min(last.end, start);
  };
  for (const a of actions) {
    const last = runs.at(-1);
    if (a.action === 'beat') {
      if (last) last.split = true;
      continue;
    }
    if (a.action === 'steady') {
      if (last?.steady && last.box.join() === a.box.join()) {
        last.end = Math.max(last.end, a.t + hold);
        continue;
      }
      endFramingBefore(last, a.t);
      runs.push({ start: a.t, end: a.t + hold, box: a.box, zoom: a.zoom, steady: true });
      continue;
    }
    const b = boxInView(a);
    if (!b) {
      if (a.action === 'overview' && last) Object.assign(last, { end: Math.min(last.end, a.t), closed: true });
      continue;
    }
    const start = a.t - (a.action === 'ui' ? overlayLoggedAfterAppearing : pointerLoggedAfterMoveStarted);
    const joined = last && !last.split && start < last.end && union(last.box, b);
    if (joined && zoom(joined) >= last.zoom - 0.05) {
      Object.assign(last, { box: joined, zoom: zoom(joined), end: Math.max(last.end, a.t + hold) });
      continue;
    }
    const widensCurrentFraming = last && !last.split && start < last.end && b[0] <= last.box[0] && b[1] <= last.box[1]
      && b[2] >= last.box[2] && b[3] >= last.box[3];
    if (widensCurrentFraming) {
      Object.assign(last, { box: b, zoom: zoom(b), end: Math.max(last.end, a.t + hold) });
      continue;
    }
    endFramingBefore(last, start);
    runs.push({ start, end: a.t + hold, box: b, zoom: zoom(b) });
  }
  return runs
    .map(r => ({ ...r, start: Math.max(0.05, r.start), end: Math.min(duration - settle, r.end) }))
    .filter(r => r.zoom >= minimum && r.end - r.start > 0.4)
    .map(r => ({
      start: r.start, end: r.end, amount: r.zoom,
      mode: { manual: {
        x: travelSpaceCentre((r.box[0] + r.box[2]) / 2 / width, r.zoom),
        y: travelSpaceCentre((r.box[1] + r.box[3]) / 2 / height, r.zoom),
      } },
      glideDirection: 'none', glideSpeed: 0.5, instantAnimation: false, edgeSnapRatio: 0.25,
    }));
}

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

export function render(project, actions, output, { zoom = true, ripple = true, amount, planner = {} } = {}) {
  const json = path => JSON.parse(readFileSync(`${project}/${path}`, 'utf8'));
  const meta = json('recording-meta.json');
  const config = json('project-config.json');
  const moves = (meta.segments ?? [meta.segment]).flatMap(s => s.cursor ? json(s.cursor).moves : []);
  const duration = config.timeline.segments.reduce((sum, s) => sum + (s.end - s.start) / s.timescale, 0);
  const shift = offsetToPointerLog(actions, moves);
  const aligned = actions.map(a => ({ ...a, t: a.t + shift }));
  const cursor = (meta.segments ?? [meta.segment]).at(-1).cursor;
  if (cursor && aligned.length) holdRestingShape(`${project}/${cursor}`, aligned.at(-1).t);
  config.timeline.zoomSegments = zoom ? zoomSegments(aligned, duration, { ...planner, ...(amount ? { amount } : {}) }) : [];
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
  const planner = existsSync(`${project}/iris-planner.json`) ? JSON.parse(readFileSync(`${project}/iris-planner.json`, 'utf8')) : {};
  console.log(JSON.stringify(render(project, actions, raw, { planner,
    zoom: !values['no-zoom'], ripple: !values['no-ripple'], amount: values.zoom && Number(values.zoom),
  })));
  mkdirSync(output, { recursive: true });
  execFileSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-an',
    '-vf', slowWithFinalFrameHold(reviewSpeed),
    '-c:v', 'libx264', '-preset', 'slow', '-crf', String(reviewCrf), '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', `${output}/${name}.mp4`]);
  console.log(`Exported ${output}/${name}.mp4`);
}
