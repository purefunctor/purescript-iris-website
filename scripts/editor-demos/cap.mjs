// Cap (https://cap.so) as the capture backend for record.mjs: IRIS_DEMO_RECORDER=cap.
// Cap renders its own smoothed cursor, click ripples and zoom from the recorded pointer data.
// Its CLI writes a default project configuration, so the zoom segments come from the action
// timeline that record.mjs logs. cap-setup.sh installs the CLI as $IRIS_DEMO_HOME/cap-cli; IRIS_DEMO_CAP
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

// One zoom segment per run of nearby actions. Each action holds focus until the next one,
// or for `hold` seconds; an action without a position ends the run. The last segment ends
// early enough for the zoom out to settle.
export function zoomSegments(actions, duration, { amount = 1.5, lead = 0.5, hold = 2.4, settle = 1 } = {}) {
  const runs = [];
  for (const a of actions) {
    const zoom = a.zoom ?? amount;
    const last = runs.at(-1);
    if (a.x === undefined) {
      if (last) last.end = Math.min(last.end, a.t);
      continue;
    }
    const fits = last && last.zoom === zoom && a.t - last.end < 1.2
      && Math.max(last.maxX, a.x) - Math.min(last.minX, a.x) < width * 0.5 / zoom
      && Math.max(last.maxY, a.y) - Math.min(last.minY, a.y) < height * 0.5 / zoom;
    if (fits) Object.assign(last, {
      end: a.t + hold, minX: Math.min(last.minX, a.x), maxX: Math.max(last.maxX, a.x),
      minY: Math.min(last.minY, a.y), maxY: Math.max(last.maxY, a.y),
    });
    else {
      if (last) last.end = Math.min(last.end, a.t - lead);
      runs.push({ start: a.t - lead, end: a.t + hold, zoom, minX: a.x, maxX: a.x, minY: a.y, maxY: a.y });
    }
  }
  return runs
    .map(r => ({ ...r, start: Math.max(0.05, r.start), end: Math.min(duration - settle, r.end) }))
    .filter(r => r.end - r.start > 0.4)
    .map(r => ({
      start: r.start, end: r.end, amount: r.zoom,
      mode: { manual: {
        x: travel((r.minX + r.maxX) / 2 / width, r.zoom),
        y: travel((r.minY + r.maxY) / 2 / height, r.zoom),
      } },
      glideDirection: 'none', glideSpeed: 0.5, instantAnimation: false, edgeSnapRatio: 0.25,
    }));
}

export function render(project, actions, output, { zoom = true, ripple = true, amount } = {}) {
  const json = path => JSON.parse(readFileSync(`${project}/${path}`, 'utf8'));
  const meta = json('recording-meta.json');
  const config = json('project-config.json');
  const moves = (meta.segments ?? [meta.segment]).flatMap(s => s.cursor ? json(s.cursor).moves : []);
  const duration = config.timeline.segments.reduce((sum, s) => sum + (s.end - s.start) / s.timescale, 0);
  const shift = offset(actions, moves);
  const aligned = actions.map(a => ({ ...a, t: a.t + shift }));
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
  // The same 75% retime and final hold as record.mjs, applied to the normal-speed export.
  mkdirSync(output, { recursive: true });
  execFileSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-an',
    '-vf', 'setpts=(PTS-STARTPTS)/0.75,fps=60,tpad=stop_mode=clone:stop_duration=1',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '23', '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', `${output}/${name}.mp4`]);
  console.log(`Exported ${output}/${name}.mp4`);
}
