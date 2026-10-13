// Run against the disposable native VS Code started by launch.sh, never the seed editor.
import { execFileSync, spawn } from 'node:child_process';
import { once } from 'node:events';
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const tools = process.env.IRIS_DEMO_HOME || '/tmp/iris-editor-tools';
const output = resolve(process.env.IRIS_DEMO_OUTPUT || `${tools}/recordings`);
const session = 'iriscode';
const env = { ...process.env, DISPLAY: ':94' };
const run = (name, args) => execFileSync(name, args, { env, encoding: 'utf8' }).trim();
const browser = (...args) => run('agent-browser', ['--session', session, '--cdp', '9223', ...args]);
const evaluate = code => JSON.parse(browser('eval', code));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const press = key => (focus(), browser('press', key));
const input = '.quick-input-widget input';
// cap renders Cap's cursor, click ripples and zoom (cap.mjs); ffmpeg captures the X display as is.
const recorder = process.env.IRIS_DEMO_RECORDER || 'cap';
const cap = recorder === 'cap' && await import('./cap.mjs');
// Playback speed and quality of the exported take. Cap's zoom makes faster takes easy to follow.
const [speed, crf] = cap ? [cap.speed, cap.crf] : [0.75, 23];
let recording;
// Pointer and keyboard actions in the current take, in seconds since capture started. Cap zooms toward them.
let actions = [], epoch;
const mark = (x, y, detail = {}) => epoch && actions.push(wide
  ? { t: (Date.now() - epoch) / 1000, action: 'overview' }
  : { t: (Date.now() - epoch) / 1000, x, y, ...detail });
// Actions inside `overview` show the whole editor rather than zooming in.
let wide = false;
async function overview(action) {
  wide = true;
  mark();
  try { await action(); } finally { wide = false; }
}
// Keyboard work keeps the focus at the last pointer action.
const pointer = () => actions.findLast(a => a.action !== 'key' && a.action !== 'ui' && a.x !== undefined);
const focus = () => { const last = pointer(); if (last) mark(last.x, last.y, { action: 'key' }); };
// Overlays that demos show. Each passing check logs the screen boxes of those that are in view, which
// Cap's zoom keeps in frame. A check can name what else it shows with a script returning elements.
const overlays = ['.monaco-hover', '.suggest-widget', '.peekview-widget', '.quick-input-widget', '.action-widget',
  '.rename-box'];
const lines = (...texts) => `[...document.querySelectorAll('.view-line')].filter(line => ${JSON.stringify(texts)}
  .some(text => line.textContent.replaceAll('\\u00a0', ' ').includes(text)))`;
// The visible lines from the one containing `from` to the one containing `to`.
const region = (from, to) => `(() => {
  const text = line => line.textContent.replaceAll('\\u00a0', ' ');
  const lines = [...document.querySelectorAll('.view-line')]
    .sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);
  const start = lines.findIndex(line => text(line).includes(${JSON.stringify(from)}));
  const end = lines.findIndex((line, i) => i >= start && text(line).includes(${JSON.stringify(to)}));
  return start < 0 || end < 0 ? [] : lines.slice(start, end + 1).flatMap(line => [...line.querySelectorAll('span span')]);
})()`;
const highlights = `document.querySelectorAll('.cdr.wordHighlight, .cdr.wordHighlightStrong, .cdr.wordHighlightText')`;

async function expect(code, message, shows = '[]') {
  const boxes = evaluate(`new Promise(resolve => {
    const deadline = Date.now() + 12000;
    // Skip anything covered by something else, such as an editor behind the Settings dialog.
    const uncovered = (e, r) => {
      const hit = document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2);
      return hit && (e.contains(hit) || hit.closest('.monaco-editor') === e.closest('.monaco-editor'));
    };
    const overlays = () => [...document.querySelectorAll(${JSON.stringify(overlays.join(', '))}), ...${shows}]
      .filter(e => e.checkVisibility({ opacityProperty: true, visibilityProperty: true }))
      .map(e => [e, e.getBoundingClientRect()])
      .filter(([e, r]) => r.width > 0 && r.height > 0 && uncovered(e, r))
      .map(([, r]) => [r.left, r.top, r.right, r.bottom].map(v => Math.round(v * devicePixelRatio)));
    const check = () => {
      if (${code}) resolve(overlays());
      else if (Date.now() > deadline) resolve(false);
      else setTimeout(check, 100);
    }; check();
  })`);
  if (!boxes) throw new Error(message);
  // A check that names what it shows is framed on that alone.
  const last = shows === '[]' ? pointer() : undefined;
  mark(last?.x, last?.y, { action: 'ui', boxes });
  console.log(`PASS: ${message}`);
}

