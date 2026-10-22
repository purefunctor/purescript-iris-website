// Records the playground trailer's two takes in Helium on the display that playground-launch.sh
// starts: `playground`, a continuous take of the playground at iris-lang.com, and `playground-share`,
// an incognito window that opens the take's share link. See playground-screenplay.md.
//   node scripts/editor-demos/playground.mjs [--site https://iris-lang.com] [--share-only]
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { inflateRawSync } from 'node:zlib';
import { env, height, lines, output, recorder, run, sleep, suggestion, tools, width } from './recorder.mjs';

// --share-only records the incognito take again from the last take's link, which Share copies.
const { values: options } = parseArgs({ options: {
  site: { type: 'string', default: 'https://iris-lang.com' },
  'share-only': { type: 'boolean', default: false },
} });
const page = `${options.site}/playground/`;
// Helium's portable build, which playground-setup.sh unpacks; playground-launch.sh runs the same one.
const browserPath = process.env.IRIS_DEMO_BROWSER || `${tools}/helium/helium`;

// Keyboard work in the editor is framed on its text cursor.
const caret = `(() => {
  const r = document.querySelector('.monaco-editor.focused .cursor')?.getBoundingClientRect();
  return r && r.height > 0 ? { x: Math.round(r.x * devicePixelRatio), y: Math.round((r.y + r.height / 2) * devicePixelRatio) } : null;
})()`;
// Where the page starts on screen, in device pixels: 0 while fullscreen, below the toolbar in the
// incognito window.
let top = 0;
const {
  browser, evaluate, actions, beats, now, mark, overview, beat, focus, expect,
  move, clickAt, centre, clickOn, tokenPoint, aside: moveAside, smoothScroll: scrollTo, capture,
} = recorder({
  session: 'irispg',
  cdp: 9224,
  // Overlays that the take shows.
  overlays: ['.suggest-widget', '.monaco-hover'],
  caret,
  offset: () => top,
  // The page renders at 100%, so the camera zooms in further than on the editor take, and holds a
  // framing across longer pauses, panning between places instead of zooming out and back in. It
  // zooms as little as 1.1×, which frames Run with a program rendered in the middle of the output.
  planner: { amount: 1.8, hold: 4, bridge: 6, minimum: 1.1 },
});
// Keys go to Helium through X rather than CDP, because the incognito window and the program's
// sandboxed frame are reached only through X.
const key = (...keys) => (focus(), run('xdotool', ['key', '--clearmodifiers', ...keys]));
// A new line in the editor. Typing opens suggestions, which Enter would accept, so Escape closes them first.
const newline = () => key('Escape', 'Return');
// The pointer moves aside from the caret, where suggestions open.
const aside = () => moveAside(evaluate(caret) ?? undefined);

const button = label => `[...document.querySelectorAll('button')].find(b => (b.getAttribute('aria-label') ?? b.textContent.trim()) === ${JSON.stringify(label)})`;
// A file's tab, whose label may end in its error count.
const tab = name => `[...document.querySelectorAll('button')].filter(b => b.textContent.trim().replace(/\\d+$/, '') === ${JSON.stringify(name)}).at(-1)`;

const token = (line, text, options) => clickAt(tokenPoint(line, text, options), options);

// Whether a line that contains `text` is in view.
const shown = text => `${lines(text)}.length > 0`;
const errors = `document.querySelectorAll('.monaco-editor .squiggly-error').length`;
const log = `(document.querySelector('[role=log]')?.innerText ?? '')`;
const ready = `!!${button('Run')} && !${button('Run')}.disabled`;

// One scroll, as scrollTo makes it. The camera first moves to the code where the line will land, so
// the scroll plays in view; `arrive: false` skips that for a scroll that continues work already in frame.
async function smoothScroll(line, at = 0.45, duration = 700, { arrive = true } = {}) {
  if (arrive) {
    const area = evaluate(`(() => {
      const r = [...document.querySelectorAll('.monaco-editor .monaco-scrollable-element.editor-scrollable')]
        .find(e => e.checkVisibility()).getBoundingClientRect();
      const y = r.top + ${at} * r.height;
      return [r.left, y - 200, Math.min(r.right, r.left + 900), y + 200].map(v => Math.round(v * devicePixelRatio));
    })()`);
    mark(undefined, undefined, { action: 'ui', boxes: [area] });
    await sleep(900);
  }
  await scrollTo(line, at, duration);
}

