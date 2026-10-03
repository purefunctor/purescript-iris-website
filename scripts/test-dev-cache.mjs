import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFile } from "node:fs/promises";

// Requires agent-browser and a running dev server. Runs a production build
// while the dev server and its browser module graph remain alive.
const base = process.argv[2] || "http://localhost:4321";
const session = `dev-cache-${process.pid}`;
const browser = (...args) => execFileSync("agent-browser", ["--session", session, ...args], {
  encoding: "utf8",
  maxBuffer: 5 * 1024 * 1024,
});
const metadata = () => readFile("node_modules/.vite-dev/deps/_metadata.json", "utf8");
const checkPage = async () => {
  const response = await fetch(base);
  assert.equal(response.status, 200, "HTTP status");
  await response.text();
  browser("open", base);
  browser("wait", "--fn", '!!document.querySelector("astro-island:not([ssr])")');
  assert.equal(browser("eval", '!!document.querySelector("astro-error-overlay, vite-error-overlay")').trim(), "false");
};

try {
  await checkPage();
  const before = await metadata();
  execFileSync("pnpm", ["exec", "astro", "build"], { stdio: "inherit" });
  assert.deepEqual(await metadata(), before, "production build must preserve live dev prebundles");
  await checkPage();
  assert.deepEqual(await metadata(), before, "reloading must not discover new dependencies");
  const errors = browser("errors").trim();
  assert.ok(!errors || errors === "No errors", errors);
  console.log("Dev cache regression passed: build preserves prebundles and the landing page hydrates.");
} finally {
  browser("close");
}
