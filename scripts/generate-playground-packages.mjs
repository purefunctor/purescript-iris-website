
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const cache = join(root, "playground/.cache");
const output = join(root, "playground/packages/index.json");

const manifest = readFileSync(join(root, "playground/language-server/Cargo.toml"), "utf8");
const tags = new Set(manifest.match(/tag = "[^"]+"/g).map((tag) => tag.slice(7, -1)));
if (tags.size !== 1) throw new Error(`Expected one Iris tag, found ${[...tags].join(", ")}`);
const [irisTag] = tags;

const presets = await Promise.all(
  ["core", "acme"].map(async (preset) => {
    const url = `https://raw.githubusercontent.com/purefunctor/purescript-iris/${irisTag}/tests-compatibility/purescript-${preset}.txt`;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`${url}: ${response.status}`);
    return (await response.text()).split("\n").map((line) => line.trim()).filter(Boolean);
  }),
);

const registry = clone("registry", "https://github.com/purescript/registry.git");
const registryIndex = clone("registry-index", "https://github.com/purescript/registry-index.git");

const packageSetVersion = readdirSync(join(registry, "package-sets"))
  .filter((name) => name.endsWith(".json"))
  .map((name) => name.slice(0, -5))
  .sort(compareVersions)
  .at(-1);
const packageSet = readJson(join(registry, "package-sets", `${packageSetVersion}.json`));

const packages = {};
const missing = [];
const queue = [...new Set(presets.flat())];
while (queue.length > 0) {
  const name = queue.shift();
  if (packages[name] || missing.includes(name)) continue;
  const version = packageSet.packages[name];
  if (!version) {
    missing.push(name);
    continue;
  }
  const manifest = readFileSync(join(registryIndex, indexPath(name)), "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => JSON.parse(line))
    .find((manifest) => manifest.version === version);
  if (!manifest) throw new Error(`${name}@${version} is missing from the Registry index`);
  const metadata = readJson(join(registry, "metadata", `${name}.json`));
  const published = metadata.published[version];
  if (!published) throw new Error(`${name}@${version} has no published metadata`);
  const dependencies = Object.keys(manifest.dependencies ?? {}).sort();
  const owner = metadata.location.githubOwner ?? null;
  packages[name] = { version, owner, dependencies, integrity: published.hash, bytes: published.bytes };
  queue.push(...dependencies);
}

const sorted = Object.fromEntries(Object.entries(packages).sort(([a], [b]) => a.localeCompare(b)));
const index = {
  iris: irisTag,
  packageSet: { version: packageSet.version, compiler: packageSet.compiler },
  packages: sorted,
};
writeFileSync(output, `${JSON.stringify(index, null, 2)}\n`);
const bytes = Object.values(sorted).reduce((total, entry) => total + entry.bytes, 0);
console.log(
  `Wrote ${Object.keys(sorted).length} packages from package set ${packageSet.version} ` +
    `(${(bytes / 1024 / 1024).toFixed(1)} MiB of archives) for Iris ${irisTag}.`,
);
if (missing.length > 0) console.log(`Not in the package set: ${missing.sort().join(", ")}`);

function clone(name, url) {
  const directory = join(cache, name);
  if (existsSync(directory)) {
    execFileSync("git", ["-C", directory, "pull", "--quiet", "--ff-only"], { stdio: "inherit" });
  } else {
    mkdirSync(cache, { recursive: true });
    execFileSync("git", ["clone", "--quiet", "--depth", "1", url, directory], { stdio: "inherit" });
  }
  return directory;
}

function indexPath(name) {
  if (name.length <= 2) return join(String(name.length), name);
  if (name.length === 3) return join("3", name[0], name);
  return join(name.slice(0, 2), name.slice(2, 4), name);
}

function compareVersions(left, right) {
  const a = left.split(".").map(Number);
  const b = right.split(".").map(Number);
  for (let index = 0; index < 3; index++) {
    if (a[index] !== b[index]) return a[index] - b[index];
  }
  return 0;
}

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}
