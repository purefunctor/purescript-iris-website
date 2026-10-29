import assert from "node:assert/strict";
import { test } from "node:test";
import { mappingIndex, matchingSegments, stackFrames } from "./source-maps.js";

test("generated spans stop at unmapped regions and at line endings", () => {
  const { segments } = mappingIndex({
    version: 3, sources: ["src/Main.purs"], names: [],
    mappings: [[[2, 0, 12, 4], [6], [9, 0, 18, 2]], [], [[0, 0, 3, 1]]],
  }, "abcdefghijkl\nunmapped\nxy");
  assert.deepEqual(segments.map(({ line, start, end, sourceLine, sourceColumn }) =>
    [line, start, end, sourceLine, sourceColumn]), [[1, 3, 7, 13, 5], [1, 10, 13, 19, 3], [3, 1, 3, 4, 2]]);
});

test("linked selections respect segment ends, unmapped gaps and source columns", () => {
  const { segments } = mappingIndex({
    version: 3, sources: ["file:///project/src/Other.purs"], names: [],
    mappings: [[[2, 0, 4, 2], [4], [6, 0, 4, 12]], [[0, 0, 7, 1]]],
  }, "😀abcdefgh\nnext");
  const selection = (line, start, endLine = line, end = start) => ({
    startLineNumber: line, startColumn: start, endLineNumber: endLine, endColumn: end,
  });
  const matched = (side, range) => matchingSegments(segments, side, range).map((s) => [s.line, s.start]);
  assert.deepEqual(matched("generated", selection(1, 3)), [[1, 3]]);
  assert.deepEqual(matched("generated", selection(1, 5)), []);
  assert.deepEqual(matched("generated", selection(1, 7)), [[1, 7]]);
  assert.deepEqual(matched("generated", selection(1, 4, 2, 1)), [[1, 3], [1, 7]]);
  assert.deepEqual(matched("source", selection(5, 13, 5, 14)), [[1, 7]]);
  assert.deepEqual(matched("source", selection(5, 3, 5, 13)), [[1, 3]]);
  assert.deepEqual(matched("source", selection(5, 1)), [[1, 3], [1, 7]]);
});

test("runtime frames use each module's map and preserve unmapped and disabled locations", () => {
  const { trace } = mappingIndex({
    version: 3, sources: ["file:///project/src/Inventory.purs"], names: ["reserve"],
    mappings: [[[0], [5, 0, 8, 3, 0], [12]]],
  }, "abcdefghijklmnop");
  const maps = new Map([["Inventory/index.js", trace]]);
  const stack = "Error: sold out\n    at generated (iris-playground:///Inventory/index.js:1:6)\nreserve@iris-playground:///Inventory/index.js:1:7\n    at iris-playground:///Main/foreign.js:2:9\n    at iris-playground:///Inventory/index.js:1:13\n    at iris-playground:///Other/index.js:1:6";
  const frames = stackFrames(stack, maps, true);
  assert.deepEqual(frames[1], { text: "reserve · src/Inventory.purs:9:4", uri: "file:///project/src/Inventory.purs", line: 9, column: 4, mapped: true });
  assert.deepEqual(frames[2], frames[1]);
  assert.equal(frames[3].text, "    at Main/foreign.js:2:9");
  assert.deepEqual(frames.map((f) => f.mapped), [false, true, true, false, false, false]);
  assert.ok(stackFrames(stack, maps, false).every((f) => !f.mapped && f.uri === ""));
  assert.equal(stackFrames(stack, maps, false)[1].text, "    at generated (Inventory/index.js:1:6)");
});
