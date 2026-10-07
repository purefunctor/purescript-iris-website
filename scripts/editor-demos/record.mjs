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
const press = key => browser('press', key);
const input = '.quick-input-widget input';
let recording;

async function expect(code, message) {
  const result = evaluate(`new Promise(resolve => {
    const deadline = Date.now() + 12000;
    const check = () => {
      if (${code}) resolve(true);
      else if (Date.now() > deadline) resolve(false);
      else setTimeout(check, 100);
    }; check();
  })`);
  if (!result) throw new Error(message);
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

async function token(line, text, action = 'hover', occurrence = 0) {
  const { x, y } = tokenPoint(line, text, occurrence);
  await move(x, y);
  if (action === 'click') run('xdotool', ['click', '1']);
  if (action === 'select') run('xdotool', ['click', '--repeat', '2', '--delay', '90', '1']);
  await sleep(300);
}

async function click(selector) {
  const { x, y } = evaluate(`(() => {
    const r = document.querySelector(${JSON.stringify(selector)}).getBoundingClientRect();
    return { x: (r.x + r.width / 2) * devicePixelRatio, y: (r.y + r.height / 2) * devicePixelRatio };
  })()`);
  await move(x, y);
  run('xdotool', ['click', '1']);
  await sleep(300);
}

async function type(text) {
  run('xdotool', ['type', '--clearmodifiers', '--delay', '85', text]);
  await sleep(300);
}

async function capture(name, action) {
  const raw = `${tools}/${name}-raw.mp4`;
  recording = spawn('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y',
    '-f', 'x11grab', '-draw_mouse', '1', '-video_size', '1920x1080', '-framerate', '60',
    '-i', ':94', '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '18', '-pix_fmt', 'yuv420p', raw],
    { env, stdio: ['pipe', 'ignore', 'inherit'] });
  await sleep(800);
  await action();
  await sleep(2000);
  recording.stdin.end('q\n');
  const [code] = await once(recording, 'exit');
  recording = undefined;
  if (code !== 0) throw new Error(`ffmpeg exited ${code}`);
  run('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-an',
    // Slow the interactions to 75% speed, then hold the final frame for one extra second.
    '-vf', 'setpts=(PTS-STARTPTS)/0.75,fps=60,tpad=stop_mode=clone:stop_duration=1',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '23', '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', `${output}/${name}.mp4`]);
  writeFileSync(`${output}/${name}.txt`, browser('snapshot', '-i'));
  console.log(`Recorded ${name}`);
}

