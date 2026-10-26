
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPOSITORY = "purefunctor/purescript-iris-website";
const ASSET = "playground-language-server.tar.gz";
const INPUTS = ["playground/language-server", "scripts/build-playground-language-server.mjs"];
const NOT_PUBLISHED = 3;

const root = new URL("..", import.meta.url).pathname;
const dist = join(root, "public/playground/language-server");

const git = (...args) => execFileSync("git", args, { cwd: root, encoding: "utf8" }).trim();
if (git("rev-parse", "--is-shallow-repository") === "true") {
  fail("The checkout is shallow, so it cannot find the server's last change. Run: git fetch --unshallow");
}
const revision = git("log", "-1", "--format=%H", "--", ...INPUTS);
if (!/^[0-9a-f]{40}$/.test(revision)) {
  fail("Git history has no commit that changed the language server. Fetch the full history.");
}
const tag = `playground-language-server-dev.${revision.slice(0, 12)}`;
if (process.argv.includes("--print-tag")) {
  console.log(tag);
  process.exit(0);
}

const url = `https://github.com/${REPOSITORY}/releases/download/${tag}/${ASSET}`;
const response = await fetch(url);
if (response.status === 404) {
  console.error(`The canary ${tag} for ${revision} is not published yet.`);
  process.exit(NOT_PUBLISHED);
}
if (!response.ok) fail(`${url} returned ${response.status}.`);

const scratch = mkdtempSync(join(tmpdir(), "playground-language-server-"));
try {
  const archive = join(scratch, ASSET);
  writeFileSync(archive, new Uint8Array(await response.arrayBuffer()));
  if (process.argv.includes("--verify")) {
    execFileSync(
      "gh",
      ["attestation", "verify", archive, "--repo", REPOSITORY, "--signer-workflow", `${REPOSITORY}/.github/workflows/playground-canary.yml`],
      { stdio: "inherit" },
    );
  }
  rmSync(dist, { recursive: true, force: true });
  mkdirSync(dist, { recursive: true });
  execFileSync("tar", ["-xzf", archive, "-C", dist], { stdio: "inherit" });
  const manifest = JSON.parse(readFileSync(join(dist, "manifest.json"), "utf8"));
  if (manifest.source !== tag) fail(`The archive was built for ${manifest.source}, not ${tag}.`);
  console.log(`Installed ${tag}: Iris ${manifest.iris} (${manifest.revision}).`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
