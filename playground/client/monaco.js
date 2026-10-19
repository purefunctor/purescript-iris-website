// Monaco with only the editor features the playground uses, the PureScript grammar for syntax
// highlighting before the language server answers, and the site's colors.

import * as monaco from "monaco-editor/editor/editor.api.js";
import "monaco-editor/editor/browser/coreCommands.js";
import "monaco-editor/editor/browser/widget/codeEditor/codeEditorWidget.js";
import "monaco-editor/editor/contrib/bracketMatching/browser/bracketMatching.js";
import "monaco-editor/editor/contrib/clipboard/browser/clipboard.js";
import "monaco-editor/editor/contrib/codeAction/browser/codeActionContributions.js";
import "monaco-editor/editor/contrib/comment/browser/comment.js";
import "monaco-editor/editor/contrib/contextmenu/browser/contextmenu.js";
import "monaco-editor/editor/contrib/cursorUndo/browser/cursorUndo.js";
import "monaco-editor/editor/contrib/documentSymbols/browser/documentSymbols.js";
import "monaco-editor/editor/contrib/find/browser/findController.js";
import "monaco-editor/editor/contrib/folding/browser/folding.js";
import "monaco-editor/editor/contrib/format/browser/formatActions.js";
import "monaco-editor/editor/contrib/gotoError/browser/gotoError.js";
import "monaco-editor/editor/contrib/gotoSymbol/browser/goToCommands.js";
import "monaco-editor/editor/contrib/gotoSymbol/browser/link/goToDefinitionAtPosition.js";
import "monaco-editor/editor/contrib/hover/browser/hoverContribution.js";
import "monaco-editor/editor/contrib/indentation/browser/indentation.js";
import "monaco-editor/editor/contrib/linesOperations/browser/linesOperations.js";
import "monaco-editor/editor/contrib/multicursor/browser/multicursor.js";
import "monaco-editor/editor/contrib/readOnlyMessage/browser/contribution.js";
import "monaco-editor/editor/contrib/rename/browser/rename.js";
import "monaco-editor/editor/contrib/semanticTokens/browser/documentSemanticTokens.js";
import "monaco-editor/editor/contrib/smartSelect/browser/smartSelect.js";
import "monaco-editor/editor/contrib/snippet/browser/snippetController2.js";
import "monaco-editor/editor/contrib/suggest/browser/suggestController.js";
import "monaco-editor/editor/contrib/wordHighlighter/browser/wordHighlighter.js";
import "monaco-editor/editor/contrib/wordOperations/browser/wordOperations.js";
import "monaco-editor/editor/standalone/browser/quickAccess/standaloneCommandsQuickAccess.js";
import "monaco-editor/editor/standalone/browser/quickAccess/standaloneGotoLineQuickAccess.js";
import "monaco-editor/editor/standalone/browser/quickAccess/standaloneGotoSymbolQuickAccess.js";
import "monaco-editor/editor/standalone/browser/referenceSearch/standaloneReferenceSearch.js";
import "monaco-editor/editor/common/standaloneStrings.js";
import "monaco-editor/languages/definitions/javascript/register.js";
import { StandaloneServices } from "monaco-editor/editor/standalone/browser/standaloneServices.js";
import { IStorageService } from "monaco-editor/platform/storage/common/storage.js";
import EditorWorker from "monaco-editor/editor/editor.worker.js?worker";
import { LANGUAGE } from "./monaco-bridge.js";
import "./monaco.css";

self.MonacoEnvironment = { getWorker: () => new EditorWorker() };

export { monaco };

let configured = false;