// Typing is framed from the caret where it starts to where it ends, so the camera centres on the
// typed text rather than leaving the caret at the frame's edge.
async function type(text, delay = 70) {
  focus();
  run('xdotool', ['type', '--clearmodifiers', '--delay', String(delay), text]);
  focus();
  await sleep(300);
}

// Picks the completion row that mentions every text, from the list that ctrl+space opens.
async function complete(...texts) {
  key('ctrl+space');
  await expect(`document.querySelector('.suggest-widget .monaco-list-row.focused') !== null`, 'Completion opens');
  for (let i = 0; i < 8 && !evaluate(suggestion(...texts)); i++) {
    await sleep(350);
    run('xdotool', ['key', 'Down']);
  }
  await expect(suggestion(...texts), `Completion offers ${texts.join(' from ')}`);
  await sleep(900);
  key('Return');
  await sleep(400);
}

// Elements inside the program's sandboxed frame are reached through the accessibility tree, which
// inlines the frame, and placed by the frame's own position.
const frameSnapshot = () => browser('snapshot', '-i');
function frameElement(role, name) {
  const ref = frameSnapshot().split('\n').find(l => l.includes(`${role} "${name}"`))?.match(/ref=(e\d+)/)?.[1];
  if (!ref) throw new Error(`The program shows no ${role} "${name}"`);
  const box = Object.fromEntries(browser('get', 'box', `@${ref}`).split('\n').map(l => l.split(':').map(s => s.trim()))
    .map(([k, v]) => [k, Number(v)]));
  const frame = evaluate(`(() => { const r = document.querySelector('iframe[title="Program view"]').getBoundingClientRect(); return { x: r.x, y: r.y, scale: devicePixelRatio } })()`);
  return { x: Math.round((frame.x + box.x + box.width / 2) * frame.scale), y: Math.round((frame.y + box.y + box.height / 2) * frame.scale) + top };
}
// The Run click whose program has not rendered yet; see clickRun.
let running;
// Waits for an element of the program, and frames the program around it: the frame's width, from a
// heading's height above the element to a few rows below it, where a program's content continues.
async function program(role, name, message) {
  const deadline = Date.now() + 15000;
  while (!frameSnapshot().includes(`${role} "${name}"`)) {
    if (Date.now() > deadline) throw new Error(message);
    await sleep(250);
  }
  const at = frameElement(role, name);
  const app = evaluate(`(() => {
    const r = document.querySelector('iframe[title="Program view"]').getBoundingClientRect();
    const [left, upper, right, lower] = [r.left, r.top, r.right, r.bottom].map(v => Math.round(v * devicePixelRatio));
    return [left, Math.max(upper + ${top}, ${at.y - 100}), right, Math.min(lower + ${top}, ${at.y + 220})];
  })()`);
  if (running) running.boxes = [app];
  running = undefined;
  mark(undefined, undefined, { action: 'ui', boxes: [app] });
  console.log(`PASS: ${message}`);
}
const clickProgram = (role, name, options) => clickAt(frameElement(role, name), options);

// A program renders wherever its own layout puts it, which is unknown until it runs. Once it has,
// `program` adds its box to the Run click, and the zoom, which is planned after the take, frames
// Run and the program together from the click, zooming in only as far as both fit, so the camera
// does not pan to the program as it renders.
async function clickRun() {
  await clickOn(button('Run'));
  running = actions.findLast(a => a.action === 'click');
}

async function runProject(expectation) {
  await expect(ready, 'The project is ready to run', { timeout: 60000 });
  await clickRun();
  await expectation();
  running = undefined;
}

// The edits the take makes, which the share link must carry exactly.
const { TEMPLATES } = await import('../../playground/client/templates.js');
const template = id => TEMPLATES.find(t => t.id === id).files[0].text;

