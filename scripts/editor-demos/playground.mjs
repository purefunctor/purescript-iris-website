import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { inflateRawSync } from 'node:zlib';
import { env, height, lines, output, recorder, run, sleep, suggestion, tools, width } from './recorder.mjs';

const { values: options } = parseArgs({ options: {
  site: { type: 'string', default: 'https://iris-lang.com' },
  'share-only': { type: 'boolean', default: false },
} });
const page = `${options.site}/playground/`;
const browserPath = process.env.IRIS_DEMO_BROWSER || `${tools}/helium/helium`;

const caret = `(() => {
  const r = document.querySelector('.monaco-editor.focused .cursor')?.getBoundingClientRect();
  return r && r.height > 0 ? { x: Math.round(r.x * devicePixelRatio), y: Math.round((r.y + r.height / 2) * devicePixelRatio) } : null;
})()`;
let pageTop = 0;
const {
  browser, evaluate, actions, beats, now, mark, overview, beat, focus, expect,
  move, clickAt, centre, clickOn, tokenPoint, aside: moveAside, smoothScroll: scrollTo, capture,
} = recorder({
  session: 'irispg',
  cdp: 9224,
  overlays: ['.suggest-widget', '.monaco-hover'],
  caret,
  offset: () => pageTop,
  planner: { amount: 1.8, hold: 4, bridge: 6, minimum: 1.1 },
});
const key = (...keys) => (focus(), run('xdotool', ['key', '--clearmodifiers', ...keys]));
const closeSuggestions = 'Escape';
const newline = () => key(closeSuggestions, 'Return');
const aside = () => moveAside(evaluate(caret) ?? undefined);

const button = label => `[...document.querySelectorAll('button')].find(b => (b.getAttribute('aria-label') ?? b.textContent.trim()) === ${JSON.stringify(label)})`;
const trailingErrorCount = '/\\d+$/';
const editorTab = name => `[...document.querySelectorAll('button')].filter(b => b.textContent.trim().replace(${trailingErrorCount}, '') === ${JSON.stringify(name)}).at(-1)`;

const token = (line, text, options) => clickAt(tokenPoint(line, text, options), options);

const shown = text => `${lines(text)}.length > 0`;
const errors = `document.querySelectorAll('.monaco-editor .squiggly-error').length`;
const log = `(document.querySelector('[role=log]')?.innerText ?? '')`;
const ready = `!!${button('Run')} && !${button('Run')}.disabled`;

async function smoothScroll(line, at = 0.45, duration = 700, { arrive = true } = {}) {
  if (arrive) {
    const whereLineLands = evaluate(`(() => {
      const r = [...document.querySelectorAll('.monaco-editor .monaco-scrollable-element.editor-scrollable')]
        .find(e => e.checkVisibility()).getBoundingClientRect();
      const y = r.top + ${at} * r.height;
      return [r.left, y - 200, Math.min(r.right, r.left + 900), y + 200].map(v => Math.round(v * devicePixelRatio));
    })()`);
    mark(undefined, undefined, { action: 'ui', boxes: [whereLineLands] });
    await sleep(900);
  }
  await scrollTo(line, at, duration);
}

async function type(text, delay = 70) {
  focus();
  run('xdotool', ['type', '--clearmodifiers', '--delay', String(delay), text]);
  focus();
  await sleep(300);
}

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

const frameSnapshot = () => browser('snapshot', '-i');
function frameElement(role, name) {
  const ref = frameSnapshot().split('\n').find(l => l.includes(`${role} "${name}"`))?.match(/ref=(e\d+)/)?.[1];
  if (!ref) throw new Error(`The program shows no ${role} "${name}"`);
  const box = Object.fromEntries(browser('get', 'box', `@${ref}`).split('\n').map(l => l.split(':').map(s => s.trim()))
    .map(([k, v]) => [k, Number(v)]));
  const frame = evaluate(`(() => { const r = document.querySelector('iframe[title="Program view"]').getBoundingClientRect(); return { x: r.x, y: r.y, scale: devicePixelRatio } })()`);
  return { x: Math.round((frame.x + box.x + box.width / 2) * frame.scale), y: Math.round((frame.y + box.y + box.height / 2) * frame.scale) + pageTop };
}
let runClickAwaitingProgram;
const headingAboveElement = 100, rowsBelowElement = 220;
async function program(role, name, message) {
  const deadline = Date.now() + 15000;
  while (!frameSnapshot().includes(`${role} "${name}"`)) {
    if (Date.now() > deadline) throw new Error(message);
    await sleep(250);
  }
  const at = frameElement(role, name);
  const programFraming = evaluate(`(() => {
    const r = document.querySelector('iframe[title="Program view"]').getBoundingClientRect();
    const [left, upper, right, lower] = [r.left, r.top, r.right, r.bottom].map(v => Math.round(v * devicePixelRatio));
    return [left, Math.max(upper + ${pageTop}, ${at.y - headingAboveElement}), right, Math.min(lower + ${pageTop}, ${at.y + rowsBelowElement})];
  })()`);
  if (runClickAwaitingProgram) runClickAwaitingProgram.boxes = [programFraming];
  runClickAwaitingProgram = undefined;
  mark(undefined, undefined, { action: 'ui', boxes: [programFraming] });
  console.log(`PASS: ${message}`);
}
const clickProgram = (role, name, options) => clickAt(frameElement(role, name), options);

async function clickRun() {
  await clickOn(button('Run'));
  runClickAwaitingProgram = actions.findLast(a => a.action === 'click');
}

async function runProject(expectation) {
  await expect(ready, 'The project is ready to run', { timeout: 60000 });
  await clickRun();
  await expectation();
  runClickAwaitingProgram = undefined;
}

