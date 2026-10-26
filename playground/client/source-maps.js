import { TraceMap, decodedMappings, originalPositionFor } from "@jridgewell/trace-mapping";

// Source maps contain origin points, not AST ranges. Generated spans stop at the next segment
// (including unmapped segments), and never extend across a newline.
export function mappingIndex(map, javascript) {
  const trace = new TraceMap(map);
  const lines = javascript.split("\n");
  const segments = decodedMappings(trace).flatMap((line, row) => line.flatMap((segment, at) => {
    if (segment.length < 4) return [];
    return [{
      line: row + 1,
      start: segment[0] + 1,
      end: (line[at + 1]?.[0] ?? lines[row]?.length ?? segment[0]) + 1,
      source: trace.sources[segment[1]],
      sourceLine: segment[2] + 1,
      sourceColumn: segment[3] + 1,
      name: segment.length > 4 ? trace.names[segment[4]] : null,
    }];
  }));
  return { trace, segments };
}

// Source maps give points on the source side, and half-open spans on the generated side.
// A source caret previews its line; a selection includes only the origin points it covers.
export function matchingSegments(segments, side, selection) {
  const empty = selection.startLineNumber === selection.endLineNumber && selection.startColumn === selection.endColumn;
  return segments.filter((segment) => {
    const line = side === "source" ? segment.sourceLine : segment.line;
    const start = side === "source" ? segment.sourceColumn : segment.start;
    const end = side === "source" ? start + 1 : segment.end;
    if (line < selection.startLineNumber || line > selection.endLineNumber) return false;
    if (side === "source" && empty) return true;
    if (end <= start) return false;
    return (line !== selection.startLineNumber || end > selection.startColumn)
      && (line !== selection.endLineNumber || (empty ? start <= selection.endColumn : start < selection.endColumn));
  });
}

// Error.stack is not source-mapped by browsers. Keep every raw line, including FFI and browser
// frames, but give mapped project/package frames a source location the editor can navigate to.
export function stackFrames(text, maps, enabled) {
  return text.split("\n").map((raw) => {
    const match = /iris-playground:\/\/\/([^\s)]+):(\d+):(\d+)/.exec(raw);
    const plain = { text: raw, uri: "", line: 0, column: 0, mapped: false };
    if (!match) return plain;
    const [, path, line, column] = match;
    const trace = maps.get(path);
    const original = enabled && trace
      ? originalPositionFor(trace, { line: Number(line), column: Number(column) - 1 }) : null;
    if (!original?.source) return { ...plain, text: raw.replace(match[0], `${path}:${line}:${column}`) };
    const label = original.source.replace(/^file:\/\/\/project\//, "").replace(/^file:\/\/\//, "");
    return {
      text: `${original.name ? `${original.name} · ` : ""}${label}:${original.line}:${original.column + 1}`,
      uri: original.source, line: original.line, column: original.column + 1, mapped: true,
    };
  });
}
