import { execFileSync, spawn } from 'node:child_process';
import { once } from 'node:events';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import * as cap from './cap.mjs';

export const tools = process.env.IRIS_DEMO_HOME || '/tmp/iris-editor-tools';
export const output = resolve(process.env.IRIS_DEMO_OUTPUT || `${tools}/recordings`);
export const { width, height } = cap;
export const env = { ...process.env, DISPLAY: ':94' };
export const run = (name, args) => execFileSync(name, args, { env, encoding: 'utf8' }).trim();
export const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const backend = process.env.IRIS_DEMO_RECORDER || 'cap';
const [speed, crf] = backend === 'cap' ? [cap.speed, cap.crf] : [0.75, 23];

export const lines = (...texts) => `[...document.querySelectorAll('.view-line')].filter(line => ${JSON.stringify(texts)}
  .some(text => line.textContent.replaceAll('\\u00a0', ' ').includes(text)))`;
export const suggestion = (...texts) => `${JSON.stringify(texts)}.every(text => document.querySelector('.suggest-widget .monaco-list-row.focused')?.innerText.includes(text))`;

export function recorder({ session, cdp, overlays, caret, chrome = { top: 0, bottom: 0 }, offset = () => 0, planner = {} }) {
  const browser = (...args) => run('agent-browser', ['--session', session, '--cdp', String(cdp), ...args]);
  const evaluate = code => JSON.parse(browser('eval', code));

  const actions = [], beats = [], captions = [];
  let epoch, steady = null, wide = false;
  const now = () => (Date.now() - epoch) / 1000;
  const mark = (x, y, detail = {}) => epoch && actions.push(steady
    ? { t: now(), action: 'steady', box: steady.box, zoom: steady.zoom }
    : wide ? { t: now(), action: 'overview' } : { t: now(), x, y, ...detail });

  async function steadily(frame, action) {
    steady = frame;
    mark();
    try { await action(); } finally { steady = null; }
  }
  async function overview(action) {
    wide = true;
    mark();
    try { await action(); } finally { wide = false; }
  }
  async function beat(slug, { continues = false } = {}) {
    await sleep(500);
    beats.push({ slug, t: now() });
    if (epoch && !steady && !continues) actions.push({ t: now(), action: 'beat' });
    await sleep(200);
  }

  const pointer = () => actions.findLast(a => a.action !== 'key' && a.action !== 'ui' && a.x !== undefined);
  const focus = () => {
    if (!epoch) return;
    const at = evaluate(caret) ?? pointer();
    if (at) mark(at.x, at.y, { action: 'key' });
  };

  async function expect(code, message, { shows = '[]', timeout = 15000 } = {}) {
    const boxes = evaluate(`new Promise(resolve => {
      const deadline = Date.now() + ${timeout};
      // Skip anything covered by something else, such as an editor behind the Settings dialog.
      const uncovered = (e, r) => {
        const hit = document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2);
        return hit && (e.contains(hit) || hit.closest('.monaco-editor') === e.closest('.monaco-editor'));
      };
      const boxes = () => [...document.querySelectorAll(${JSON.stringify(overlays.join(', '))}), ...${shows}]
        .filter(e => e.checkVisibility({ opacityProperty: true, visibilityProperty: true }))
        .map(e => [e, e.getBoundingClientRect()])
        .filter(([e, r]) => r.width > 0 && r.height > 0 && uncovered(e, r))
        .map(([, r]) => [r.left, r.top, r.right, r.bottom].map(v => Math.round(v * devicePixelRatio)));
      const check = () => {
        if (${code}) resolve(boxes());
        else if (Date.now() > deadline) resolve(false);
        else setTimeout(check, 100);
      }; check();
    })`);
    if (!boxes) throw new Error(message);
    const last = shows === '[]' ? actions.findLast(a => a.action !== 'ui' && a.x !== undefined) : undefined;
    mark(last?.x, last?.y, { action: 'ui', boxes });
    console.log(`PASS: ${message}`);
  }

  const location = () => {
    const shell = run('xdotool', ['getmouselocation', '--shell']);
    return ['X', 'Y'].map(axis => Number(shell.match(new RegExp(`^${axis}=(\\d+)`, 'm'))[1]));
  };
  async function move(x, y, duration = 650) {
    const [fromX, fromY] = location();
    const steps = Math.max(2, Math.round(duration / 25));
    const start = Date.now();
    for (let i = 1; i <= steps; i++) {
      const eased = (1 - Math.cos(Math.PI * i / steps)) / 2;
      run('xdotool', ['mousemove', String(Math.round(fromX + (x - fromX) * eased)), String(Math.round(fromY + (y - fromY) * eased))]);
      await sleep(Math.max(0, start + duration * i / steps - Date.now()));
    }
  }
  async function hold(count = 1) {
    for (let i = 0; i < count; i++) {
      if (i) await sleep(70);
      run('xdotool', ['mousedown', '1']);
      await sleep(50);
      run('xdotool', ['mouseup', '1']);
    }
  }
  async function clickAt({ x, y }, { count = 1, shift = false, duration } = {}) {
    await move(x, y, duration);
    mark(x, y, { action: 'click' });
    if (shift) run('xdotool', ['keydown', 'shift']);
    await hold(count);
    if (shift) run('xdotool', ['keyup', 'shift']);
    await sleep(300);
  }
  const centre = element => evaluate(`(() => {
    const r = (${element}).getBoundingClientRect();
    return { x: Math.round((r.x + r.width / 2) * devicePixelRatio), y: Math.round((r.y + r.height / 2) * devicePixelRatio) + ${offset()} };
  })()`);
  const clickOn = (element, options) => clickAt(centre(element), options);

  function tokenPoint(line, token, { occurrence = 0, end = false } = {}) {
    return evaluate(`(() => {
      const normalize = s => s.replaceAll('\\u00a0', ' ');
      const line = [...document.querySelectorAll('.view-line')].find(e => normalize(e.textContent).includes(${JSON.stringify(line)}));
      if (!line) throw new Error('Line not visible: ' + ${JSON.stringify(line)});
      const text = normalize(line.textContent), token = ${JSON.stringify(token)};
      let start = text.indexOf(${JSON.stringify(line)}) - 1;
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
          if (r.x < 0 || r.right > innerWidth || r.y < ${chrome.top} || r.bottom > innerHeight - ${chrome.bottom})
            throw new Error('Token clipped: ' + token);
          const x = ${end} ? r.right - 1 : r.x + r.width / 2;
          return { x: Math.round(x * devicePixelRatio), y: Math.round((r.y + r.height / 2) * devicePixelRatio) };
        }
        offset += node.length;
      }
    })()`);
  }

  async function aside(from) {
    const [x, y] = from ? [from.x, from.y] : location();
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

  async function smoothScroll(line, at = 0.45, duration = 700) {
    evaluate(`new Promise(resolve => {
      const scrollable = [...document.querySelectorAll('.monaco-editor .monaco-scrollable-element.editor-scrollable')]
        .find(e => e.checkVisibility());
      // How many pixels below fraction at of the editor the line sits; negative when above it.
      const offset = () => {
        const view = scrollable.getBoundingClientRect();
        const [number, r] = [...scrollable.closest('.monaco-editor').querySelectorAll('.line-numbers')]
          .map(e => [Number(e.textContent), e.getBoundingClientRect()])
          .filter(([n, r]) => n > 0 && r.height > 0)
          .sort((a, b) => a[1].top - b[1].top)[0];
        return r.top + (${line} - number + 0.5) * r.height - view.top - ${at} * view.height;
      };
      const wheel = pixels => {
        const r = scrollable.getBoundingClientRect();
        scrollable.dispatchEvent(new WheelEvent('wheel', { deltaY: -pixels * 120 / 50, deltaMode: 0, bubbles: true,
          cancelable: true, clientX: r.x + r.width / 2, clientY: r.y + r.height / 2 }));
      };
      const distance = offset(), started = performance.now();
      let sent = 0;
      const frame = now => {
        const t = Math.min(1, (now - started) / ${duration});
        const eased = t < 0.5 ? 4 * t ** 3 : 1 - (2 - 2 * t) ** 3 / 2;
        wheel(distance * eased - sent);
        sent = distance * eased;
        if (t < 1) requestAnimationFrame(frame);
        else setTimeout(resolve, 150);
      };
      requestAnimationFrame(frame);
    })`);
    await sleep(300);
  }

  async function keys(text, delay = 85) {
    focus();
    run('xdotool', ['type', '--clearmodifiers', '--delay', String(delay), text]);
    await sleep(300);
  }

  async function capture(name, action) {
    const raw = `${tools}/${name}-raw.mp4`;
    const project = `${tools}/cap/${name}.cap`;
    mkdirSync(output, { recursive: true });
    const recording = backend === 'cap' ? cap.start(project) : spawn('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y',
      '-f', 'x11grab', '-draw_mouse', '1', '-video_size', `${width}x${height}`, '-framerate', '60',
      '-i', ':94', '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '18', '-pix_fmt', 'yuv420p', raw],
      { env, stdio: ['pipe', 'ignore', 'inherit'] });
    for (const list of [actions, beats, captions]) list.length = 0;
    epoch = Date.now();
    try {
      await sleep(800);
      await action();
      await sleep(2000);
    } finally {
      epoch = undefined;
      if (backend === 'cap') {
        run('xdotool', ['mousemove_relative', '--', '1', '0']);
        await sleep(50);
        run('xdotool', ['mousemove_relative', '--', '-1', '0']);
        await sleep(50);
        cap.stop(recording);
      } else {
        recording.stdin.end('q\n');
        const [code] = await once(recording, 'exit');
        if (code !== 0) throw new Error(`ffmpeg exited ${code}`);
      }
    }
    if (backend === 'cap') {
      writeFileSync(`${project}/iris-actions.json`, JSON.stringify(actions, null, 2));
      writeFileSync(`${project}/iris-planner.json`, JSON.stringify(planner));
      const rendered = cap.render(project, actions, raw, { planner });
      console.log(JSON.stringify(rendered));
      const align = t => t + rendered.shift;
      writeFileSync(`${output}/${name}.pace.json`, JSON.stringify({
        first: align(actions[0]?.t ?? 0),
        last: align(actions.at(-1)?.t ?? 0),
        beats: beats.map(({ slug, t }) => ({ slug, t: align(t) })),
        captions: captions.map(caption => ({ ...caption, t: align(caption.t) })),
      }, null, 2));
    }
    run('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-an',
      '-vf', `setpts=(PTS-STARTPTS)/${speed},fps=60,tpad=stop_mode=clone:stop_duration=1`,
      '-c:v', 'libx264', '-preset', 'slow', '-crf', String(crf), '-pix_fmt', 'yuv420p',
      '-movflags', '+faststart', `${output}/${name}.mp4`]);
    writeFileSync(`${output}/${name}.txt`, browser('snapshot', '-i'));
    console.log(`Recorded ${name}`);
  }

  return {
    browser, evaluate, actions, beats, captions, now, mark, steadily, overview, beat, focus, expect,
    move, hold, clickAt, centre, clickOn, tokenPoint, aside, smoothScroll, keys, capture,
  };
}