// Stage the main window: the playground as a new visitor sees it, with the packages that the take
// activates already in the browser's cache, so templates load at once. The incognito window
// downloads its own.
async function stage() {
  browser('open', page);
  await expect(ready, 'The playground loads', { timeout: 120000 });
  // Visit the take's end state once, so that its packages are cached.
  const index = JSON.parse(readFileSync(new URL('../../playground/packages/index.json', import.meta.url), 'utf8'));
  const core = Object.keys(index.packages).filter(n => ['purescript', 'purescript-contrib'].includes(index.packages[n].owner));
  evaluate(`(async () => {
    localStorage.clear();
    localStorage.setItem('iris-playground-project', JSON.stringify({ version: 1, files: [{ path: 'src/Main.purs', text: 'module Main where' }],
      packages: ${JSON.stringify([...core, 'react-basic', 'react-basic-dom', 'react-basic-hooks', 'halogen', 'heckin'])} }));
    return true;
  })()`);
  browser('reload');
  await expect(ready, 'The take\'s packages are cached', { timeout: 180000 });
  evaluate(`(() => { localStorage.clear(); return true })()`);
  browser('reload');
  await expect(`${ready} && ${shown('log (greet "Iris")')}`, 'The playground opens the Console template', { timeout: 60000 });
  await move(1500 * width / 1920, 700 * height / 1080, 300);
  await sleep(1500);
}

let shared;

