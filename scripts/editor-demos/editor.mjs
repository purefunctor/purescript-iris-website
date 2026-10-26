import { copyFileSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { height, lines, output, recorder, run, sleep, suggestion, tools, width } from './recorder.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const input = '.quick-input-widget input';
const caret = `(() => {
  // Typing into quick input is framed on the quick input itself.
  const quick = document.activeElement?.closest('.quick-input-widget')?.getBoundingClientRect();
  if (quick) return { x: Math.round((quick.x + quick.width / 2) * devicePixelRatio), y: Math.round((quick.y + quick.height / 2) * devicePixelRatio) };
  const cursor = document.querySelector('.monaco-editor.focused .cursor');
  const r = cursor?.getBoundingClientRect();
  return r && r.height > 0 ? { x: Math.round(r.x * devicePixelRatio), y: Math.round((r.y + r.height / 2) * devicePixelRatio) } : null;
})()`;
const {
  browser, evaluate, captions, now, mark, steadily, overview, beat, focus, expect,
  move, hold, clickOn, tokenPoint, aside, smoothScroll, keys, capture,
} = recorder({
  session: 'iriscode',
  cdp: 9223,
  overlays: ['.monaco-hover', '.suggest-widget', '.peekview-widget', '.quick-input-widget', '.action-widget', '.rename-box'],
  caret,
  chrome: { top: 80, bottom: 22 },
});
const press = key => (focus(), browser('press', key));

const region = (from, to) => `(() => {
  const text = line => line.textContent.replaceAll('\\u00a0', ' ');
  const lines = [...document.querySelectorAll('.view-line')]
    .sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);
  const start = lines.findIndex(line => text(line).includes(${JSON.stringify(from)}));
  const end = lines.findIndex((line, i) => i >= start && text(line).includes(${JSON.stringify(to)}));
  return start < 0 || end < 0 ? [] : lines.slice(start, end + 1).flatMap(line => [...line.querySelectorAll('span span')]);
})()`;
const highlights = `document.querySelectorAll('.cdr.wordHighlight, .cdr.wordHighlightStrong, .cdr.wordHighlightText')`;

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

async function token(line, text, action = 'hover', occurrence = 0) {
  const { x, y } = tokenPoint(line, text, { occurrence });
  await move(x, y);
  mark(x, y, { action });
  if (action === 'click') await hold();
  if (action === 'select') await hold(2);
  await sleep(300);
}

async function type(text) {
  focus();
  await aside();
  run('xdotool', ['type', '--clearmodifiers', '--delay', '85', text]);
  await sleep(300);
}

const index = 'Landing/Index.purs';
const player = 'Components/VideoPlayer.purs';
const demos = 'Landing/Demos.purs';
const benchmarks = 'Landing/Benchmarks.purs';
const copyButton = 'Components/CopyButton.purs';
const settings = `${tools}/profile/User/settings.json`;
const setting = (key, enabled) => {
  const value = JSON.parse(readFileSync(settings, 'utf8'));
  value[key] = enabled;
  writeFileSync(settings, JSON.stringify(value, null, 2));
};
const semantic = enabled => setting('editor.semanticHighlighting.enabled', enabled);
const onChange = enabled => setting('iris.server.diagnostics.onChange', enabled);
const activeTab = file => `document.querySelector('[role="tab"][aria-selected="true"][data-resource-name="${file}"]') !== null`;
const hover = text => `document.querySelector('.monaco-hover:not(.hidden)')?.innerText.includes(${JSON.stringify(text)})`;
const errors = `document.querySelectorAll('.squiggly-error').length`;
const marks = `[...${highlights}].filter(e => e.getBoundingClientRect().width > 0)`;
const on = text => `${marks}.filter(e => ${lines(text)}.some(line => {
  const [a, b] = [line.getBoundingClientRect(), e.getBoundingClientRect()];
  return b.top >= a.top - 2 && b.bottom <= a.bottom + 2;
})).length`;
const shown = text => `${lines(text)}.some(line => {
  const r = line.getBoundingClientRect(), v = line.closest('.monaco-scrollable-element').getBoundingClientRect();
  return r.top >= v.top - 3 && r.bottom <= v.bottom + 3;
})`;

const handler = `    select number = for_ (index chapters number) \\{ at } -> do
      setSeek \\{ request } -> { request: request + 1, time: at }
      setTime at
      setPlaying (const true)
`;
const foldable = 'import Data.Foldable (for_)\n';

async function quickInput(key) {
  browser('press', key);
  await expect(`document.querySelector('.quick-input-widget')?.checkVisibility({ opacityProperty: true })
    && getComputedStyle(document.querySelector('.quick-input-widget')).opacity === '1'`, 'Quick input opens',
    { shows: `[document.querySelector('.quick-input-widget')]` });
  await sleep(600);
}

const lineOf = text => readFileSync(`${tools}/iris-website/src/Website/${demos}`, 'utf8').split('\n')
  .findIndex(line => line.includes(text)) + 1;

const spans = `(() => {
  const out = {};
  for (const line of document.querySelectorAll('.view-line')) {
    let offset = 0;
    out[Math.round(line.getBoundingClientRect().top)] = [...line.querySelectorAll(':scope > span > span')].map(span => {
      const style = getComputedStyle(span), start = offset;
      offset += span.textContent.length;
      return [start, style.color + ' ' + style.fontStyle];
    });
  }
  return out;
})()`;
const recoloured = before => `(() => {
  const before = ${JSON.stringify(before)}, scale = devicePixelRatio;
  const changed = [];
  for (const line of document.querySelectorAll('.view-line')) {
    // Lines partly hidden behind the tabs and breadcrumbs are not captioned.
    const view = line.closest('.monaco-scrollable-element').getBoundingClientRect();
    if (line.getBoundingClientRect().top < view.top - 1 || line.getBoundingClientRect().bottom > view.bottom + 1) continue;
    const top = Math.round(line.getBoundingClientRect().top), old = before[top] ?? [];
    const text = line.textContent.replaceAll('\\u00a0', ' ');
    const end = [...line.querySelectorAll(':scope > span > span')].filter(span => span.textContent.trim()).at(-1);
    let offset = 0;
    for (const span of line.querySelectorAll(':scope > span > span')) {
      const style = getComputedStyle(span), start = offset;
      offset += span.textContent.length;
      const word = span.textContent.trim().replace(/\\.$/, '');
      if (!word) continue;
      const was = old.findLast(([at]) => at <= start)?.[1];
      if (was === style.color + ' ' + style.fontStyle) continue;
      const range = document.createRange();
      range.selectNodeContents(span);
      const r = range.getBoundingClientRect();
      changed.push({ word, line: text, style: style.color + ' ' + style.fontStyle,
        box: [r.left, r.top, r.left + r.width * word.length / span.textContent.length, r.bottom].map(v => Math.round(v * scale)),
        end: Math.round(end.getBoundingClientRect().right * scale) });
    }
  }
  return changed;
})()`;
const roles = [
  { label: 'Declarations', color: '--syn-function', example: 'styles', anchor: ['styles', 'styles ='] },
  { label: 'Record labels', color: '--syn-label', example: 'onInstall', anchor: ['fontFamily', 'fontFamily:'] },
  { label: 'Module qualifiers', color: '--syn-namespace', example: 'Hooks', anchor: ['Hooks', 'reactComponent'] },
  { label: 'Bindings', color: '--syn-parameter', example: 'setRipples', anchor: ['setRipples', 'useState 0'] },
];

async function stage() {
  let dialog = '';
  try { dialog = run('xdotool', ['search', '--onlyvisible', '--name', '^Visual Studio Code$']); } catch {}
  if (dialog) throw new Error('Dismiss the native VS Code dialog on the recording display first');
  const source = readFileSync(`${root}/src/Website/${demos}`, 'utf8');
  if (!source.includes(handler) || !source.includes(foldable))
    throw new Error('Demos.purs no longer contains the handler and import that the take writes');
  semantic(false);
  onChange(false);
  await command('File: Save All Files');
  await command('View: Close All Editors');
  for (const file of [index, player, benchmarks, copyButton, 'Components/Terminal.purs', 'Components/CodeBlock.purs', 'Components/Button.purs'])
    copyFileSync(`${root}/src/Website/${file}`, `${tools}/iris-website/src/Website/${file}`);
  writeFileSync(`${tools}/iris-website/src/Website/${demos}`,
    source.replace(handler, '    select _ = pure unit\n').replace(foldable, ''));
  if (evaluate(`!!document.querySelector('.part.sidebar')?.checkVisibility()`)) press('Control+b');
  if (evaluate(`!!document.querySelector('.part.panel')?.checkVisibility()`)) {
    if (evaluate(`[...document.querySelectorAll('.part.panel .monaco-button')].some(b => b.textContent.trim() === 'Discard')`))
      await clickOn(`[...document.querySelectorAll('.part.panel .monaco-button')].find(b => b.textContent.trim() === 'Discard')`);
    await sleep(500);
  }
  if (evaluate(`!!document.querySelector('.part.panel')?.checkVisibility()`)) {
    press('Control+j');
    await sleep(500);
  }
  await open(index, 1);
  await open(index, 36);
  if (!evaluate(`${shown('styles =')} && ${shown(', footer')}`))
    throw new Error('Index.purs lines 25–48 must all be in view');
  await move(1560 * width / 1920, 860 * height / 1080, 300);
  await sleep(1500);
}

const cases = {
  async trailer() {
    await stage();
    await capture('trailer', async () => {
      await beat('semantic-highlighting');
      await overview(async () => {
        await sleep(2200);
        const before = evaluate(spans);
        semantic(true);
        await expect(`${recoloured(before)}.length > 0`, 'Semantic tokens recolour Index.purs');
        await sleep(300);
        const changed = evaluate(recoloured(before));
        const t = now();
        const styleOf = word => changed.find(span => span.word === word)?.style;
        for (const span of changed)
          if (!roles.some(role => styleOf(role.example) === span.style))
            throw new Error(`Semantic tokens recolour ${span.word}, which no caption describes`);
        for (const role of roles) {
          const tokens = changed.filter(span => span.style === styleOf(role.example));
          const anchor = tokens.find(span => span.word === role.anchor[0] && span.line.includes(role.anchor[1]));
          if (!anchor) throw new Error(`No ${role.label} caption anchor`);
          captions.push({ t, label: role.label, color: role.color, boxes: tokens.map(span => span.box),
            anchor: { box: anchor.box, end: anchor.end } });
        }
        console.log(`PASS: ${captions.length} captions cover every recoloured token`);
        await sleep(7000);
      });

      await beat('go-to-definition');
      await overview(async () => {
        await token('element Demos.component {}', 'component', 'click');
        await sleep(300);
        press('F12');
        await expect(`${activeTab('Demos.purs')} && ${shown('component = unsafePerformEffect')}`,
          'Go to definition opens the demo section component');
        await sleep(900);
      });

      await beat('information-on-hover');
      for (const [line, name, type, rest] of [
        ['time /\\ setTime', 'time', 'Number', 900],
        ['time /\\ setTime', '/\\', 't0 -> t1 -> Tuple t0 t1', 2000],
        ['seek /\\ setSeek', 'seek', '{ request :: Int, time :: Number }', 1300],
        ['chapter.at <= time', '<=', 'Ord a => a -> a -> Boolean', 1400],
        ['chapter = index', 'chapter', 'Maybe { at :: Number, description :: String, title :: String }', 1500],
      ]) {
        await token(line, name);
        await expect(hover(type), `Hovering ${name} shows ${type}`);
        await sleep(rest);
      }

      await beat('document-highlights');
      browser('press', 'Escape');
      await sleep(200);
      await token('(\\chapter -> chapter.at', 'chapter', 'click');
      await expect(`${marks}.length === 2 && ${on('(\\chapter -> chapter.at')} === 2 && ${on('chapter = index')} === 0`,
        'The lambda parameter highlights its own use, not the chapter bound beside it',
        { shows: region('selected = findLastIndex', 'chapter = index') });
      await sleep(1500);

      await beat('document-symbols');
      await quickInput('Control+Shift+o');
      await keys('styles', 60);
      await expect(`document.querySelector('.quick-input-list .monaco-list-row.focused')?.innerText.includes('styles')`,
        'Document symbols find the style table');
      await sleep(1000);
      browser('press', 'Enter');
      await sleep(500);
      await smoothScroll(lineOf('StyleX.conditionalCase breakpoints.from960'), 0.45, 450);
      await expect(shown('StyleX.conditionalCase breakpoints.from960'), 'The style table is in view',
        { shows: region('layout:', 'StyleX.conditionalCase breakpoints.from960') });
      await sleep(900);

      await beat('find-references');
      await token('StyleX.conditionalCase breakpoints.from960', 'breakpoints', 'click');
      await sleep(300);
      press('Shift+F12');
      await expect(`['SiteNav.purs', 'Benchmarks.purs'].every(file => document.querySelector('.peekview-widget')?.innerText.includes(file))`,
        'References to breakpoints span the workspace');
      await sleep(1000);
      for (const file of ['Code.purs', 'JavaScript.purs']) {
        for (const key of ['Down', 'Right', 'Down']) {
          browser('press', key);
          await sleep(300);
        }
        await expect(`document.querySelector('.peekview-widget .peekview-title')?.innerText.includes(${JSON.stringify(file)})
          && [...document.querySelectorAll('.peekview-widget .view-line')].some(line => line.textContent.includes('breakpoints.'))`,
          `The preview shows a reference to breakpoints in ${file}`);
        await sleep(1300);
        for (const key of ['Left', 'Left']) {
          browser('press', key);
          await sleep(250);
        }
      }
      await sleep(300);
      press('Escape');
      await sleep(300);

      await beat('workspace-symbols');
      await quickInput('Control+t');
      await keys('Measured', 60);
      await expect(`document.querySelector('.quick-input-list .monaco-list-row.focused')?.innerText.includes('Measured')`,
        'Workspace symbols find the benchmark chart\'s Measured type');
      await sleep(600);
      await overview(async () => {
        await sleep(600);
        press('Enter');
        await expect(`${activeTab('Benchmarks.purs')} && ${shown('type Measured a = { cold :: a, hot :: a }')}`,
          'Workspace-symbol selection opens Measured in Benchmarks.purs');
        await sleep(400);
      });
      await expect(shown('type Measured a'), 'The Measured declaration is in view',
        { shows: region('type Measured a = { cold :: a, hot :: a }', 'tool :: Measured String') });
      await sleep(900);

      await beat('rename', { continues: true });
      await token('type Measured a = { cold :: a, hot :: a }', 'a', 'click', 1);
      press('F2');
      await sleep(400);
      await aside();
      run('xdotool', ['type', '--delay', '70', 'value']);
      await sleep(400);
      press('Enter');
      await expect(`${lines('type Measured value = { cold :: value, hot :: value }')}.length === 1`,
        'The type variable is renamed throughout its declaration', { shows: region('type Measured value', 'type Measured value') });
      await sleep(1400);

      await quickInput('Control+p');
      await keys('CopyButton.purs', 40);
      await sleep(400);
      press('Enter');
      await expect(`${activeTab('CopyButton.purs')} && ${shown('data Size = Small | Medium')}`, 'CopyButton.purs opens');
      await sleep(300);
      await token('data Size = Small | Medium', 'Small', 'click');
      press('F2');
      await sleep(400);
      await aside();
      run('xdotool', ['type', '--delay', '70', 'Compact']);
      await sleep(400);
      press('Enter');
      await expect(`${lines('data Size = Compact | Medium')}.length === 1 && ${lines('Compact -> iconButtonStyles.small')}.length === 1`,
        'The constructor is renamed with its pattern', { shows: region('data Size = Compact', 'Medium -> iconButtonStyles') });
      await sleep(900);
      await token('data Size = Compact | Medium', 'Compact', 'click');
      press('Shift+F12');
      await expect(`['Terminal.purs', 'CodeBlock.purs'].every(file => document.querySelector('.peekview-widget')?.innerText.includes(file))`,
        'The renamed constructor is used in other modules');
      await sleep(700);
      const previewed = file => `document.querySelector('.peekview-widget .peekview-title')?.innerText.includes(${JSON.stringify(file)})
        && [...document.querySelectorAll('.peekview-widget .view-line')].some(line => line.textContent.includes('CopyButton.Compact'))`;
      for (const [row, file] of [['Home', 'CodeBlock.purs'], ['End', 'Terminal.purs']]) {
        press(row);
        await sleep(250);
        press('Right');
        await sleep(250);
        press('Down');
        await expect(previewed(file), `The preview shows CopyButton.Compact in ${file}`);
        await sleep(1100);
      }
      press('Escape');
      await sleep(300);

      await overview(async () => {
        await clickOn(`document.querySelector('[role="tab"][data-resource-name="Demos.purs"]')`);
        await expect(activeTab('Demos.purs'), 'The Demos.purs tab returns to the component');
        await smoothScroll(lineOf('select _ = pure unit'), 0.5);
        await expect(shown('select _ = pure unit'), 'The stub handler is in view');
      });
      await sleep(400);

      const zoom = 1.3, [frameWidth, frameHeight] = [width / zoom, height / zoom];
      const centreOf = text => evaluate(`(() => {
        const r = ${lines(text)}[0].getBoundingClientRect();
        return (r.top + r.height / 2) * devicePixelRatio;
      })()`);
      const fractionAt = y => evaluate(`(() => {
        const view = [...document.querySelectorAll('.monaco-editor .monaco-scrollable-element.editor-scrollable')]
          .find(e => e.checkVisibility()).getBoundingClientRect();
        return (${y} / devicePixelRatio - view.top) / view.height;
      })()`);
      const stubAt = centreOf('select _ = pure unit');
      const top = Math.min(height - frameHeight, Math.max(0, stubAt - 0.35 * frameHeight));
      const handler = { zoom, box: [0, top, frameWidth, top + frameHeight] };

      await beat('automatic-import');
      await steadily(handler, async () => {
        await token('select _ = pure unit', '_', 'select');
        press('Shift+End');
        await type('number = for_');
        press('Control+space');
        await expect(suggestion('for_', 'Data.Foldable'), 'Completion offers for_ from Data.Foldable, which is not imported');
        await sleep(1200);
        press('Enter');
        await expect(`${lines('select number = for_')}.length === 1`, 'Completion inserts for_');
        await sleep(400);
        const staged = readFileSync(`${tools}/iris-website/src/Website/${demos}`, 'utf8').split('\n');
        await smoothScroll(staged.findLastIndex(line => line.startsWith('import ')) + 2, fractionAt(top + frameHeight / 2));
        await expect(`${lines('import Data.Foldable (for_)')}.length === 1`, 'Completion adds the Data.Foldable import');
        await sleep(1200);
        await smoothScroll(lineOf('select _ = pure unit') + 1, fractionAt(stubAt));
        await expect(shown('select number = for_'), 'The handler is back in view');
        await keys(' (index chapters number) \\{ at } -> do', 55);

        await beat('completion');
        press('Enter');
        await keys('  setSee');
        press('Control+space');
        await expect(suggestion('setSeek'), 'Completion offers the hook\'s local setSeek');
        await sleep(1200);
        press('Enter');
        await expect(`${lines('      setSeek')}.length === 1`, 'Completion inserts setSeek');

        await beat('typed-hole-suggestions');
        await keys(' \\{ request } -> { request: request + 1, time: ?time }', 50);
        for (const key of ['Left', 'Left', 'Left']) press(key);
        await sleep(600);
        press('Control+.');
        await expect(`document.querySelector('.action-widget')?.innerText.includes("Replace hole with 'at'")`,
          'Quick fix suggests at for the typed hole');
        await sleep(1400);
        await clickOn(`[...document.querySelectorAll('.action-widget .monaco-list-row')].find(row => row.innerText.includes("Replace hole with 'at'"))`);
        await expect(`${lines('time: at }')}.length === 1`, 'The hole is replaced with at');
        press('End');

        await beat('live-diagnostics');
        onChange(true);
        await sleep(500);
        press('Enter');
        await type('setTime at');
        press('Enter');
        await keys('setPlaying true');
        await expect(`${errors} > 0`, 'Passing a Boolean to the setter is an error before saving');
        await token('setPlaying true', 'true');
        await expect(hover("Cannot unify 'Boolean' with 'Boolean -> Boolean'"), 'The error explains the mismatch');
        await sleep(1800);
        await token('setPlaying true', 'true', 'select');
        await type('(const true)');
        await expect(`${errors} === 0`, 'Correcting the call clears the error');
        press('Control+s');
        await sleep(900);
      });
    });
    await command('File: Save All Files');
    await sleep(800);
    const seeded = file => readFileSync(`${tools}/iris-website/src/Website/${file}`, 'utf8');
    const original = file => readFileSync(`${root}/src/Website/${file}`, 'utf8');
    const expected = {
      [demos]: original(demos),
      [benchmarks]: original(benchmarks).replace('type Measured a = { cold :: a, hot :: a }', 'type Measured value = { cold :: value, hot :: value }'),
      [copyButton]: original(copyButton).replace('data Size = Small | Medium', 'data Size = Compact | Medium')
        .replace('  Small -> iconButtonStyles.small', '  Compact -> iconButtonStyles.small'),
      'Components/Terminal.purs': original('Components/Terminal.purs').replaceAll('CopyButton.Small', 'CopyButton.Compact'),
      'Components/CodeBlock.purs': original('Components/CodeBlock.purs').replaceAll('CopyButton.Small', 'CopyButton.Compact'),
      'Components/Button.purs': original('Components/Button.purs'),
    };
    const unordered = text => text.replace(foldable, '');
    if (seeded(demos).split(foldable).length !== 2) throw new Error('The take does not import for_ exactly once');
    for (const [file, text] of Object.entries(expected))
      if (unordered(seeded(file)) !== unordered(text)) {
        writeFileSync(`${output}/trailer-${file.split('/').at(-1)}`, seeded(file));
        throw new Error(`The take's ${file} differs from the expected result; see ${output}`);
      }
    console.log('PASS: The take writes the repository\'s files, with its renames applied');
    for (const file of Object.keys(expected))
      copyFileSync(`${root}/src/Website/${file}`, `${tools}/iris-website/src/Website/${file}`);
  },
};

try {
  let display = evaluate('({width:innerWidth,height:innerHeight,scale:devicePixelRatio})');
  if (display.width * display.scale !== width) {
    browser('press', 'F11');
    await sleep(3000);
    display = evaluate('({width:innerWidth,height:innerHeight,scale:devicePixelRatio})');
  }
  if (display.width * display.scale !== width || display.height * display.scale !== height)
    throw new Error(`VS Code must be fullscreen (F11) on the ${width}×${height} desktop`);
  console.log(`Native VS Code at ${display.scale * 100}% — ${width}×${height}`);
  const selected = process.argv.slice(2);
  if (!selected.length) throw new Error(`Choose a clip or all: ${Object.keys(cases).join(', ')}`);
  for (const name of selected.includes('all') ? Object.keys(cases) : selected) {
    if (!cases[name]) throw new Error(`Unknown demo: ${name}`);
    await cases[name]();
  }
} finally {
  browser('close');
}
