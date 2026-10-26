
import * as monaco from "monaco-editor/editor/editor.api.js";

export const LANGUAGE = "purescript";

const toPosition = (position) => ({ line: position.lineNumber - 1, character: position.column - 1 });

const toRange = (range) =>
  new monaco.Range(range.start.line + 1, range.start.character + 1, range.end.line + 1, range.end.character + 1);

const SEVERITY = {
  1: monaco.MarkerSeverity.Error,
  2: monaco.MarkerSeverity.Warning,
  3: monaco.MarkerSeverity.Info,
  4: monaco.MarkerSeverity.Hint,
};

const COMPLETION_KIND = (() => {
  const kinds = monaco.languages.CompletionItemKind;
  return [
    null, kinds.Text, kinds.Method, kinds.Function, kinds.Constructor, kinds.Field, kinds.Variable,
    kinds.Class, kinds.Interface, kinds.Module, kinds.Property, kinds.Unit, kinds.Value, kinds.Enum,
    kinds.Keyword, kinds.Snippet, kinds.Color, kinds.File, kinds.Reference, kinds.Folder,
    kinds.EnumMember, kinds.Constant, kinds.Struct, kinds.Event, kinds.Operator, kinds.TypeParameter,
  ];
})();

const markdown = (contents) => {
  const items = Array.isArray(contents) ? contents : [contents];
  return items.filter(Boolean).map((item) => {
    if (typeof item === "string") return { value: item };
    if ("language" in item) return { value: `\`\`\`${item.language}\n${item.value}\n\`\`\`` };
    return { value: item.value };
  });
};

const published = new Map();

const intersects = (a, b) =>
  !(
    a.end.line < b.start.line ||
    (a.end.line === b.start.line && a.end.character < b.start.character) ||
    b.end.line < a.start.line ||
    (b.end.line === a.start.line && b.end.character < a.start.character)
  );

const documentation = (value) => {
  if (!value) return undefined;
  return typeof value === "string" ? value : { value: value.value };
};

