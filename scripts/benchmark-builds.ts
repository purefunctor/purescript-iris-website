#!/usr/bin/env bun

import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { delimiter, join, resolve } from "node:path";
import { parseArgs } from "node:util";

const { values: options } = parseArgs({
  options: {
    purs: { type: "string" },
    iris: { type: "string", default: "iris" },
    "package-set": { type: "string", default: "81.1.0" },
    directory: { type: "string", default: join(tmpdir(), "iris-benchmark-acme") },
    runs: { type: "string", default: "5" },
    edits: { type: "string", default: "20" },
    fresh: { type: "boolean", default: false },
  },
});
if (!options.purs) throw new Error("Pass --purs with the path to an official purs binary.");

const runs = Number(options.runs);
const edits = Number(options.edits);
const project = resolve(options.directory);
const iris = Bun.which(options.iris) ?? resolve(options.iris);

const pursDirectory = mkdtempSync(join(tmpdir(), "purs-"));
const purs = join(pursDirectory, "purs");
symlinkSync(Bun.which(options.purs) ?? resolve(options.purs), purs);
const env = { ...process.env, PATH: pursDirectory + delimiter + process.env.PATH };

function output(cmd: string[], cwd = project): string {
  const result = Bun.spawnSync({ cmd, cwd, env, stdout: "pipe", stderr: "pipe" });
  if (!result.success) throw new Error(`${cmd.join(" ")} failed:\n${result.stderr.toString()}`);
  return result.stdout.toString().trim();
}

function time(cmd: string[]): number {
  const start = performance.now();
  const result = Bun.spawnSync({ cmd, cwd: project, env, stdout: "ignore", stderr: "ignore" });
  const elapsed = (performance.now() - start) / 1000;
  if (!result.success) throw new Error(`${cmd.join(" ")} failed with exit code ${result.exitCode}`);
  return elapsed;
}

const pursVersion = output([purs, "--version"], tmpdir());
const pursVersionOnPath = output(["sh", "-c", "purs --version"], tmpdir());
if (pursVersionOnPath !== pursVersion) throw new Error(`Spago would run purs ${pursVersionOnPath}, not ${pursVersion}`);

if (options.fresh) rmSync(project, { recursive: true, force: true });
if (!existsSync(join(project, "spago.yaml"))) {
  console.error(`Setting up acme with package set ${options["package-set"]} in ${project}`);
  mkdirSync(project, { recursive: true });
  output(["spago", "init", "--name", "acme", "--package-set", options["package-set"]]);
  const packages = Object.keys(JSON.parse(output(["spago", "ls", "packages", "--json"]))).filter(name => name !== "acme");
  output(["spago", "install", ...packages]);
}

const main = join(project, "src/Main.purs");
const original = readFileSync(main, "utf8");
const literal = /"[^"\n]*"/.exec(original);
if (!literal) throw new Error("src/Main.purs needs a string literal to edit");
const edited = (tag: string) =>
  original.slice(0, literal.index + literal[0].length - 1) + ` ${tag}` + original.slice(literal.index + literal[0].length - 1);

const sources = output(["spago", "sources"]).split(/\s+/);
const tools: Record<string, (out: string) => string[]> = {
  "spago build": out => ["spago", "build", "--output", out],
  "purs compile": out => [purs, "compile", "--output", out, ...sources],
  "iris build": out => [iris, "build", "--output", out],
};
type Scenarios = { cold: number[]; noop: number[]; edit: number[] };
const results: Record<string, Scenarios> = {};
const fetches: number[] = [];
const outputs: string[] = [];
const rebuilds: { wall: number; reported: number }[] = [];
let initial = { wall: 0, reported: 0 };
let modules = 0;