async function command(name) {
  press('F1');
  browser('fill', input, `>${name}`);
  await sleep(400);
  press('Enter');
  await sleep(400);
}

async function open(file, line = 1) {
  press('Escape');
  press('Control+p');
  browser('fill', input, `src/Website/${file}:${line}`);
  await sleep(800);
  press('Enter');
  await sleep(700);
}

async function prepare(file, line = 1) {
  copyFileSync(`${root}/src/Website/${file}`, `${tools}/iris-website/src/Website/${file}`);
  await open(file, line);
  await command('File: Revert File');
  await command('View: Close All Editors');
  await open(file, line);
  await move(100, 180, 100);
  press('Escape');
  await sleep(800);
}

// Resolve actual rendered text ranges, not fixed coordinates. This also works at 200%.
function tokenPoint(line, token, occurrence = 0) {
  return evaluate(`(() => {
    const normalize = s => s.replaceAll('\u00a0', ' ');
    const line = [...document.querySelectorAll('.view-line')]
      .find(e => normalize(e.textContent).includes(${JSON.stringify(line)}));
    if (!line) throw new Error('Line not visible: ' + ${JSON.stringify(line)});
    const text = normalize(line.textContent), token = ${JSON.stringify(token)};
    let start = -1;
    for (let i = 0; i <= ${occurrence}; i++) start = text.indexOf(token, start + 1);
    if (start < 0) throw new Error('Token not found: ' + token);
    const walker = document.createTreeWalker(line, NodeFilter.SHOW_TEXT);
    const range = document.createRange();
    let offset = 0, node;
    while (node = walker.nextNode()) {
      if (start >= offset && start < offset + node.length) {
        range.setStart(node, start - offset);
        range.setEnd(node, Math.min(node.length, start - offset + token.length));
        const r = range.getBoundingClientRect();
        if (r.x < 0 || r.right > innerWidth || r.y < 80 || r.bottom > innerHeight - 22)
          throw new Error('Token clipped: ' + token);
        return { x: (r.x + r.width / 2) * devicePixelRatio,
          y: (r.y + r.height / 2) * devicePixelRatio };
      }
      offset += node.length;
    }
  })()`);
}

async function move(x, y, duration = 650) {
  const location = run('xdotool', ['getmouselocation', '--shell']);
  const fromX = Number(location.match(/^X=(\d+)/m)[1]);
  const fromY = Number(location.match(/^Y=(\d+)/m)[1]);
  const steps = Math.max(2, Math.round(duration / 25));
  const start = Date.now();
  for (let i = 1; i <= steps; i++) {
    const eased = (1 - Math.cos(Math.PI * i / steps)) / 2;
    run('xdotool', ['mousemove', String(Math.round(fromX + (x - fromX) * eased)), String(Math.round(fromY + (y - fromY) * eased))]);
    await sleep(Math.max(0, start + duration * i / steps - Date.now()));
  }
}

// Hold each button press for a few frames. Cap polls the pointer every 16 ms and misses instant clicks.
async function press1(count = 1) {
  for (let i = 0; i < count; i++) {
    if (i) await sleep(70);
    run('xdotool', ['mousedown', '1']);
    await sleep(50);
    run('xdotool', ['mouseup', '1']);
  }
}

async function token(line, text, action = 'hover', occurrence = 0) {
  const { x, y } = tokenPoint(line, text, occurrence);
  await move(x, y);
  mark(x, y, { action });
  if (action === 'click') await press1();
  if (action === 'select') await press1(2);
  await sleep(300);
}