export function registerProviders({ client, ensureModel, capabilities }) {
  const disposables = [];
  const register = (enabled, create) => {
    if (enabled) disposables.push(create());
  };
  const request = (method, params, token) => {
    const controller = new AbortController();
    token?.onCancellationRequested(() => controller.abort());
    return client()
      .request(method, params, controller.signal)
      .catch((error) => {
        if ([-32800, -32801].includes(error.code)) return null;
        throw error;
      });
  };
  const textPosition = (model, position) => ({
    textDocument: { uri: model.uri.toString() },
    position: toPosition(position),
  });
  const locations = async (result) => {
    if (!result) return [];
    const items = Array.isArray(result) ? result : [result];
    const converted = items.map((item) =>
      "targetUri" in item
        ? { uri: item.targetUri, range: item.targetSelectionRange ?? item.targetRange }
        : item,
    );
    await Promise.all(converted.map((item) => ensureModel(item.uri)));
    return converted.map((item) => ({ uri: monaco.Uri.parse(item.uri), range: toRange(item.range) }));
  };
  const workspaceEdit = (edit) => {
    if (!edit) return null;
    const edits = [];
    for (const [uri, textEdits] of Object.entries(edit.changes ?? {})) {
      for (const textEdit of textEdits) {
        edits.push({ resource: monaco.Uri.parse(uri), textEdit: { range: toRange(textEdit.range), text: textEdit.newText }, versionId: undefined });
      }
    }
    for (const change of edit.documentChanges ?? []) {
      for (const textEdit of change.edits ?? []) {
        edits.push({
          resource: monaco.Uri.parse(change.textDocument.uri),
          textEdit: { range: toRange(textEdit.range), text: textEdit.newText },
          versionId: undefined,
        });
      }
    }
    return { edits };
  };

  register(capabilities.hoverProvider, () =>
    monaco.languages.registerHoverProvider(LANGUAGE, {
      async provideHover(model, position, token) {
        const hover = await request("textDocument/hover", textPosition(model, position), token);
        if (!hover) return null;
        return { contents: markdown(hover.contents), range: hover.range && toRange(hover.range) };
      },
    }),
  );

  register(capabilities.completionProvider, () =>
    monaco.languages.registerCompletionItemProvider(LANGUAGE, {
      triggerCharacters: capabilities.completionProvider.triggerCharacters,
      async provideCompletionItems(model, position, _context, token) {
        const result = await request("textDocument/completion", textPosition(model, position), token);
        if (!result) return { suggestions: [] };
        const items = Array.isArray(result) ? result : result.items;
        const word = model.getWordUntilPosition(position);
        const fallback = new monaco.Range(position.lineNumber, word.startColumn, position.lineNumber, word.endColumn);
        return {
          incomplete: !Array.isArray(result) && result.isIncomplete,
          suggestions: items.map((item) => completionItem(item, fallback)),
        };
      },
      resolveCompletionItem: capabilities.completionProvider.resolveProvider
        ? async (suggestion, token) => {
            const resolved = await request("completionItem/resolve", suggestion.lspItem, token);
            if (!resolved) return suggestion;
            const range = suggestion.range;
            return { ...completionItem(resolved, range), range };
          }
        : undefined,
    }),
  );

  register(capabilities.definitionProvider, () =>
    monaco.languages.registerDefinitionProvider(LANGUAGE, {
      async provideDefinition(model, position, token) {
        return locations(await request("textDocument/definition", textPosition(model, position), token));
      },
    }),
  );

  register(capabilities.referencesProvider, () =>
    monaco.languages.registerReferenceProvider(LANGUAGE, {
      async provideReferences(model, position, context, token) {
        const params = { ...textPosition(model, position), context };
        return locations(await request("textDocument/references", params, token));
      },
    }),
  );

  register(capabilities.documentHighlightProvider, () =>
    monaco.languages.registerDocumentHighlightProvider(LANGUAGE, {
      async provideDocumentHighlights(model, position, token) {
        const highlights = await request("textDocument/documentHighlight", textPosition(model, position), token);
        return (highlights ?? []).map((highlight) => ({
          range: toRange(highlight.range),
          kind: (highlight.kind ?? 1) - 1,
        }));
      },
    }),
  );

  register(capabilities.renameProvider, () =>
    monaco.languages.registerRenameProvider(LANGUAGE, {
      async provideRenameEdits(model, position, newName, token) {
        const params = { ...textPosition(model, position), newName };
        const edit = await request("textDocument/rename", params, token);
        return workspaceEdit(edit) ?? { edits: [], rejectReason: "Nothing to rename here" };
      },
      async resolveRenameLocation(model, position, token) {
        const result = await request("textDocument/prepareRename", textPosition(model, position), token).catch(
          (error) => ({ rejectReason: error.message }),
        );
        if (!result) return { range: null, text: "", rejectReason: "This symbol cannot be renamed" };
        if (result.rejectReason) return result;
        const range = "range" in result ? result.range : result;
        const converted = toRange(range);
        return { range: converted, text: result.placeholder ?? model.getValueInRange(converted) };
      },
    }),
  );

  register(capabilities.documentSymbolProvider, () =>
    monaco.languages.registerDocumentSymbolProvider(LANGUAGE, {
      async provideDocumentSymbols(model, token) {
        const symbols = await request("textDocument/documentSymbol", { textDocument: { uri: model.uri.toString() } }, token);
        const convert = (symbol) => {
          const range = toRange(symbol.range ?? symbol.location.range);
          return {
            name: symbol.name,
            detail: symbol.detail ?? "",
            kind: symbol.kind - 1,
            tags: [],
            range,
            selectionRange: symbol.selectionRange ? toRange(symbol.selectionRange) : range,
            children: (symbol.children ?? []).map(convert),
          };
        };
        return (symbols ?? []).map(convert);
      },
    }),
  );

  register(capabilities.documentFormattingProvider, () =>
    monaco.languages.registerDocumentFormattingEditProvider(LANGUAGE, {
      async provideDocumentFormattingEdits(model, options, token) {
        const params = {
          textDocument: { uri: model.uri.toString() },
          options: { tabSize: options.tabSize, insertSpaces: options.insertSpaces },
        };
        const edits = await request("textDocument/formatting", params, token);
        return (edits ?? []).map((edit) => ({ range: toRange(edit.range), text: edit.newText }));
      },
    }),
  );

  register(capabilities.codeActionProvider, () =>
    monaco.languages.registerCodeActionProvider(LANGUAGE, {
      async provideCodeActions(model, range, context, token) {
        const lspRange = { start: toPosition(range.getStartPosition()), end: toPosition(range.getEndPosition()) };
        const diagnostics = (published.get(model.uri.toString()) ?? []).filter((diagnostic) =>
          intersects(diagnostic.range, lspRange),
        );
        const params = {
          textDocument: { uri: model.uri.toString() },
          range: lspRange,
          context: { diagnostics, only: context.only ? [context.only] : undefined },
        };
        const actions = await request("textDocument/codeAction", params, token);
        return {
          actions: (actions ?? [])
            .filter((action) => action.edit)
            .map((action) => ({
              title: action.title,
              kind: action.kind,
              isPreferred: action.isPreferred,
              edit: workspaceEdit(action.edit),
            })),
          dispose() {},
        };
      },
    }),
  );

  const legend = capabilities.semanticTokensProvider?.legend;
  register(legend && capabilities.semanticTokensProvider.full, () =>
    monaco.languages.registerDocumentSemanticTokensProvider(LANGUAGE, {
      getLegend: () => legend,
      async provideDocumentSemanticTokens(model, _lastResultId, token) {
        const params = { textDocument: { uri: model.uri.toString() } };
        const tokens = await request("textDocument/semanticTokens/full", params, token);
        return tokens ? { data: new Uint32Array(tokens.data), resultId: tokens.resultId } : null;
      },
      releaseDocumentSemanticTokens() {},
    }),
  );

  return { dispose: () => disposables.forEach((disposable) => disposable.dispose()) };
}

