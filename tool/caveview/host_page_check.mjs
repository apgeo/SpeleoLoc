// Loads the 3D viewer's host page in headless Chromium the way the app does —
// the page, the vendored CaveView build and one survey file served from a
// loopback port — and prints a verdict: what the page reported over its
// channel, how many requests left the loopback origin, and, with --focus,
// whether a tap on the focused station comes back as that station.
//
// It prints counts and protocol messages, never a survey's contents, so it can
// be pointed at a real model. A screenshot is only written when asked for, and
// only an invented fixture should be screenshotted.
//
// Usage:
//   node tool/caveview/host_page_check.mjs [--model <file>] [--focus <station>]
//                                          [--lang ro] [--screenshot <png>]
// Playwright is taken from PLAYWRIGHT_NODE_MODULES (default: the SilexGIS
// client's node_modules), as the CaveView fork's own smoke test does.
// Exit codes: 0 pass, 1 fail, 2 could not run.
import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { extname, join, normalize, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(import.meta.url), '../../..');
const args = process.argv.slice(2);
const option = (name, fallback) => {
  const at = args.indexOf(name);
  return at >= 0 ? args[at + 1] : fallback;
};
const modelPath = resolve(option('--model', join(root, 'test_data/cave_models/test_cave.lox')));
const focus = option('--focus', null);
const lang = option('--lang', 'en');
const screenshot = option('--screenshot', null);

const modules = process.env.PLAYWRIGHT_NODE_MODULES
  ?? '/home/devuser1/projects/silexgis/silexgis/client/node_modules';
let chromium;
try {
  ({ chromium } = createRequire(join(modules, 'noop.js'))('playwright'));
} catch (error) {
  console.log(`could not load Playwright from ${modules}: ${error.message}`);
  process.exit(2);
}

const caveviewDirs = readdirSync(join(root, 'assets/caveview')).filter((d) => d.startsWith('v'));
if (caveviewDirs.length !== 1) {
  console.log(`expected one vendored CaveView version, found ${caveviewDirs.length}`);
  process.exit(2);
}
const caveviewDir = join(root, 'assets/caveview', caveviewDirs[0]);
const hostDir = join(root, 'assets/caveview/host');
const modelName = `model${extname(modelPath).toLowerCase()}`;
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css',
  '.json': 'application/json', '.svg': 'image/svg+xml' };

function fileUnder(dir, rest) {
  const path = normalize(join(dir, rest));
  return path.startsWith(dir + sep) ? path : null;
}

const server = createServer((request, response) => {
  const url = new URL(request.url, 'http://127.0.0.1');
  let path = null;
  if (url.pathname === `/t/model/${modelName}`) path = modelPath;
  else if (url.pathname.startsWith('/t/host/')) path = fileUnder(hostDir, url.pathname.slice(8));
  else if (url.pathname.startsWith('/t/caveview/')) path = fileUnder(caveviewDir, url.pathname.slice(12));
  try {
    if (path === null || !statSync(path).isFile()) throw new Error('none');
    response.writeHead(200, { 'content-type': TYPES[extname(path)] ?? 'application/octet-stream' });
    response.end(readFileSync(path));
  } catch {
    response.writeHead(404);
    response.end();
  }
});
await new Promise((done) => server.listen(0, '127.0.0.1', done));
const origin = `http://127.0.0.1:${server.address().port}`;

const browser = await chromium.launch({
  args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--ignore-gpu-blocklist'],
});
const page = await browser.newPage({ viewport: { width: 412, height: 780 } });
const messages = [];
let outside = 0;
page.on('request', (request) => {
  if (!request.url().startsWith(origin)) outside++;
});
await page.exposeFunction('__report', (text) => messages.push(JSON.parse(text)));
await page.addInitScript(() => {
  window.SpeleoLocViewer = { postMessage: (text) => window.__report(text) };
});

const waitFor = async (predicate, ms) => {
  const until = Date.now() + ms;
  while (Date.now() < until) {
    const found = messages.find(predicate);
    if (found) return found;
    await new Promise((done) => setTimeout(done, 100));
  }
  return null;
};