async function pushConsoleOverProgramAndBack() {
  const handle = centre(`document.querySelector('[aria-label="Resize console"]')`);
  await move(handle.x, handle.y, 500);
  mark(handle.x, handle.y, { action: 'click' });
  run('xdotool', ['mousedown', '1']);
  await move(handle.x, handle.y - 330, 900);
  await sleep(700);
  await move(handle.x, handle.y + 60, 900);
  run('xdotool', ['mouseup', '1']);
  await sleep(600);
}

const { TEMPLATES } = await import('../../playground/client/templates.js');
const template = id => TEMPLATES.find(t => t.id === id).files[0].text;

async function cacheTakePackages() {
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
}

async function stage() {
  browser('open', page);
  await expect(ready, 'The playground loads', { timeout: 120000 });
  await cacheTakePackages();
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
    await expect(`${log}.includes('count: 4')`, 'The console shows each count', { shows: `[document.querySelector('#playground-console').parentElement]` });
    await sleep(800);
    await pushConsoleOverProgramAndBack();
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
    await clickOn(editorTab('Main.purs'));
    await expect(`${shown('module Main where')} || ${shown('mkTodos')} || ${shown('styles = StyleX.create')}`, 'Main.purs is back');
    const colorsCommentLine = todos.findIndex(l => l.startsWith('-- The program runs')) + 1;
    const stylePropsLine = todos.findIndex(l => l.startsWith('styleProps = StyleX.recordProps styles')) + 1;
    await smoothScroll(colorsCommentLine, 0.2);
    await token('-- The program runs', 'The');
    key('Home');
    await expect(`document.querySelector('.monaco-editor.focused .current-line') !== null && ${lines('-- The program runs')}.some(line => Math.abs(line.getBoundingClientRect().top - document.querySelector('.monaco-editor.focused .cursor').getBoundingClientRect().top) < 4)`, 'The caret is on the colors comment');
    await smoothScroll(stylePropsLine + 1, 0.7, 1100, { arrive: false });
    await clickAt(tokenPoint('styleProps = StyleX.recordProps styles', 'styles', { occurrence: 0, end: true }), { shift: true });
    key('shift+Down');
    await sleep(700);
    key('ctrl+x');
    await sleep(600);
    await clickOn(editorTab('Styles.purs'));
    await expect(`${shown('module Styles where')}`, 'Styles.purs is back');
    const belowLastLine = evaluate(`(() => {
      const r = [...document.querySelectorAll('.monaco-editor .monaco-scrollable-element.editor-scrollable')].find(e => e.checkVisibility()).getBoundingClientRect();
      return { x: Math.round((r.left + 240) * devicePixelRatio), y: Math.round((r.top + r.height * 0.4) * devicePixelRatio) };
    })()`);
    await clickAt(belowLastLine);
    key('ctrl+End');
    key('ctrl+v');
    await sleep(800);
    await expect(`${shown('styleProps = StyleX.recordProps styles')}`, 'The styles move into Styles.purs');
    await sleep(900);
    await clickOn(editorTab('Main.purs'));
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
    await overview(() => sleep(1500));
  });

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

const addressBarMiddleAbovePage = 19;
const showTabsAndAddressBar = () => run('xdotool', ['key', 'F11']);

async function share() {
  spawn(browserPath, [`--user-data-dir=${tools}/playground-profile`, '--incognito', '--new-window', 'about:blank'],
    { env, detached: true, stdio: 'ignore' }).unref();
  await sleep(3000);
  const window = run('xdotool', ['getactivewindow']);
  if (!run('xdotool', ['getwindowname', window]).startsWith('about:blank')) throw new Error('The incognito window did not open');
  showTabsAndAddressBar();
  await sleep(1500);
  run('xdotool', ['windowmove', window, '0', '0', 'windowsize', window, String(width), String(height)]);
  await sleep(500);
  await move(width * 0.55, height * 0.5, 200);
  const incognito = browser('tab', 'list').split('\n').find(l => l.includes('about:blank'))?.match(/\[(t\d+)\]/)?.[1];
  if (!incognito) throw new Error('The agent cannot see the incognito tab');
  browser('tab', incognito);
  pageTop = evaluate('Math.round((outerHeight - innerHeight) * devicePixelRatio)');
  const addressBar = { x: Math.round(width * 0.2), y: pageTop - addressBarMiddleAbovePage };
  await capture('playground-share', async () => {
    await sleep(600);
    await beat('open-link');
    await clickAt(addressBar, { duration: 700 });
    await sleep(500);
    run('xdotool', ['key', 'ctrl+v']);
    mark(addressBar.x, addressBar.y, { action: 'ui', boxes: [[0, pageTop - 40, Math.round(width * 0.62), pageTop]] });
    await sleep(1500);
    await overview(async () => {
      beats.push({ slug: 'loading', t: now() });
      run('xdotool', ['key', 'Return']);
      await expect(`location.pathname === '/playground/'`, 'The incognito window opens the link');
      await expect(ready, 'The shared project loads, with its packages', { timeout: 120000 });
      beats.push({ slug: 'shared-loaded', t: now() });
      await sleep(800);
    });
    await clickOn(editorTab('Styles.purs'));
    await sleep(1500);
    await clickOn(editorTab('Main.purs'));
    await sleep(600);
    await clickRun();
    await program('heading', 'React todos', 'The shared project runs');
    await clickProgram('textbox', 'What needs doing?');
    run('xdotool', ['type', '--delay', '60', 'it works everywhere']);
    run('xdotool', ['key', 'Return']);
    await program('checkbox', 'It Works Everywhere', 'The shared project title-cases todos too');
    await sleep(1500);
  });
  pageTop = 0;
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
