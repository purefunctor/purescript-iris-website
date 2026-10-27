module Website.Documentation.Formatting (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, item, link, list, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "Formatting" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.Formatting
    , intro:
        [ paragraph
            [ DOM.text "Iris includes a formatter for PureScript. Run "
            , inlineCode "iris format"
            , DOM.text
                " to format a Spago workspace, check formatting in CI, or format a file without a workspace. You can also format an open document in your editor."
            ]
        ]
    , sections
    }

sections :: Array Documentation.Section
sections =
  [ { id: "format-a-workspace"
    , title: "Format a workspace"
    , body:
        [ paragraph
            [ DOM.text "To format a workspace, run "
            , inlineCode "iris format"
            , DOM.text " from a directory inside it:"
            ]
        , Terminal.terminal [ { command: "iris format", output: "" } ]
        , paragraph
            [ DOM.text "Iris formats the "
            , inlineCode "src"
            , DOM.text " and "
            , inlineCode "test"
            , DOM.text
                " sources of every workspace package and writes changes in place. It skips downloaded dependencies in "
            , inlineCode ".spago"
            , DOM.text
                ", symlinks, nested workspaces, and files outside package sources. Formatting does not fetch dependencies or compile the workspace."
            ]
        ]
    }
  , { id: "check-formatting"
    , title: "Check formatting in CI"
    , body:
        [ paragraph
            [ DOM.text "To check formatting without changing files, add "
            , inlineCode "--check"
            , DOM.text ":"
            ]
        , Terminal.terminal [ { command: "iris format --check", output: "" } ]
        , paragraph
            [ DOM.text
                "Iris lists files that need formatting on standard error and exits with status 1. It exits with status 0 when all files are formatted, or status 2 for an error such as invalid source or options."
            ]
        ]
    }
  , { id: "format-a-single-file"
    , title: "Format a single file"
    , body:
        [ paragraph
            [ DOM.text "Use "
            , inlineCode "--file"
            , DOM.text
                " to format a single file. The formatted source code is printed to standard output."
            ]
        , Terminal.terminal [ { command: "iris format --file src/Main.purs", output: "" } ]
        , paragraph
            [ DOM.text "Use "
            , inlineCode "--write"
            , DOM.text " to update the file and "
            , inlineCode "--check"
            , DOM.text " to check it. You can repeat "
            , inlineCode "--file"
            , DOM.text " to select multiple files. "
            , inlineCode "--write"
            , DOM.text " cannot be used with "
            , inlineCode "--check"
            , DOM.text " and vice versa."
            ]
        , paragraph
            [ DOM.text "If you use "
            , inlineCode "--file"
            , DOM.text " for multiple distinct inputs, add either "
            , inlineCode "--write"
            , DOM.text " or "
            , inlineCode "--check"
            , DOM.text "."
            ]
        , Terminal.terminal
            [ { command: "iris format --write --file src/Main.purs --file test/Main.purs"
              , output: ""
              }
            ]
        , paragraph
            [ DOM.text "Use ", inlineCode "--file -", DOM.text " to read from standard input." ]
        , Terminal.terminal [ { command: "cat src/Main.purs | iris format --file -", output: "" } ]
        ]
    }
  , { id: "format-in-your-editor"
    , title: "Format in your editor"
    , body:
        [ paragraph
            [ DOM.text "When your editor is connected to the "
            , link "/docs/language-server/" "Iris language server"
            , DOM.text
                ", the editor's Format Document command formats the open document, including unsaved changes. It uses the same formatter as "
            , inlineCode "iris format"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "The editor sends "
            , inlineCode "tabSize"
            , DOM.text
                " to set the indentation width, which may differ from the command-line default of two spaces. Iris uses spaces even when "
            , inlineCode "insertSpaces"
            , DOM.text
                " is false. The editor preserves existing ASCII and Unicode spellings; it cannot enable the command-line "
            , inlineCode "--unicode"
            , DOM.text " option."
            ]
        , paragraph
            [ DOM.text
                "To match the command-line indentation in Visual Studio Code, add these settings for PureScript files to "
            , inlineCode "settings.json"
            , DOM.text ":"
            ]
        , CodeBlock.codeBlock
            { code:
                "{\n  \"[purescript]\": {\n    \"editor.tabSize\": 2,\n    \"editor.detectIndentation\": false\n  }\n}"
            , filename: "settings.json"
            , highlight: []
            , language: CodeBlock.JSON
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ DOM.text
                "The preferred line width defaults to 100 columns. LSP clients that send custom formatting options can set "
            , inlineCode "options.lineWidth"
            , DOM.text
                " to a positive integer. The Visual Studio Code extension does not send this option. Iris returns no edits for invalid source."
            ]
        ]
    }
  , { id: "options-and-layout"
    , title: "Options and layout"
    , body:
        [ paragraph
            [ DOM.text
                "On the command line, Iris defaults to a preferred width of 100 columns and two spaces per indentation level. Set these options on the command line:"
            ]
        , Terminal.terminal
            [ { command: "iris format --width 100 --indent 4 --unicode", output: "" } ]
        , list
            [ item
                [ inlineCode "--width COLUMNS"
                , DOM.text
                    " sets the preferred line width to a positive integer. Long comments and indivisible tokens can exceed it."
                ]
            , item
                [ inlineCode "--indent SPACES"
                , DOM.text " sets the indentation width from 1 to 65535 spaces."
                ]
            , item
                [ inlineCode "--unicode"
                , DOM.text " uses Unicode for built-in signatures, arrows, constraints, and "
                , inlineCode "forall"
                , DOM.text
                    ". Without it, Iris preserves the original spellings, including Unicode. The flag does not convert literals, comments, record labels, or user-defined operators."
                ]
            ]
        , paragraph
            [ DOM.text
                "Iris has no project-level formatter configuration. Use the same options when formatting and checking a project. Iris normalizes CRLF line endings in whitespace and comments to LF, so "
            , inlineCode "--check"
            , DOM.text " can report a CRLF file as needing formatting."
            ]
        , paragraph
            [ DOM.text "Iris sorts imports by module name, placing an open, unaliased "
            , inlineCode "import Prelude"
            , DOM.text
                " first. It does not sort or merge import lists. For example, given this file:"
            ]
        , CodeBlock.codeBlock
            { code:
                "module Main where\n\nimport Effect\nimport Prelude\n\nmain :: Effect Unit\nmain= pure unit"
            , filename: "src/Main.purs"
            , highlight: []
            , language: CodeBlock.PureScript
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph [ DOM.text "Iris produces:" ]
        , CodeBlock.codeBlock
            { code:
                "module Main where\n\nimport Prelude\n\nimport Effect\n\nmain :: Effect Unit\nmain = pure unit"
            , filename: "Formatted output"
            , highlight: []
            , language: CodeBlock.PureScript
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ DOM.text
                "The formatter wraps expressions, types, and lists to fit the preferred width. It preserves comments and section separation outside the import block. For the full layout conventions, see the "
            , link
                "https://github.com/purefunctor/purescript-iris/blob/main/documentation/formatting.md"
                "formatter reference"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text
                "Iris validates every result before writing any files. If a file has invalid source, Iris stops without writing any files. Writes are not atomic, so an interrupted or failed write can leave a file partially written or an earlier file already updated."
            ]
        ]
    }
  ]