async function click(selector) {
  const { x, y } = evaluate(`(() => {
    const r = document.querySelector(${JSON.stringify(selector)}).getBoundingClientRect();
    return { x: (r.x + r.width / 2) * devicePixelRatio, y: (r.y + r.height / 2) * devicePixelRatio };
  })()`);
  await move(x, y);
  mark(x, y, { action: 'click' });
  await press1();
  await sleep(300);
}

// The pointer stays visible while typing, so move it aside first, into the nearest negative space
// of the editor: clear of text, outside the area around the caret where suggestion lists, quick
// fixes and hovers open, and preferably below and to the right of the caret.
async function aside() {
  const location = run('xdotool', ['getmouselocation', '--shell']);
  const [x, y] = ['X', 'Y'].map(axis => Number(location.match(new RegExp(`^${axis}=(\\d+)`, 'm'))[1]));
  const target = evaluate(`(() => {
    const [px, py] = [${x} / devicePixelRatio, ${y} / devicePixelRatio];
    const editor = [...document.querySelectorAll('.monaco-editor')].findLast(e => {
      const r = e.getBoundingClientRect();
      return px >= r.left && px <= r.right && py >= r.top && py <= r.bottom;
    });
    const bounds = editor.querySelector('.lines-content').closest('.monaco-scrollable-element').getBoundingClientRect();
    const lines = [...editor.querySelectorAll('.view-line')].map(line => {
      const text = [...line.querySelectorAll('span span')].filter(s => s.textContent.trim()).at(-1);
      const r = line.getBoundingClientRect();
      return { top: r.top, bottom: r.bottom, end: text ? text.getBoundingClientRect().right : -Infinity };
    });
    const clear = (x, y, gap) => lines.every(l => l.bottom < y - gap || l.top > y + gap || l.end + 24 < x);
    const popups = (x, y) => x > px - 40 && x < px + 520 && y > py - 80 && y < py + 260;
    const [x0, y0] = [px + 160, py + 200];
    const candidates = [];
    for (let y = bounds.top + 24; y <= bounds.bottom - 40; y += 12)
      for (let x = bounds.left + 24; x <= bounds.right - 40; x += 24)
        if (!popups(x, y)) candidates.push([x, y]);
    // Points above or left of the caret count as further away.
    const cost = ([x, y]) => Math.hypot(x - x0, y - y0) + (y < py + 24 ? 400 : 0) + (x < px ? 400 : 0);
    const [x, y] = [36, 12].map(gap => candidates.filter(([x, y]) => clear(x, y, gap)).sort((a, b) => cost(a) - cost(b))[0])
      .find(Boolean) ?? [Math.min(x0, bounds.right - 40), Math.min(y0, bounds.bottom - 40)];
    return { x: Math.round(x * devicePixelRatio), y: Math.round(y * devicePixelRatio) };
  })()`);
  await move(target.x, target.y, 300);
}

// Scroll with the wheel, as a person would, until the line containing `text` is in the upper part of
// the editor, or the editor reaches the top of the file.
async function scrollTo(text) {
  const visible = `[...document.querySelectorAll('.view-line')].some(line =>
    line.textContent.replaceAll('\\u00a0', ' ').includes(${JSON.stringify(text)})
    && line.getBoundingClientRect().top > 60
    && (line.getBoundingClientRect().top < innerHeight * 0.6
      || [...document.querySelectorAll('.line-numbers')].some(n => n.textContent.trim() === '1')))`;
  for (let i = 0; i < 60 && !evaluate(visible); i++) {
    run('xdotool', ['click', '--repeat', '6', '--delay', '15', '4']);
    await sleep(20);
  }
  if (!evaluate(visible)) throw new Error(`Could not scroll to ${text}`);
  await sleep(500);
}

async function type(text) {
  focus();
  await aside();
  run('xdotool', ['type', '--clearmodifiers', '--delay', '85', text]);
  await sleep(300);
}

