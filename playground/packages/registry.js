
const REGISTRY = "https://packages.registry.purescript.org";

const MAX_UNPACKED_BYTES = 64 * 1024 * 1024;
const MAX_ENTRIES = 20_000;

export function resolveClosure(index, roots) {
  const ordered = [];
  const visited = new Set();
  const visit = (name, path) => {
    if (visited.has(name)) return;
    const entry = index.packages[name];
    if (!entry) throw new Error(`${name} is not in package set ${index.packageSet.version}`);
    if (path.includes(name)) throw new Error(`Dependency cycle: ${[...path, name].join(" -> ")}`);
    for (const dependency of entry.dependencies) visit(dependency, [...path, name]);
    visited.add(name);
    ordered.push({ name, ...entry });
  };
  for (const root of roots) visit(root, []);
  return ordered;
}

export function archiveUrl(entry) {
  return `${REGISTRY}/${entry.name}/${entry.version}.tar.gz`;
}

export async function unpackPackage(entry, archive) {
  const bytes = new Uint8Array(archive);
  if (bytes.byteLength !== entry.bytes) {
    throw new Error(`${entry.name}@${entry.version}: expected ${entry.bytes} bytes, got ${bytes.byteLength}`);
  }
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  const integrity = `sha256-${base64(digest)}`;
  if (integrity !== entry.integrity) {
    throw new Error(`${entry.name}@${entry.version}: integrity mismatch`);
  }
  const tar = await gunzip(bytes);
  const files = [];
  const decoder = new TextDecoder("utf-8", { fatal: true });
  for (const { path, data } of readTar(tar)) {
    const relative = withoutArchiveRoot(path);
    if (!/^src\/.+\.(purs|js|jsx)$/.test(relative) || relative.split("/").includes("..")) continue;
    files.push({ path: relative, text: decoder.decode(data) });
  }
  return files;
}

function withoutArchiveRoot(path) {
  return path.slice(path.indexOf("/") + 1);
}

async function gunzip(bytes) {
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"));
  const reader = stream.getReader();
  const chunks = [];
  let length = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > MAX_UNPACKED_BYTES) throw new Error("Archive unpacks to too many bytes");
    chunks.push(value);
  }
  const result = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return result;
}

function* readTar(bytes) {
  const decoder = new TextDecoder();
  const field = (offset, length) => {
    const raw = bytes.subarray(offset, offset + length);
    const end = raw.indexOf(0);
    return decoder.decode(end === -1 ? raw : raw.subarray(0, end));
  };
  let offset = 0;
  let entries = 0;
  let longName;
  while (offset + 512 <= bytes.byteLength) {
    if (bytes.subarray(offset, offset + 512).every((byte) => byte === 0)) break;
    if (++entries > MAX_ENTRIES) throw new Error("Archive has too many entries");
    const size = parseInt(field(offset + 124, 12).trim() || "0", 8);
    const type = String.fromCharCode(bytes[offset + 156] || 0x30);
    const prefix = field(offset + 345, 155);
    const name = longName ?? (prefix ? `${prefix}/${field(offset, 100)}` : field(offset, 100));
    const data = bytes.subarray(offset + 512, offset + 512 + size);
    offset += 512 + Math.ceil(size / 512) * 512;
    longName = undefined;
    if (type === "L") {
      longName = field(offset - Math.ceil(size / 512) * 512, size);
    } else if (type === "x") {
      const match = /\d+ path=([^\n]*)\n/.exec(decoder.decode(data));
      if (match) longName = match[1];
    } else if (type === "0" || type === "\0") {
      yield { path: name, data };
    }
  }
}

function base64(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}