let failed = false;
await page.goto(`${origin}/t/host/index.html?model=${modelName}&lang=${lang}`);
const ready = await waitFor((m) => m.type === 'ready', 15000);
console.log(ready ? `ready: ${ready.engine} ${ready.engineVersion}` : 'ready: never');
const settled = await waitFor((m) => m.type === 'loaded' || m.type === 'error', 60000);
if (settled?.type === 'loaded') {
  console.log(`loaded: ${settled.stations} stations`);
} else {
  failed = true;
  console.log(settled ? `error: ${settled.code}` : 'loaded: never');
}

if (focus && settled?.type === 'loaded') {
  await page.evaluate((station) => window.speleolocViewer.receive(
    JSON.stringify({ v: 1, type: 'focusStation', station, span: 20 })), focus);
  await page.waitForTimeout(2500);
  const box = await page.locator('#model canvas').first().boundingBox();
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  const tapped = await waitFor((m) => m.type === 'stationTapped', 5000);
  const same = tapped?.station === focus;
  if (!same) failed = true;
  console.log(`tap at the focused station: ${same ? 'reported as that station' : tapped ? 'reported as another station' : 'nothing reported'}`);
  await page.mouse.move(box.x + 50, box.y + 300);
  await page.mouse.down();
  await page.mouse.move(box.x + 250, box.y + 320, { steps: 8 });
  await page.mouse.up();
  await page.waitForTimeout(500);
  const afterDrag = messages.filter((m) => m.type === 'stationTapped').length;
  console.log(`a drag reported ${afterDrag - 1} station taps`);
  if (afterDrag !== 1) failed = true;
}

if (focus && settled?.type === 'loaded') {
  const send = (command) => page.evaluate((text) => window.speleolocViewer.receive(text),
    JSON.stringify({ v: 1, ...command }));
  const answer = async (type) => {
    const before = messages.filter((m) => m.type === type).length;
    return () => waitFor((m, i) => m.type === type
      && messages.filter((x) => x.type === type).indexOf(m) >= before, 5000);
  };

  let next = await answer('marksResolved');
  await send({ type: 'setMarks', marks: [
    { id: 'p1', station: focus, label: 'Mapped place', color: '#ff9800' },
    { id: 'p2', station: 'no.such.station', label: 'Lost', color: '#ff9800' },
  ] });
  const resolved = await next();
  const marksOk = resolved?.unresolved?.length === 1 && resolved.unresolved[0] === 'p2';
  console.log(`marks: ${marksOk ? 'placed, the missing station reported' : 'wrong answer'}`);
  if (!marksOk) failed = true;

  next = await answer('stationInfo');
  await send({ type: 'getStation', station: focus });
  const info = await next();
  console.log(`station info: ${info ? `${info.splays.length} splays` : 'none'}`);
  if (!info) failed = true;

  if (info?.splays.length > 0) {
    await send({ type: 'focusStation', station: focus, span: 15 });
    await page.waitForTimeout(2000);
    await send({ type: 'showSplayPicker', station: focus });
    await page.waitForTimeout(500);
    const dots = page.locator('.splay-dot:not([hidden])');
    const shown = await dots.count();
    next = await answer('splayPicked');
    if (shown > 0) {
      const box = await dots.first().boundingBox();
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    }
    const picked = await next();
    const match = picked && info.splays.some((s) => s.every((v, i) => Math.abs(v - picked.offset[i]) < 1e-6));
    console.log(`splay picker: ${shown} dots shown; ${match ? 'the tapped splay reported' : 'no splay reported'}`);
    if (!match) failed = true;
    await send({ type: 'hideSplayPicker' });
  }

  next = await answer('trailInfo');
  await send({ type: 'setTrail', id: 't', stations: [focus, focus], color: '#00bcd4' });
  const trail = await next();
  console.log(`trail: ${trail ? `${trail.gaps} gaps` : 'none'}`);
  if (!trail) failed = true;
}

if (screenshot) await page.screenshot({ path: screenshot });
const errors = messages.filter((m) => m.type === 'error').length;
console.log(`errors reported: ${errors}; requests outside the loopback origin: ${outside}`);
if (errors > 0 || outside > 0) failed = true;

await browser.close();
server.close();
console.log(failed ? 'FAIL' : 'PASS');
process.exit(failed ? 1 : 0);