/** Registers PureScript and the `iris` theme once, from colors computed at build time. */
export function configure(theme) {
  if (configured) return;
  configured = true;
  monaco.languages.register({ id: LANGUAGE, extensions: [".purs"], aliases: ["PureScript", "Iris"] });
  monaco.languages.setLanguageConfiguration(LANGUAGE, {
    comments: { lineComment: "--", blockComment: ["{-", "-}"] },
    brackets: [
      ["{", "}"],
      ["[", "]"],
      ["(", ")"],
    ],
    autoClosingPairs: [
      { open: "{", close: "}" },
      { open: "[", close: "]" },
      { open: "(", close: ")" },
      { open: '"', close: '"', notIn: ["string"] },
    ],
    surroundingPairs: [
      { open: "{", close: "}" },
      { open: "[", close: "]" },
      { open: "(", close: ")" },
      { open: '"', close: '"' },
    ],
    wordPattern: /[A-Za-z_][\w']*/,
    indentationRules: { increaseIndentPattern: /(\bwhere|\bdo|\bof|\blet|=|->)\s*$/, decreaseIndentPattern: /^\s*$/ },
  });
  monaco.languages.setMonarchTokensProvider(LANGUAGE, grammar);
  monaco.editor.defineTheme("iris", theme);
}

// Monaco gives the references view's preview 70% of its width, which leaves the list of
// references too narrow beside a sidebar. Readers can still drag the divider.
function widenReferences() {
  const storage = StandaloneServices.get(IStorageService);
  const key = "peekViewLayout";
  // Profile scope, machine target, as `ReferencesController` stores it.
  if (!storage.get(key, 0)) storage.store(key, JSON.stringify({ ratio: 0.5, heightInLines: 18 }), 0, 1);
}

export function createEditor(element, options) {
  // The context menu mounts beside the editor, outside `.monaco-editor`, and reads the theme's
  // colors from variables that Monaco also defines for `.monaco-component`.
  element.classList.add("monaco-component");
  const editor = monaco.editor.create(element, {
    theme: "iris",
    automaticLayout: true,
    fontFamily: '"Geist Mono Variable", ui-monospace, "SF Mono", Menlo, Consolas, monospace',
    fontSize: 14,
    lineHeight: 22,
    fontLigatures: false,
    minimap: { enabled: false },
    scrollBeyondLastLine: false,
    renderLineHighlight: "line",
    tabSize: 2,
    insertSpaces: true,
    detectIndentation: false,
    padding: { top: 16, bottom: 16 },
    "semanticHighlighting.enabled": true,
    fixedOverflowWidgets: true,
    stickyScroll: { enabled: false },
    ...options,
  });
  widenReferences();
  return editor;
}

const grammar = {
  defaultToken: "identifier",
  keywords: [
    "module", "where", "import", "data", "type", "newtype", "class", "instance", "derive", "let", "in",
    "case", "of", "if", "then", "else", "do", "ado", "forall", "foreign", "as", "hiding", "infixl",
    "infixr", "infix",
  ],
  operators: /[:!#$%&*+./<=>?@\\^|~-]+/,
  tokenizer: {
    root: [
      [/\{-/, "comment", "@comment"],
      [/--(?![:!#$%&*+./<=>?@\\^|~]).*$/, "comment"],
      [/"""/, "string", "@rawString"],
      [/"/, "string", "@string"],
      [/'(?:[^'\\]|\\.)'/, "string"],
      [/\b\d+(\.\d+)?([eE][+-]?\d+)?\b|\b0x[0-9a-fA-F]+\b/, "number"],
      [/[A-Z][\w']*(\.[A-Z][\w']*)*/, "type"],
      [/[a-z_][\w']*/, { cases: { "@keywords": "keyword", "@default": "identifier" } }],
      [/[(){}[\],;`]/, "delimiter"],
      [/@operators/, "operator"],
      [/\s+/, "white"],
    ],
    comment: [
      [/[^{-]+/, "comment"],
      [/\{-/, "comment", "@push"],
      [/-\}/, "comment", "@pop"],
      [/[{-]/, "comment"],
    ],
    string: [
      [/[^"\\]+/, "string"],
      [/\\./, "string"],
      [/"/, "string", "@pop"],
    ],
    rawString: [
      [/"""/, "string", "@pop"],
      [/[^"]+|"/, "string"],
    ],
  },
};