async function capture(name, action) {
  const raw = `${tools}/${name}-raw.mp4`;
  const project = `${tools}/cap/${name}.cap`;
  if (cap) recording = cap.start(project);
  else recording = spawn('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y',
    '-f', 'x11grab', '-draw_mouse', '1', '-video_size', '1920x1080', '-framerate', '60',
    '-i', ':94', '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '18', '-pix_fmt', 'yuv420p', raw],
    { env, stdio: ['pipe', 'ignore', 'inherit'] });
  [actions, epoch] = [[], Date.now()];
  await sleep(800);
  await action();
  await sleep(2000);
  epoch = undefined;
  if (cap) {
    // Cap logs the cursor shape only when the pointer moves. An invisible move just before stopping,
    // too late to raise a hover, logs the shape the pointer rests in; cap.mjs dates it back.
    run('xdotool', ['mousemove_relative', '--', '1', '0']);
    await sleep(50);
    run('xdotool', ['mousemove_relative', '--', '-1', '0']);
    await sleep(50);
    cap.stop(recording);
    recording = undefined;
    writeFileSync(`${project}/iris-actions.json`, JSON.stringify(actions, null, 2));
    console.log(JSON.stringify(cap.render(project, actions, raw)));
  } else {
    recording.stdin.end('q\n');
    const [code] = await once(recording, 'exit');
    recording = undefined;
    if (code !== 0) throw new Error(`ffmpeg exited ${code}`);
  }
  run('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-an',
    // Slow the interactions, then hold the final frame for one extra second.
    '-vf', `setpts=(PTS-STARTPTS)/${speed},fps=60,tpad=stop_mode=clone:stop_duration=1`,
    '-c:v', 'libx264', '-preset', 'slow', '-crf', String(crf), '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', `${output}/${name}.mp4`]);
  writeFileSync(`${output}/${name}.txt`, browser('snapshot', '-i'));
  console.log(`Recorded ${name}`);
}

