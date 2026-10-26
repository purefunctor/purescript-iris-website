
const KEYWORDS = "module where import data type newtype class instance derive let in case of if then else do ado forall foreign as hiding infixl infixr infix".split(" ");
const WORD = /[A-Za-z_][\w']*/g;

export class MockServer {
  #documents = new Map();
  #packages = new Map();
  #pending = [];

  handle(text) {
    const message = JSON.parse(text);
    const replies = [];
    if (message.id !== undefined && message.method) {
      try {
        replies.push({ jsonrpc: "2.0", id: message.id, result: this.#request(message.method, message.params ?? {}) });
      } catch (error) {
        replies.push({ jsonrpc: "2.0", id: message.id, error: { code: -32601, message: error.message } });
      }
    } else if (message.method) {
      replies.push(...this.#notification(message.method, message.params ?? {}));
    }
    return JSON.stringify(replies);
  }

  nextDiagnostics() {
    const uri = this.#pending.shift();
    if (uri === undefined) return undefined;
    const document = this.#documents.get(uri);
    if (!document) return this.nextDiagnostics();
    const diagnostics = [];
    document.text.split("\n").forEach((line, index) => {
      for (const [marker, severity, message] of [
        ["???", 1, "The mock language server marks ??? as an error."],
        ["TODO", 2, "The mock language server marks TODO as a warning."],
      ]) {
        const character = line.indexOf(marker);
        if (character === -1) continue;
        diagnostics.push({
          range: { start: { line: index, character }, end: { line: index, character: character + marker.length } },
          severity,
          source: "mock",
          message,
        });
      }
    });
    return JSON.stringify({
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: { uri, version: document.version, diagnostics },
    });
  }

  readSource(uri) {
    return this.#documents.get(uri)?.text ?? this.#packages.get(uri) ?? null;
  }

  #request(method, params) {
    switch (method) {
      case "initialize":
        return {
          serverInfo: { name: "iris-playground-mock-server" },
          capabilities: {
            hoverProvider: true,
            completionProvider: { triggerCharacters: ["."] },
            definitionProvider: true,
            documentSymbolProvider: true,
            documentFormattingProvider: true,
            textDocumentSync: { openClose: true, change: 2 },
          },
        };
      case "shutdown":
        return null;
      case "iris/setPackages":
        this.#packages.clear();
        for (const pkg of params.packages) {
          for (const file of pkg.files) this.#packages.set(`file:///packages/${pkg.name}/${file.path}`, file.text);
        }
        this.#pending.push(...this.#documents.keys());
        return { sources: this.#packages.size };
      case "textDocument/hover": {
        const word = this.#wordAt(params.textDocument.uri, params.position);
        return word && { contents: { kind: "markdown", value: `\`${word.text}\` · mock language server` }, range: word.range };
      }
      case "textDocument/completion": {
        const words = new Set(KEYWORDS);
        for (const document of this.#documents.values()) {
          for (const [word] of document.text.matchAll(WORD)) words.add(word);
        }
        return [...words].sort().map((label) => ({ label, kind: KEYWORDS.includes(label) ? 14 : 6 }));
      }
      case "textDocument/definition": {
        const word = this.#wordAt(params.textDocument.uri, params.position);
        if (!word) return null;
        for (const [uri, document] of this.#documents) {
          const lines = document.text.split("\n");
          const line = lines.findIndex((text) => text.startsWith(`${word.text} ::`) || text.startsWith(`${word.text} =`));
          if (line !== -1) {
            return { uri, range: { start: { line, character: 0 }, end: { line, character: word.text.length } } };
          }
        }
        return null;
      }
      case "textDocument/documentSymbol": {
        const document = this.#documents.get(params.textDocument.uri);
        if (!document) return [];
        return document.text.split("\n").flatMap((text, line) => {
          const match = /^([a-z_][\w']*) ::/.exec(text);
          if (!match) return [];
          const range = { start: { line, character: 0 }, end: { line, character: match[1].length } };
          return [{ name: match[1], kind: 12, range, selectionRange: range }];
        });
      }
      case "textDocument/formatting": {
        const document = this.#documents.get(params.textDocument.uri);
        if (!document) return null;
        const lines = document.text.split("\n");
        return lines.flatMap((text, line) => {
          const trimmed = text.trimEnd();
          if (trimmed === text) return [];
          return [{ range: { start: { line, character: trimmed.length }, end: { line, character: text.length } }, newText: "" }];
        });
      }
      case "iris/generated": {
        const document = this.#documents.get(params.uri);
        if (!document) throw new Error("No open document at this URI");
        const name = /^module\s+([\w.]+)/m.exec(document.text)?.[1] ?? "Main";
        return { status: "generated", path: `${name}/index.js`, map: null,
          text: "// Mock language server: no compiled JavaScript or source maps.\n// Build or download the Iris language server to inspect this module.\n" };
      }
      case "iris/emit": {
        const modules = [...this.#documents.keys()]
          .filter((uri) => uri.endsWith(".purs"))
          .map((uri) => {
            const name = /^module\s+([\w.]+)/m.exec(this.#documents.get(uri).text)?.[1] ?? "Main";
            return { name, uri, path: `${name}/index.js` };
          });
        const files = modules.map(({ name, path }) => ({
          path,
          text: `export const main = () => {\n  console.log(${JSON.stringify(`${name}.main ran on the mock language server.`)});\n  console.log("Build or download the Iris language server to compile programs.");\n};\n`,
        }));
        return { status: "emitted", modules, files };
      }
      default:
        throw new Error(`Unhandled method ${method}`);
    }
  }

  #notification(method, params) {
    switch (method) {
      case "textDocument/didOpen": {
        const { uri, text, version } = params.textDocument;
        this.#documents.set(uri, { text, version });
        this.#pending.push(uri);
        return [];
      }
      case "textDocument/didChange": {
        const { uri, version } = params.textDocument;
        const document = this.#documents.get(uri);
        if (!document) return [];
        for (const change of params.contentChanges) {
          document.text = change.range ? splice(document.text, change.range, change.text) : change.text;
        }
        document.version = version;
        this.#pending.push(uri);
        return [];
      }
      case "textDocument/didClose": {
        const { uri } = params.textDocument;
        this.#documents.delete(uri);
        return [{ jsonrpc: "2.0", method: "textDocument/publishDiagnostics", params: { uri, diagnostics: [] } }];
      }
      default:
        return [];
    }
  }

  #wordAt(uri, position) {
    const line = this.readSource(uri)?.split("\n")[position.line];
    if (line === undefined) return null;
    for (const match of line.matchAll(WORD)) {
      const start = match.index;
      const end = start + match[0].length;
      if (position.character >= start && position.character <= end) {
        return {
          text: match[0],
          range: { start: { line: position.line, character: start }, end: { line: position.line, character: end } },
        };
      }
    }
    return null;
  }
}

function splice(text, range, replacement) {
  const offset = ({ line, character }) => {
    let index = 0;
    for (let current = 0; current < line; current++) index = text.indexOf("\n", index) + 1;
    return index + character;
  };
  return text.slice(0, offset(range.start)) + replacement + text.slice(offset(range.end));
}