const player = 'Components/VideoPlayer.purs';
const demos = 'Landing/Demos.purs';
const factorial = 'Landing/Example/Factorial.purs';
const cases = {
  async 'inferred-types'() {
    await prepare(player, 236);
    await capture('inferred-types', async () => {
      await token('active = props.playing', 'active');
      await expect(`document.querySelector('.monaco-hover')?.innerText.includes('Boolean')`, 'Local active has inferred Boolean type');
      await sleep(1800);
      await token('toggle = props.setPlaying', 'toggle');
      await expect(`document.querySelector('.monaco-hover')?.innerText.includes('Effect Unit')`, 'Local toggle has inferred Effect Unit type');
      await sleep(1800);
    });
  },
  async rename() {
    await prepare(player, 239);
    await capture('rename', async () => {
      await token('    controls =', 'controls', 'click');
      press('F2');
      await sleep(500);
      browser('fill', '.rename-box input', 'controlProps');
      await sleep(900);
      press('Enter');
      await expect(`document.querySelector('.view-lines')?.textContent.includes('controlProps') && document.querySelector('.view-lines')?.textContent.includes('styles.controls')`, 'Local rename leaves styles.controls unchanged');
      await move(1650, 820);
    });
    press('Control+s');
    await sleep(500);
    const text = readFileSync(`${tools}/iris-website/src/Website/${player}`, 'utf8');
    if (!text.includes('DOM.div controlProps') || !text.includes('[ styles.controls')) throw new Error('Rename missed a reference or changed a field');
    await prepare(player, 239);
  },
  async 'document-highlights'() {
    await prepare(player, 236);
    await capture('document-highlights', async () => {
      await token('active = props.playing', 'active', 'click');
      await expect(`document.querySelectorAll('.wordHighlightText').length >= 2`, 'Binding and its references are highlighted');
      await move(1640, 820);
      await sleep(1600);
    });
  },
  async 'live-diagnostics'() {
    await prepare(demos, 181);
    await capture('live-diagnostics', async () => {
      await token('setPlaying (const true)', 'true', 'select');
      await type('"true"');
      await expect(`document.querySelectorAll('.squiggly-error').length > 0`, 'Unsaved String produces a type error');
      await token('setPlaying (const "true")', '"true"');
      await expect(`document.querySelector('.monaco-hover')?.innerText.includes('Boolean')`, 'Diagnostic explains the Boolean type mismatch');
      await sleep(1700);
      press('Escape');
      press('Control+z');
      await move(1640, 820);
      await expect(`document.querySelectorAll('.squiggly-error').length === 0`, 'Undo clears the unsaved diagnostic');
    });
    await prepare(demos, 181);
  },
  async completion() {
    await prepare(demos, 181);
    await capture('completion', async () => {
      await token('setPlaying (const true)', 'setPlaying', 'select');
      await type('setPla');
      press('Control+space');
      await expect(`document.querySelector('.suggest-widget')?.innerText.includes('setPlaying')`, 'Completion includes the locally bound setter');
      await sleep(1700);
      press('Enter');
      await expect(`document.querySelector('.view-lines')?.textContent.includes('setPlaying (const true)')`, 'Completion inserts setPlaying');
      await move(1640, 820);
    });
    await prepare(demos, 181);
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
    await prepare(demos, 178);
    const path = `${tools}/iris-website/src/Website/${demos}`;
    writeFileSync(path, readFileSync(path, 'utf8').replace('import Data.Maybe (fromMaybe)\n', ''));
    await command('File: Revert File');
    await open(demos, 177);
    await capture('automatic-import', async () => {
      await token('demo = fromMaybe inferredTypes', 'fromMaybe', 'select');
      await type('fromMa');
      press('Control+space');
      await expect(`document.querySelector('.suggest-widget')?.innerText.includes('fromMaybe')`, 'Completion finds unimported fromMaybe');
      await sleep(1600);
      press('Enter');
      await sleep(1100);
      press('Control+Home');
      await expect(`document.querySelector('.view-lines')?.textContent.includes('import Data.Maybe (fromMaybe)')`, 'Completion adds the Data.Maybe import');
      await token('import Data.Maybe (fromMaybe)', 'fromMaybe');
    });
    await prepare(demos, 178);
  },
  async 'go-to-definition'() {
    await prepare('Landing/Index.purs', 50);
    await capture('go-to-definition', async () => {
      await token('[ siteNav { onInstall:', 'siteNav', 'click');
      await sleep(700);
      press('F12');
      await expect(`document.querySelector('[role="tab"][aria-selected="true"][data-resource-name="SiteNav.purs"]') !== null && document.querySelector('.view-lines')?.textContent.includes('siteNav ::')`, 'Definition navigation opens siteNav in another module');
      await move(1650, 820);
    });
  },
  async 'find-references'() {
    await prepare('Components/ContentShell.purs');
    await capture('find-references', async () => {
      await token('contentShell = StyleX.props', 'contentShell', 'click');
      await sleep(700);
      press('Shift+F12');
      await expect(`document.querySelector('.peekview-widget')?.innerText.includes('Demos.purs')`, 'References include consumers in other website modules');
      await move(1500, 800);
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
      await move(1650, 820);
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
      await move(1650, 820);
    });
  },
  async 'semantic-highlighting'() {
    const path = `${tools}/profile/User/settings.json`;
    const settings = JSON.parse(readFileSync(path, 'utf8'));
    settings['editor.semanticHighlighting.enabled'] = false;
    writeFileSync(path, JSON.stringify(settings, null, 2));
    await prepare('Components/CopyButton.purs', 22);
    const colors = `(() => {
      const line = [...document.querySelectorAll('.view-line')].find(e => e.textContent.replaceAll('\u00a0', ' ').includes('copyButton { label, size, text }'));
      return [...line.querySelectorAll('span span')].map(e => [e.textContent, getComputedStyle(e).color]);
    })()`;
    const before = evaluate(colors);
    await capture('semantic-highlighting', async () => {
      await sleep(1500);
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
      await expect(`JSON.stringify(${colors}) !== ${JSON.stringify(JSON.stringify(before))}`, 'Iris semantic tokens change the parameter colours');
      await move(1450, 20);
      await sleep(1600);
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
  if (recording) {
    recording.stdin.end('q\n');
    await once(recording, 'exit');
  }
  // Disconnect from the external Electron browser without closing VS Code.
  browser('close');
}