const player = 'Components/VideoPlayer.purs';
const demos = 'Landing/Demos.purs';
const factorial = 'Landing/Example/Factorial.purs';
const cases = {
  async 'inferred-types'() {
    const hover = text => `document.querySelector('.monaco-hover')?.innerText.includes(${JSON.stringify(text)})`;
    await prepare(player, 242);
    await capture('inferred-types', async () => {
      await token('active = props.playing', 'active');
      await expect(hover('Boolean'), 'Local active has inferred Boolean type');
      await sleep(1500);
      await token('active = props.playing', 'props');
      await expect(hover('setPlaying :: (Boolean -> Boolean) -> Effect Unit'), 'Component props have an inferred record type');
      await sleep(2000);
      await token('setTime { current, duration }', 'setTime');
      await expect(hover('{ current :: Number, duration :: Number } -> Effect Unit'), 'State setter has an inferred type');
      await sleep(1800);
    });
  },
  async rename() {
    // The `onTime` handler's `current` parameter shadows the component's `current` binding and is
    // passed on through a record pun. Renaming it must leave the outer binding and the label alone.
    const handler = '\\current duration -> setTime { current, duration }';
    const renamed = '\\seconds duration -> setTime { current: seconds, duration }';
    await prepare(player, 242);
    await capture('rename', async () => {
      await token(`onTime: ${handler}`, 'current', 'click');
      press('F2');
      await sleep(500);
      await aside();
      browser('fill', '.rename-box input', 'seconds');
      await sleep(900);
      press('Enter');
      await expect(`${lines(renamed)}.length === 1 && ${lines('current = shown == props.src')}.length === 1`,
        'Rename expands the pun and leaves the shadowed binding', lines(renamed, 'current = shown == props.src'));
      await sleep(1800);
    });
    press('Control+s');
    await sleep(500);
    const text = readFileSync(`${tools}/iris-website/src/Website/${player}`, 'utf8');
    const expected = readFileSync(`${root}/src/Website/${player}`, 'utf8').replace(handler, renamed);
    if (text !== expected) throw new Error('Rename changed more than the shadowing parameter and its pun');
    await prepare(player, 242);
  },
  async 'document-highlights'() {
    await prepare(player, 238);
    await capture('document-highlights', async () => {
      await token('active = props.playing', 'active', 'click');
      await expect(`document.querySelectorAll('.wordHighlightText').length >= 2`, 'Binding and its references are highlighted', highlights);
      await sleep(1600);
    });
  },
  async 'live-diagnostics'() {
    await prepare(demos, 163);
    await capture('live-diagnostics', async () => {
      await token('setPlaying (const true)', 'true', 'select');
      await type('"true"');
      await expect(`document.querySelectorAll('.squiggly-error').length > 0`, 'Unsaved String produces a type error');
      await token('setPlaying (const "true")', '"true"');
      await expect(`document.querySelector('.monaco-hover')?.innerText.includes('Boolean')`, 'Diagnostic explains the Boolean type mismatch');
      await sleep(1700);
      press('Escape');
      press('Control+z');
      await expect(`document.querySelectorAll('.squiggly-error').length === 0`, 'Undo clears the unsaved diagnostic');
    });
    await prepare(demos, 163);
  },
  async completion() {
    await prepare(demos, 163);
    await capture('completion', async () => {
      await token('setPlaying (const true)', 'setPlaying', 'select');
      await type('setPla');
      press('Control+space');
      await expect(`document.querySelector('.suggest-widget')?.innerText.includes('setPlaying')`, 'Completion includes the locally bound setter');
      await sleep(1700);
      press('Enter');
      await expect(`document.querySelector('.view-lines')?.textContent.includes('setPlaying (const true)')`, 'Completion inserts setPlaying');
    });
    await prepare(demos, 163);
  },
  async 'typed-hole-suggestions'() {
    await prepare(factorial);
    await capture('typed-hole-suggestions', async () => {
      await token('if value == 0 then accumulator', 'accumulator', 'select');
      await type('?result');
      await expect(`document.querySelectorAll('.squiggly-error, .squiggly-warning').length > 0`, 'Typed hole is diagnosed');
      await command('Quick Fix');
      await expect(`document.body.innerText.includes("Replace hole with 'accumulator'")`, 'Quick fix suggests accumulator for the typed hole');
      await sleep(1700);
      const label = evaluate(`JSON.stringify([...document.querySelectorAll('.monaco-list-row')].find(e => e.innerText.includes("Replace hole with 'accumulator'"))?.getAttribute('data-index'))`);
      await click(`.action-widget .monaco-list-row[data-index=${JSON.stringify(JSON.parse(label))}]`);
      await expect(`document.querySelector('.view-lines')?.textContent.includes('then accumulator')`, 'Typed hole replaced with accumulator');
    });
    await prepare(factorial);
  },
  async 'automatic-import'() {
    await prepare(demos, 160);
    const path = `${tools}/iris-website/src/Website/${demos}`;
    writeFileSync(path, readFileSync(path, 'utf8').replace('import Data.Maybe (fromMaybe)\n', ''));
    await command('File: Revert File');
    await open(demos, 159);
    await capture('automatic-import', async () => {
      await token('demo = fromMaybe inferredTypes', 'fromMaybe', 'select');
      await type('fromMa');
      press('Control+space');
      await expect(`document.querySelector('.suggest-widget')?.innerText.includes('fromMaybe')`, 'Completion finds unimported fromMaybe');
      await sleep(1600);
      press('Enter');
      await sleep(1100);
      await overview(() => scrollTo('import Data.Maybe (fromMaybe)'));
      await expect(`${lines('import Data.Maybe (fromMaybe)')}.length === 1`, 'Completion adds the Data.Maybe import',
        lines('import Data.Maybe (fromMaybe)'));
      await token('import Data.Maybe (fromMaybe)', 'fromMaybe');
    });
    await prepare(demos, 160);
  },
  async 'go-to-definition'() {
    await prepare('Landing/Index.purs', 54);
    await capture('go-to-definition', async () => {
      await token('[ siteNav { onInstall:', 'siteNav', 'click');
      await sleep(700);
      press('F12');
      await expect(`document.querySelector('[role="tab"][aria-selected="true"][data-resource-name="SiteNav.purs"]') !== null && document.querySelector('.view-lines')?.textContent.includes('siteNav ::')`, 'Definition navigation opens siteNav in another module');
    });
  },
  async 'find-references'() {
    await prepare('Components/ContentShell.purs');
    await capture('find-references', async () => {
      await token('contentShell = StyleX.props', 'contentShell', 'click');
      await sleep(700);
      press('Shift+F12');
      await expect(`document.querySelector('.peekview-widget')?.innerText.includes('Demos.purs')`, 'References include consumers in other website modules');
      await sleep(1000);
    });
    press('Escape');
  },
  async 'document-symbols'() {
    await prepare(player);
    await capture('document-symbols', async () => {
      press('Control+Shift+o');
      browser('fill', input, '@mediaButton');
      await expect(`document.querySelector('.quick-input-list')?.innerText.includes('mediaButton')`, 'Document symbols find mediaButton');
      await sleep(1700);
      press('Enter');
      await expect(`document.querySelector('.view-lines')?.textContent.includes('mediaButton :: String')`, 'Document-symbol selection reaches its declaration');
    });
  },
  async 'workspace-symbols'() {
    await prepare('Landing/Index.purs');
    await capture('workspace-symbols', async () => {
      press('Control+t');
      browser('fill', input, '#copyButton');
      await expect(`document.querySelector('.quick-input-list')?.innerText.includes('copyButton')`, 'Workspace symbols find copyButton');
      await sleep(1700);
      press('Enter');
      await expect(`document.querySelector('[role="tab"][aria-selected="true"][data-resource-name="CopyButton.purs"]') !== null`, 'Workspace-symbol selection opens CopyButton.purs');
    });
  },
  async 'semantic-highlighting'() {
    const path = `${tools}/profile/User/settings.json`;
    const settings = JSON.parse(readFileSync(path, 'utf8'));
    settings['editor.semanticHighlighting.enabled'] = false;
    writeFileSync(path, JSON.stringify(settings, null, 2));
    await prepare(player, 242);
    // The player's effect: binders, labels, qualifiers and a lambda, all of which semantic tokens recolour.
    const code = region('Hooks.useEffectOnce do', 'onVisible: setVisible');
    const colors = `${code}.map(e => [e.textContent, getComputedStyle(e).color, getComputedStyle(e).fontStyle])`;
    const before = evaluate(colors);
    if (!before.length) throw new Error('The player effect is not visible');
    await capture('semantic-highlighting', async () => {
      await sleep(1500);
      await overview(async () => {
        await command('Preferences: Open Settings (UI)');
        press('Control+a');
        browser('keyboard', 'inserttext', '@id:editor.semanticHighlighting.enabled');
        await expect(`document.querySelector('select[aria-label="editor.semanticHighlighting.enabled"]')?.value === 'false'`, 'Semantic highlighting starts disabled');
        await click('select[aria-label="editor.semanticHighlighting.enabled"]');
        await sleep(800);
        press('Home');
        press('Enter');
        await expect(`document.querySelector('select[aria-label="editor.semanticHighlighting.enabled"]')?.value === 'true'`, 'Semantic highlighting is enabled through Settings');
        await sleep(900);
        press('Escape');
        // The editor recolours as soon as the setting changes; zoom in once the dialog has closed.
        await sleep(700);
      });
      await expect(`JSON.stringify(${colors}) !== ${JSON.stringify(JSON.stringify(before))}`, 'Iris semantic tokens recolour the player effect', code);
      await sleep(2400);
    });
  },

};

mkdirSync(output, { recursive: true });
try {
  const display = evaluate('({width:innerWidth,height:innerHeight,scale:devicePixelRatio})');
  if (display.width * display.scale !== 1920 || display.height * display.scale !== 1080)
    throw new Error('VS Code must be fullscreen (F11) on the 1920×1080 desktop');
  console.log(`Native VS Code at ${display.scale * 100}% — 1920×1080`);
  const selected = process.argv.slice(2);
  if (!selected.length) throw new Error(`Choose a clip or all: ${Object.keys(cases).join(', ')}`);
  for (const name of selected.includes('all') ? Object.keys(cases) : selected) {
    if (!cases[name]) throw new Error(`Unknown demo: ${name}`);
    await cases[name]();
  }
} finally {
  if (recording && cap) cap.stop(recording);
  else if (recording) {
    recording.stdin.end('q\n');
    await once(recording, 'exit');
  }
  // Disconnect from the external Electron browser without closing VS Code.
  browser('close');
}