function completionItem(item, fallback) {
  const edit = item.textEdit;
  const range = edit ? toRange(edit.range ?? edit.insert) : fallback;
  return {
    label: item.labelDetails ? { label: item.label, detail: item.labelDetails.detail, description: item.labelDetails.description } : item.label,
    kind: COMPLETION_KIND[item.kind] ?? monaco.languages.CompletionItemKind.Text,
    detail: item.detail,
    documentation: documentation(item.documentation),
    insertText: edit?.newText ?? item.insertText ?? item.label,
    filterText: item.filterText,
    sortText: item.sortText,
    additionalTextEdits: item.additionalTextEdits?.map((textEdit) => ({ range: toRange(textEdit.range), text: textEdit.newText })),
    range,
    lspItem: item,
  };
}

export function applyDiagnostics(params) {
  published.set(params.uri, params.diagnostics);
  const model = monaco.editor.getModel(monaco.Uri.parse(params.uri));
  const counts = { errors: 0, warnings: 0 };
  if (!model) return counts;
  const markers = params.diagnostics.map((diagnostic) => {
    if (diagnostic.severity === 1) counts.errors += 1;
    if (diagnostic.severity === 2) counts.warnings += 1;
    const range = toRange(diagnostic.range);
    return {
      severity: SEVERITY[diagnostic.severity ?? 1],
      message: diagnostic.message,
      code: diagnostic.code === undefined ? undefined : String(diagnostic.code),
      source: diagnostic.source,
      startLineNumber: range.startLineNumber,
      startColumn: range.startColumn,
      endLineNumber: range.endLineNumber,
      endColumn: range.endColumn,
    };
  });
  monaco.editor.setModelMarkers(model, "iris", markers);
  return counts;
}
