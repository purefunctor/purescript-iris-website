// A small tokenizer for PureScript and JavaScript samples; returns lines of { kind, text } tokens.
const keywords = {
  purescript: new Set("module where import data type newtype class instance derive let in case of if then else do ado forall foreign as hiding infixl infixr infix".split(" ")),
  javascript: new Set("const let var function return if else for while import export from default new class extends async await try catch throw typeof true false null undefined this".split(" ")),
};

const patterns = {
  purescript: /(--[^\n]*)|(\{-[\s\S]*?-\})|("(?:\\.|[^"\\])*")|('(?:\\.|[^'\\])')|(\b\d+(?:\.\d+)?\b)|(\b[A-Z][\w']*(?:\.[A-Z][\w']*)*)|(\b[a-z_][\w']*)|(::|->|<-|=>|>>>|<<<|<=|>=|<>|<\$>|<\*>|>>=|==|#|\/=|&&|\|\||[=\\|$<>+\-*\/.@])|([()[\]{},;`])/g,
  javascript: /(\/\/[^\n]*)|(\/\*[\s\S]*?\*\/)|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)|(\b\d+(?:\.\d+)?\b)|(\b[A-Z][\w$]*)|(\b[a-z_$][\w$]*)|(=>|===|!==|==|&&|\|\||[=+\-*\/<>!?:.])|([()[\]{},;])/g,
};

function classify(language, match, source, end) {
  const text = match[0];
  if (language === "purescript") {
    if (match[1] || match[2]) return "comment";
    if (match[3] || match[4]) return "string";
    if (match[5]) return "number";
    if (match[6]) return "type";
    if (match[7]) {
      if (keywords.purescript.has(text)) return "keyword";
      const lineStart = source.lastIndexOf("\n", match.index - 1) + 1;
      return match.index === lineStart ? "function" : "text";
    }
    if (match[8]) return "operator";
    return "punct";
  }
  if (match[1] || match[2]) return "comment";
  if (match[3]) return "string";
  if (match[4]) return "number";
  if (match[5]) return "type";
  if (match[6]) return keywords.javascript.has(text) ? "keyword" : source[end] === "(" ? "function" : "text";
  if (match[7]) return "operator";
  return "punct";
}

export const tokenizeImpl = language => code => {
  const source = code.replace(/\n$/, "");
  const pattern = new RegExp(patterns[language].source, "g");
  const tokens = [];
  let last = 0;
  let match;
  while ((match = pattern.exec(source))) {
    if (match.index > last) tokens.push({ kind: "text", text: source.slice(last, match.index) });
    tokens.push({ kind: classify(language, match, source, pattern.lastIndex), text: match[0] });
    last = pattern.lastIndex;
  }
  if (last < source.length) tokens.push({ kind: "text", text: source.slice(last) });

  const lines = [[]];
  for (const { kind, text } of tokens) {
    text.split("\n").forEach((part, index) => {
      if (index > 0) lines.push([]);
      if (part) lines[lines.length - 1].push({ kind, text: part });
    });
  }
  return lines;
};