async function playground() {
  await capture('playground', async () => {
    await beat('run');
    await overview(async () => {
      await sleep(1200);
      await clickOn(button('Run'));
      await expect(`${log}.includes('Hello, Iris!') && ${log}.includes('The sum of 1 to 10 is 55')`, 'Run prints the greeting and the sum');
      await sleep(1800);
    });

    await beat('edit');
    await token('log (greet "Iris")', 'Iris', { count: 2 });
    await aside();
    await type('PureScript');
    key('Escape');
    await sleep(500);
    await runProject(() => expect(`${log}.includes('Hello, PureScript!')`, 'Running again prints the new greeting'));
    await sleep(1800);

    await beat('templates');
    await clickOn(button('React counterA React component styled with StyleX'));
    await expect(`${shown('import React.Basic.Hooks')}`, 'The React counter template opens');
    await sleep(800);
    await runProject(() => program('button', '+', 'The counter renders'));
    for (const name of ['+', '+', '+', '−']) {
      await clickProgram('button', name, { duration: 350 });
      await sleep(250);
    }
    await sleep(1000);

    await beat('completion');
    const counter = template('react-counter').split('\n');
    await smoothScroll(counter.findIndex(l => l.includes('onClick: handler_ (setCount change)')) + 1, 0.55);
    const before = tokenPoint('onClick: handler_ (setCount change)', '(setCount');
    await clickAt({ x: before.x - 9, y: before.y });
    key('shift+End');
    await aside();
    await type('do');
    newline();
    await type('    log');
    await complete('log', 'Effect.Console');
    await type(' ("count: " <> show count)', 55);
    newline();
    await type('setCount change');
    key('Escape');
    await expect(`${errors} === 0 && ${shown('log ("count: " <> show count)')}`, 'The handler logs the count, and log is imported');
    await sleep(1200);

    await beat('console');
    await runProject(() => program('button', '+', 'The counter renders again'));
    for (let i = 0; i < 5; i++) {
      await clickProgram('button', '+', { duration: 300 });
      await sleep(200);
    }
    // Framed on the console and the counter's keys, not the whole view, which is too tall to zoom on.
    await expect(`${log}.includes('count: 4')`, 'The console shows each count', { shows: `[document.querySelector('#playground-console').parentElement]` });
    await sleep(800);
    // The console's top edge pushes it up over the program, then down again, and its bar collapses it.
    const handle = centre(`document.querySelector('[aria-label="Resize console"]')`);
    await move(handle.x, handle.y, 500);
    mark(handle.x, handle.y, { action: 'click' });
    run('xdotool', ['mousedown', '1']);
    await move(handle.x, handle.y - 330, 900);
    await sleep(700);
    await move(handle.x, handle.y + 60, 900);
    run('xdotool', ['mouseup', '1']);
    await sleep(600);
    await clickOn(`document.querySelector('[aria-controls="playground-console"][aria-expanded]')`);
    await expect(`document.querySelector('[aria-controls="playground-console"][aria-expanded]').getAttribute('aria-expanded') === 'false'`, 'The console collapses to its bar');
    await sleep(900);
    await clickOn(`document.querySelector('[aria-controls="playground-console"][aria-expanded]')`);
    await expect(`document.querySelector('[aria-controls="playground-console"][aria-expanded]').getAttribute('aria-expanded') === 'true'`, 'The console comes back up');
    await sleep(1000);

    await beat('todos');
    await clickOn(button('React todosA React todo list styled with StyleX'));
    await expect(`${shown('mkTodos')} || ${shown('import React.Basic.DOM.SVG')}`, 'The React todos template opens');
    await sleep(600);
    await runProject(() => program('textbox', 'What needs doing?', 'The todo list renders'));
    await clickProgram('textbox', 'What needs doing?');
    await type('share the playground', 60);
    run('xdotool', ['key', 'Return']);
    await program('checkbox', 'share the playground', 'A todo is added as typed');
    await sleep(600);
    await clickProgram('checkbox', 'Write some PureScript');
    await sleep(1000);

    await beat('packages');
    await clickOn(`[...document.querySelectorAll('[role=tab]')].find(t => t.textContent.startsWith('Packages'))`);
    await clickOn(`[...document.querySelectorAll('button')].find(b => b.textContent.startsWith('All '))`);
    await clickOn(`document.querySelector('input[aria-label="Search packages"]')`);
    await type('heckin', 90);
    const heckin = `document.querySelector('[role=switch][aria-label="heckin"]')`;
    await expect(`${heckin} !== null`, 'The package set offers heckin', { shows: `[document.querySelector('input[aria-label="Search packages"]'), ${heckin}.closest('li')]` });
    await sleep(500);
    await clickOn(heckin);
    await expect(`${heckin}.getAttribute('aria-checked') === 'true' && !${heckin}.disabled`, 'heckin is activated and the server has loaded it', { timeout: 60000 });
    await sleep(900);

    await beat('package-import');
    const todos = template('react-todos').split('\n');
    await smoothScroll(todos.findIndex(l => l.includes('{ key: next, text, done: false }')) + 1, 0.4);
    await token('{ key: next, text, done: false }', 'text', { end: true });
    await aside();
    await type(': toTi');
    await complete('toTitleCase', 'Data.String.Casing');
    await type(' text');
    key('Escape');
    await expect(`${errors} === 0 && ${shown('text: toTitleCase text')}`, 'toTitleCase is imported from heckin');
    await sleep(600);
    await runProject(() => program('textbox', 'What needs doing?', 'The todo list renders again'));
    await clickProgram('textbox', 'What needs doing?');
    await type('share the playground', 60);
    run('xdotool', ['key', 'Return']);
    await program('checkbox', 'Share The Playground', 'The new todo is title-cased');
    await sleep(1300);

    await beat('stylex');
    await smoothScroll(todos.findIndex(l => l.includes('title: { fontSize: 16')) + 1, 0.4);
    await token('title: { fontSize: 16, fontWeight: 600', '16', { count: 2 });
    await aside();
    await type('32');
    await token('title: { fontSize: 32, fontWeight: 600', '600', { count: 2 });
    await type('800, color: colors.accent', 60);
    key('Escape');
    await expect(`${errors} === 0 && ${shown('fontWeight: 800, color: colors.accent')}`, 'The title takes the accent color');
    await runProject(() => program('heading', 'React todos', 'The restyled list renders'));
    await sleep(1800);

    await beat('files');
    await clickOn(button('New file'));
    await expect(`${shown('module Module1 where')}`, 'A new module opens');
    await clickOn(button('Rename src/Module1.purs'));
    await sleep(300);
    key('ctrl+a');
    await type('src/Styles.purs', 60);
    key('Return');
    await expect(`${shown('module Styles where')}`, 'Renaming the file renames its module');
    await token('import Prelude', 'Prelude', { count: 2 });
    await aside();
    await type('Iris.StyleX as StyleX');
    key('Escape');
    // The editor's tab is the last button with the file's name; the file list's comes first.
    await clickOn(tab('Main.purs'));
    await expect(`${shown('module Main where')} || ${shown('mkTodos')} || ${shown('styles = StyleX.create')}`, 'Main.purs is back');
    // Select the colors and styles, from their comment down to styleProps, and cut them.
    const first = todos.findIndex(l => l.startsWith('-- The program runs')) + 1;
    const last = todos.findIndex(l => l.startsWith('styleProps = StyleX.recordProps styles')) + 1;
    await smoothScroll(first, 0.2);
    // The caret goes on the comment itself; the gutter beside it does not move the caret.
    await token('-- The program runs', 'The');
    key('Home');
    await expect(`document.querySelector('.monaco-editor.focused .current-line') !== null && ${lines('-- The program runs')}.some(line => Math.abs(line.getBoundingClientRect().top - document.querySelector('.monaco-editor.focused .cursor').getBoundingClientRect().top) < 4)`, 'The caret is on the colors comment');
    await smoothScroll(last + 1, 0.7, 1100, { arrive: false });
    await clickAt(tokenPoint('styleProps = StyleX.recordProps styles', 'styles', { occurrence: 0, end: true }), { shift: true });
    key('shift+Down');
    await sleep(700);
    key('ctrl+x');
    await sleep(600);
    await clickOn(tab('Styles.purs'));
    await expect(`${shown('module Styles where')}`, 'Styles.purs is back');
    // A tab does not focus the editor; a click below the last line puts the caret on it.
    await clickAt(evaluate(`(() => {
      const r = [...document.querySelectorAll('.monaco-editor .monaco-scrollable-element.editor-scrollable')].find(e => e.checkVisibility()).getBoundingClientRect();
      return { x: Math.round((r.left + 240) * devicePixelRatio), y: Math.round((r.top + r.height * 0.4) * devicePixelRatio) };
    })()`));
    key('ctrl+End');
    key('ctrl+v');
    await sleep(800);
    await expect(`${shown('styleProps = StyleX.recordProps styles')}`, 'The styles move into Styles.purs');
    await sleep(900);
    await clickOn(tab('Main.purs'));
    await smoothScroll(todos.findIndex(l => l === 'import Iris.StyleX as StyleX') + 1, 0.4);
    await token('import Iris.StyleX as StyleX', 'StyleX', { occurrence: 1, end: true });
    key('End');
    newline();
    await aside();
    await type('import Styles (styleProps, styles)', 55);
    key('Escape');
    await expect(`${errors} === 0`, 'Main imports its styles from Styles', { timeout: 20000 });
    await runProject(() => program('heading', 'React todos', 'The two-module project renders'));
    await sleep(1500);

    await beat('share');
    await clickOn(button('Share'));
    await expect(`!!${button('Copied')}`, 'Share copies the link');
    shared = evaluate('location.href');
    // The whole playground shows before the trailer moves it aside for the incognito window.
    await overview(() => sleep(1500));
  });

  // The share link must carry the project that the take wrote.
  const project = JSON.parse(inflateRawSync(Buffer.from(shared.split('#project=')[1], 'base64url')).toString());
  const file = path => project.files.find(f => f.path === path)?.text.replace(/\n+$/, '');
  const main = file('src/Main.purs'), styles = file('src/Styles.purs');
  if (!project.packages.includes('heckin')) throw new Error('The share link does not activate heckin');
  for (const [text, where] of [['import Styles (styleProps, styles)', main], ['import Data.String.Casing (toTitleCase)', main],
    ['text: toTitleCase text', main], ['module Styles where\n\nimport Iris.StyleX as StyleX', styles],
    ['fontSize: 32, fontWeight: 800, color: colors.accent', styles]])
    if (!where?.includes(text)) throw new Error(`The shared project lacks ${text}`);
  if (main.includes('StyleX.create')) throw new Error('Main.purs still defines the styles');
  writeFileSync(`${output}/playground.link`, shared);
  console.log(`PASS: The share link (${shared.length} characters) carries both modules and heckin`);
}

