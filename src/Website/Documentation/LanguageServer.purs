module Website.Documentation.LanguageServer (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Documentation.Prose (inlineCode, item, link, list, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "LanguageServer" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.LanguageServer
    , intro:
        [ paragraph
            [ DOM.text "Iris includes a language server for PureScript. Start it with "
            , inlineCode "iris lsp"
            , DOM.text
                ". It provides type information, completion, diagnostics, navigation, rename, and formatting through the Language Server Protocol (LSP)."
            ]
        , paragraph
            [ DOM.text
                "Install the Visual Studio Code extension to use it in your editor, or connect another editor with an LSP client. This page also describes the protocol and settings for developers building an integration."
            ]
        ]
    , sections
    }

sections :: Array Documentation.Section
sections =
  [ { id: "visual-studio-code"
    , title: "Visual Studio Code"
    , body:
        [ paragraph
            [ DOM.text "Install Iris and Spago as described in "
            , link "/docs/getting-started/" "Getting started"
            , DOM.text ". Then install the "
            , link
                "https://marketplace.visualstudio.com/items?itemName=purefunctor.purescript-analyzer"
                "Iris extension"
            , DOM.text
                " from the Visual Studio Marketplace. The extension starts the language server with the "
            , inlineCode "iris"
            , DOM.text " executable on your PATH."
            ]
        ]
    }
  , { id: "settings"
    , title: "Settings"
    , body:
        [ paragraph
            [ DOM.text
                "The Visual Studio Code extension uses the following settings. This example enables diagnostics as you type in "
            , inlineCode "settings.json"
            , DOM.text ":"
            ]
        , CodeBlock.codeBlock
            { code:
                "{\n  \"iris.client.serverPath\": \"\",\n  \"iris.server.diagnostics.onOpen\": null,\n  \"iris.server.diagnostics.onSave\": null,\n  \"iris.server.diagnostics.onChange\": true\n}"
            , filename: "settings.json"
            , highlight: []
            , language: CodeBlock.JSON
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ inlineCode "iris.client.serverPath"
            , DOM.text
                " selects the language server executable or command. When empty, the extension uses "
            , inlineCode "iris"
            , DOM.text " from your PATH."
            ]
        , paragraph
            [ DOM.text
                "Iris reports diagnostics when you open, close, or save a file, or when a file changes on disk. To report diagnostics as you type, set "
            , inlineCode "iris.server.diagnostics.onChange"
            , DOM.text " to "
            , inlineCode "true"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "The diagnostic settings default to "
            , inlineCode "null"
            , DOM.text ", which uses the Iris defaults: on open and save, but not on change. Set "
            , inlineCode "iris.server.diagnostics.onOpen"
            , DOM.text " or "
            , inlineCode "iris.server.diagnostics.onSave"
            , DOM.text " to "
            , inlineCode "false"
            , DOM.text " to disable that trigger."
            ]
        ]
    }
  , { id: "zed"
    , title: "Zed"
    , body:
        [ paragraph
            [ DOM.text "A community-maintained "
            , link "https://github.com/sectore/purescript-iris-zed" "Zed extension"
            , DOM.text " starts the language server in Zed. The "
            , link "https://github.com/sectore/purescript-iris-zed#readme" "README"
            , DOM.text " describes installation and configuration."
            ]
        ]
    }
  , { id: "other-editors"
    , title: "Other editors"
    , body:
        [ paragraph
            [ DOM.text "To connect another editor, configure its LSP client to start "
            , inlineCode "iris lsp --stdio"
            , DOM.text
                " for PureScript files. The server communicates over standard input and output."
            ]
        , paragraph
            [ DOM.text "Send the project folder in "
            , inlineCode "workspaceFolders"
            , DOM.text
                " when initializing the server. Iris uses only the first folder and does not support multi-root workspaces for now. If the first folder is missing or is not a file URI, Iris uses the server process's working directory. It does not use "
            , inlineCode "rootUri"
            , DOM.text " or "
            , inlineCode "rootPath"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "For an example integration, see the "
            , link "https://github.com/purefunctor/purescript-iris-vscode"
                "Visual Studio Code extension source"
            , DOM.text ". Run "
            , inlineCode "iris lsp --help"
            , DOM.text " to see the language server options."
            ]
        ]
    }
  , { id: "protocol-support"
    , title: "Protocol support"
    , body:
        [ paragraph [ DOM.text "Iris handles these LSP requests and notifications:" ]
        , list
            [ item
                [ DOM.text "Completion and hover: "
                , inlineCode "textDocument/completion"
                , DOM.text ", "
                , inlineCode "completionItem/resolve"
                , DOM.text ", and "
                , inlineCode "textDocument/hover"
                , DOM.text "."
                ]
            , item
                [ DOM.text "Navigation and rename: "
                , inlineCode "textDocument/definition"
                , DOM.text ", "
                , inlineCode "textDocument/references"
                , DOM.text ", "
                , inlineCode "textDocument/prepareRename"
                , DOM.text ", and "
                , inlineCode "textDocument/rename"
                , DOM.text "."
                ]
            , item
                [ DOM.text "Symbols and highlighting: "
                , inlineCode "textDocument/documentSymbol"
                , DOM.text ", "
                , inlineCode "workspace/symbol"
                , DOM.text ", "
                , inlineCode "textDocument/documentHighlight"
                , DOM.text ", and "
                , inlineCode "textDocument/semanticTokens/full"
                , DOM.text "."
                ]
            , item
                [ DOM.text "Formatting and quick fixes: "
                , inlineCode "textDocument/formatting"
                , DOM.text " and "
                , inlineCode "textDocument/codeAction"
                , DOM.text "."
                ]
            , item
                [ DOM.text "Document synchronization: "
                , inlineCode "textDocument/didOpen"
                , DOM.text ", "
                , inlineCode "textDocument/didChange"
                , DOM.text ", "
                , inlineCode "textDocument/didSave"
                , DOM.text ", and "
                , inlineCode "textDocument/didClose"
                , DOM.text
                    ". Iris advertises incremental changes and also accepts full-document replacements."
                ]
            , item
                [ DOM.text "File changes: "
                , inlineCode "workspace/didChangeWatchedFiles"
                , DOM.text "."
                ]
            ]
        , paragraph
            [ DOM.text "Iris handles file URIs ending in "
            , inlineCode ".purs"
            , DOM.text ", "
            , inlineCode ".js"
            , DOM.text ", or "
            , inlineCode ".jsx"
            , DOM.text ". It publishes diagnostics for PureScript sources with "
            , inlineCode "textDocument/publishDiagnostics"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "If the client supports dynamic registration for "
            , inlineCode "workspace/didChangeWatchedFiles"
            , DOM.text
                ", Iris registers watchers for those file types. Otherwise, the client must send file change notifications itself to keep Iris up to date."
            ]
        , paragraph
            [ DOM.text "Send "
            , inlineCode "initialized"
            , DOM.text " after initialization and "
            , inlineCode "shutdown"
            , DOM.text " before "
            , inlineCode "exit"
            , DOM.text ". The client can cancel requests with "
            , inlineCode "$/cancelRequest"
            , DOM.text ". It must handle "
            , inlineCode "window/showMessage"
            , DOM.text " and, when negotiated, "
            , inlineCode "client/registerCapability"
            , DOM.text ". If the client supports work-done progress, it must also handle "
            , inlineCode "window/workDoneProgress/create"
            , DOM.text " and "
            , inlineCode "$/progress"
            , DOM.text ". The client can cancel workspace preparation with "
            , inlineCode "window/workDoneProgress/cancel"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "Iris chooses a position encoding from the client's "
            , inlineCode "general.positionEncodings"
            , DOM.text
                ", preferring UTF-8, then UTF-16, then UTF-32. It defaults to UTF-16 and returns its choice in "
            , inlineCode "capabilities.positionEncoding"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "For formatting, "
            , inlineCode "options.tabSize"
            , DOM.text " sets the indentation width and the optional "
            , inlineCode "options.lineWidth"
            , DOM.text
                " sets the preferred line width as a positive integer. Iris uses spaces even when "
            , inlineCode "options.insertSpaces"
            , DOM.text " is false."
            ]
        ]
    }
  , { id: "configuration-updates"
    , title: "LSP client configuration"
    , body:
        [ paragraph
            [ DOM.text "For LSP client developers, the "
            , link
                "https://github.com/purefunctor/purescript-iris/blob/main/compiler-services/iris-configuration/configuration.schema.json"
                "configuration JSON Schema"
            , DOM.text " describes the "
            , inlineCode "iris.server"
            , DOM.text " settings. Iris rejects unrecognized fields, including "
            , inlineCode "$schema"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "To configure Iris, advertise "
            , inlineCode "workspace.configuration"
            , DOM.text " and respond to "
            , inlineCode "workspace/configuration"
            , DOM.text ". After the client sends "
            , inlineCode "initialized"
            , DOM.text ", Iris requests the "
            , inlineCode "iris.server"
            , DOM.text
                " section, scoped to the first workspace folder if present. Iris waits for the request to resolve before preparing the workspace. Without "
            , inlineCode "workspace.configuration"
            , DOM.text
                ", Iris uses the defaults and the client cannot change them. When the client sends "
            , inlineCode "workspace/didChangeConfiguration"
            , DOM.text ", Iris requests the section again and ignores the "
            , inlineCode "settings"
            , DOM.text " value in the notification."
            ]
        , paragraph
            [ DOM.text "Return the "
            , inlineCode "iris.server"
            , DOM.text " settings as the single item in the result array. A bare object or "
            , inlineCode "null"
            , DOM.text " is not a valid result. For example:"
            ]
        , CodeBlock.codeBlock
            { code:
                "[\n  {\n    \"diagnostics\": {\n      \"onOpen\": true,\n      \"onSave\": true,\n      \"onChange\": false\n    }\n  }\n]"
            , filename: "workspace/configuration result"
            , highlight: []
            , language: CodeBlock.JSON
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ DOM.text "Each response replaces the previous configuration. A missing or "
            , inlineCode "null"
            , DOM.text
                " field reverts to its default rather than keeping its previous value. A settings object of "
            , inlineCode "{}"
            , DOM.text " or "
            , inlineCode "null"
            , DOM.text " resets all settings."
            ]
        , paragraph
            [ DOM.text
                "If a response contains an unknown field or an invalid value, Iris reports an error in the editor and keeps the last valid configuration. If there is no valid configuration yet, Iris uses the defaults."
            ]
        ]
    }
  ]
