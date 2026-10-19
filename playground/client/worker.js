// The playground's Web Worker. It hosts a language server, either the WebAssembly build of the
// Iris server or the JavaScript mock, and downloads the whole package set for it.
//
// Page to worker:
//   { type: "start", server: "auto" | "mock" }
//   { type: "lsp", message }                  a JSON-RPC message for the server
//   { type: "read", id, uri }                 the text of a package or Prim source
// Worker to page:
//   { type: "progress", packageSet, loaded, total, bytes, totalBytes }   packages downloaded so far
//   { type: "started", server: { kind: "iris" | "mock", version }, packageSet, packages }
//   { type: "failed", error }                 the packages or the server could not be loaded
//   { type: "lsp", message }
//   { type: "read", id, text }
//   { type: "crashed", error }                the server panicked
//
// The server receives every package once the client sends `initialized`, before any document,
// and loads the modules that the project imports.

import index from "../packages/index.json";
import { archiveUrl, unpackPackage } from "../packages/registry.js";
import { MockServer } from "./mock-server.js";

const CACHE = "iris-playground-registry-v1";
const SERVER_BASE = "/playground/language-server/";
// Registry archives are small, so the download is bound by round trips rather than bandwidth.
const CONCURRENCY = 16;

let server;
let packages;
let crashed = false;
const queue = [];
let draining = false;
let idle;

self.onmessage = async ({ data }) => {
  switch (data.type) {
    case "start":
      return start(data.server);
    case "lsp":
      queue.push(data.message);
      return schedule();
    case "read":
      return self.postMessage({ type: "read", id: data.id, text: readSource(data.uri) });
  }
};

async function start(preference) {
  try {
    const [iris, downloaded] = await Promise.all([
      preference === "mock" ? null : loadIris(),
      downloadPackageSet(),
    ]);
    packages = downloaded;
    server = iris ?? new MockServer();
    self.postMessage({
      type: "started",
      server: { kind: iris ? "iris" : "mock", version: iris?.version ?? null },
      packageSet: index.packageSet.version,
      packages: Object.entries(index.packages).map(([name, entry]) => ({ name, version: entry.version })),
    });
    schedule();
  } catch (error) {
    self.postMessage({ type: "failed", error: error.message ?? String(error) });
  }
}

/** Loads the built or downloaded server, or returns null when there is none. */
async function loadIris() {
  const response = await fetch(`${SERVER_BASE}manifest.json`, { cache: "no-cache" });
  const type = response.headers.get("content-type") ?? "";
  if (!response.ok || !type.includes("json")) return null;
  const manifest = await response.json();
  const bindings = await import(/* @vite-ignore */ `${SERVER_BASE}language_server.js`);
  await bindings.default({ module_or_path: `${SERVER_BASE}language_server_bg.wasm` });
  const instance = new bindings.LanguageServer();
  instance.version = `${manifest.iris} (${manifest.revision})`;
  return instance;
}

// Messages are handled in batches, so that a request cancelled while it waited is dropped, and
// diagnostics are collected one source at a time while nothing else waits.
function schedule() {
  if (draining || !server || crashed) return;
  draining = true;
  setTimeout(drain, 0);
}

function drain() {
  draining = false;
  if (crashed) return;
  clearTimeout(idle);
  const batch = queue.splice(0);
  const cancelled = new Set(
    batch.filter((message) => message.method === "$/cancelRequest").map((message) => message.params.id),
  );
  try {
    for (const message of batch) {
      if (message.method === "$/cancelRequest") continue;
      if (message.id !== undefined && cancelled.has(message.id)) {
        send({ jsonrpc: "2.0", id: message.id, error: { code: -32800, message: "Request cancelled" } });
        continue;
      }
      for (const reply of JSON.parse(server.handle(JSON.stringify(message)))) send(reply);
      if (message.method === "initialized") setPackages();
    }
  } catch (error) {
    return fail(error);
  }
  idle = setTimeout(collectDiagnostics, 0);
}

/** Hands the downloaded packages to the server, which keeps them, and drops this copy. */
function setPackages() {
  const message = { jsonrpc: "2.0", id: "packages", method: "iris/setPackages", params: { packages } };
  packages = null;
  const [reply, ...notifications] = JSON.parse(server.handle(JSON.stringify(message)));
  if (reply?.error) throw new Error(`The language server rejected the packages: ${reply.error.message}`);
  for (const notification of notifications) send(notification);
}

function collectDiagnostics() {
  if (crashed || queue.length > 0) return;
  try {
    const next = server.nextDiagnostics();
    if (next === undefined) return;
    send(JSON.parse(next));
  } catch (error) {
    return fail(error);
  }
  idle = setTimeout(collectDiagnostics, 0);
}

function send(message) {
  self.postMessage({ type: "lsp", message });
}

function fail(error) {
  crashed = true;
  self.postMessage({ type: "crashed", error: String(error?.stack ?? error) });
}

/**
 * Downloads every package in the package set, or reads it from the cache, and reports progress.
 * Each package is fetched and cached on its own, so that later visits, and a future playground
 * that downloads packages only when the project imports them, reuse the same entries.
 */
async function downloadPackageSet() {
  const entries = Object.entries(index.packages).map(([name, entry]) => ({ name, ...entry }));
  const total = entries.length;
  const totalBytes = entries.reduce((sum, entry) => sum + entry.bytes, 0);
  let loaded = 0;
  let bytes = 0;
  const packageSet = index.packageSet.version;
  const report = () => self.postMessage({ type: "progress", packageSet, loaded, total, bytes, totalBytes });
  report();
  const cache = await caches.open(CACHE).catch(() => null);
  return mapConcurrently(entries, CONCURRENCY, async (entry) => {
    const files = await loadPackage(cache, entry);
    loaded += 1;
    bytes += entry.bytes;
    report();
    return { name: entry.name, files };
  });
}

async function loadPackage(cache, entry) {
  const url = archiveUrl(entry);
  const cached = await cache?.match(url).catch(() => undefined);
  const archive = cached ? await cached.arrayBuffer() : await fetchWithRetry(url);
  try {
    const files = await unpackPackage(entry, archive);
    if (!cached) await cache?.put(url, new Response(archive)).catch(() => {});
    return files;
  } catch (error) {
    // A corrupt cached copy is dropped, so a retry downloads it again.
    if (cached) await cache?.delete(url).catch(() => {});
    throw error;
  }
}

async function fetchWithRetry(url) {
  let lastError;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetch(url, {
        mode: "cors",
        credentials: "omit",
        signal: AbortSignal.timeout(20_000),
      });
      if (!response.ok) throw new Error(`${url} returned ${response.status}`);
      return await response.arrayBuffer();
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, 500 * 2 ** attempt));
    }
  }
  throw new Error(`Could not download ${url}: ${lastError.message}`);
}

/** Maps `items` with at most `limit` actions in flight, and stops at the first failure. */
async function mapConcurrently(items, limit, action) {
  const results = new Array(items.length);
  let next = 0;
  let failed = false;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length && !failed) {
      const index = next++;
      try {
        results[index] = await action(items[index]);
      } catch (error) {
        failed = true;
        throw error;
      }
    }
  });
  await Promise.all(workers);
  return results;
}

function readSource(uri) {
  if (crashed) return null;
  try {
    return server?.readSource(uri) ?? null;
  } catch (error) {
    fail(error);
    return null;
  }
}