// The incognito window starts with no project and no cached packages.
async function share() {
  spawn(browserPath, [`--user-data-dir=${tools}/playground-profile`, '--incognito', '--new-window', 'about:blank'],
    { env, detached: true, stdio: 'ignore' }).unref();
  await sleep(3000);
  const window = run('xdotool', ['getactivewindow']);
  if (!run('xdotool', ['getwindowname', window]).startsWith('about:blank')) throw new Error('The incognito window did not open');
  // It opens fullscreen like the main window; F11 brings back its tabs and address bar.
  run('xdotool', ['key', 'F11']);
  await sleep(1500);
  run('xdotool', ['windowmove', window, '0', '0', 'windowsize', window, String(width), String(height)]);
  await sleep(500);
  await move(width * 0.55, height * 0.5, 200);
  // The agent's session follows the incognito tab from here; its page starts below the toolbar,
  // and the address bar's middle sits 19 pixels above the page.
  const incognito = browser('tab', 'list').split('\n').find(l => l.includes('about:blank'))?.match(/\[(t\d+)\]/)?.[1];
  if (!incognito) throw new Error('The agent cannot see the incognito tab');
  browser('tab', incognito);
  top = evaluate('Math.round((outerHeight - innerHeight) * devicePixelRatio)');
  const bar = { x: Math.round(width * 0.2), y: top - 19 };
  await capture('playground-share', async () => {
    await sleep(600);
    await beat('open-link');
    // The camera zooms in on the address bar before the paste, so the link reads as it lands.
    await clickAt(bar, { duration: 700 });
    await sleep(500);
    run('xdotool', ['key', 'ctrl+v']);
    mark(bar.x, bar.y, { action: 'ui', boxes: [[0, top - 40, Math.round(width * 0.62), top]] });
    await sleep(1500);
    // The page loads under the whole window.
    await overview(async () => {
      // The trailer hurries through the download from here, after the paste has read.
      beats.push({ slug: 'loading', t: now() });
      run('xdotool', ['key', 'Return']);
      await expect(`location.pathname === '/playground/'`, 'The incognito window opens the link');
      await expect(ready, 'The shared project loads, with its packages', { timeout: 120000 });
      // The trailer hurries through the download up to here.
      beats.push({ slug: 'shared-loaded', t: now() });
      await sleep(800);
    });
    await clickOn(tab('Styles.purs'));
    await sleep(1500);
    await clickOn(tab('Main.purs'));
    await sleep(600);
    await clickRun();
    await program('heading', 'React todos', 'The shared project runs');
    await clickProgram('textbox', 'What needs doing?');
    run('xdotool', ['type', '--delay', '60', 'it works everywhere']);
    run('xdotool', ['key', 'Return']);
    await program('checkbox', 'It Works Everywhere', 'The shared project title-cases todos too');
    await sleep(1500);
  });
  top = 0;
  run('xdotool', ['key', 'ctrl+shift+w']);
}

try {
  const display = evaluate('({ width: innerWidth, height: innerHeight, scale: devicePixelRatio })');
  if (display.scale !== 1 || Math.abs(display.width - width) > 1 || Math.abs(display.height - height) > 1)
    throw new Error(`Helium must be fullscreen at 100% on the ${width}×${height} display; start playground-launch.sh`);
  if (options['share-only']) {
    browser('open', readFileSync(`${output}/playground.link`, 'utf8'));
    await expect(ready, 'The last take\'s link opens', { timeout: 120000 });
    await clickOn(button('Share'));
    await expect(`!!${button('Copied')}`, 'Share copies the link again');
  } else {
    await stage();
    await playground();
  }
  await share();
} finally {
  browser('close');
}