try {
  for (let run = 0; run < runs; run++) {
    fetches.push(time(["spago", "fetch"]));
    for (const [tool, command] of Object.entries(tools)) {
      const out = join(project, "output-benchmark-" + tool.replace(" ", "-"));
      outputs.push(out);
      rmSync(out, { recursive: true, force: true });
      const scenarios = (results[tool] ??= { cold: [], noop: [], edit: [] });
      scenarios.cold.push(time(command(out)));
      if (tool === "iris build") modules = readdirSync(out).filter(name => existsSync(join(out, name, "index.js"))).length;
      scenarios.noop.push(time(command(out)));
      writeFileSync(main, edited(String(run)));
      scenarios.edit.push(time(command(out)));
      writeFileSync(main, original);
      time(command(out));
    }
  }

  const out = join(project, "output-benchmark-iris-watch");
  outputs.push(out);
  rmSync(out, { recursive: true, force: true });
  const report = /(Build|Rebuild) (succeeded|failed) in ([\d.]+) (ms|s)\b/;
  const start = performance.now();
  const watcher = Bun.spawn({
    cmd: ["sh", "-c", 'exec "$0" watch --output "$1" 2>&1', iris, out],
    cwd: project,
    env,
    stdout: "pipe",
  });
  const lines = (async function* () {
    const decoder = new TextDecoder();
    let buffer = "";
    for await (const chunk of watcher.stdout) {
      buffer += decoder.decode(chunk, { stream: true });
      const parts = buffer.split("\n");
      buffer = parts.pop() ?? "";
      for (const line of parts) yield { at: performance.now(), line };
    }
  })();
  const waitFor = async (kind: string) => {
    for (let next = await lines.next(); !next.done; next = await lines.next()) {
      const { at, line } = next.value;
      const match = report.exec(line);
      if (match?.[1] !== kind) continue;
      if (match[2] !== "succeeded") throw new Error(line);
      return { at, reported: Number(match[3]) / (match[4] === "ms" ? 1000 : 1) };
    }
    throw new Error(`iris watch exited before reporting a ${kind.toLowerCase()}`);
  };

  try {
    const built = await waitFor("Build");
    initial = { wall: (built.at - start) / 1000, reported: built.reported };
    for (let edit = 0; edit < edits; edit++) {
      await Bun.sleep(1500);
      writeFileSync(main, edited(`watch ${edit}`));
      const written = performance.now();
      const rebuilt = await waitFor("Rebuild");
      rebuilds.push({ wall: (rebuilt.at - written) / 1000, reported: rebuilt.reported });
    }
  } finally {
    writeFileSync(main, original);
    watcher.kill();
    await watcher.exited;
  }
} finally {
  writeFileSync(main, original);
  for (const out of outputs) rmSync(out, { recursive: true, force: true });
  rmSync(pursDirectory, { recursive: true, force: true });
}

const round = (value: number) => Math.round(value * 1000) / 1000;
const summary = (values: number[]) => {
  const sorted = [...values].sort((a, b) => a - b);
  const middle = sorted.length / 2;
  const median = sorted.length % 2 ? sorted[Math.floor(middle)] : (sorted[middle - 1] + sorted[middle]) / 2;
  return { median: round(median), min: round(sorted[0]), max: round(sorted[sorted.length - 1]) };
};

console.log(
  JSON.stringify(
    {
      purs: pursVersion,
      iris: output([iris, "--version"]),
      packageSet: options["package-set"],
      modules,
      runs,
      oneShot: {
        ...Object.fromEntries(
          Object.entries(results).map(([tool, scenarios]) => [
            tool,
            { cold: summary(scenarios.cold), noop: summary(scenarios.noop), edit: summary(scenarios.edit) },
          ]),
        ),
        "spago fetch": { noop: summary(fetches) },
      },
      irisWatch: {
        initial: { wall: round(initial.wall), reported: round(initial.reported) },
        edit: { wall: summary(rebuilds.map(r => r.wall)), reported: summary(rebuilds.map(r => r.reported)) },
      },
    },
    null,
    2,
  ),
);
