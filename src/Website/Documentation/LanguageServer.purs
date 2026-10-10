module Website.Documentation.LanguageServer (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Documentation.Prose (inlineCode, link, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "LanguageServer" \_ -> Hooks.do
  Hooks.useEffectOnce Documentation.configurePlatform
  pure
    $ Documentation.documentation
        { page: Documentation.LanguageServer
        , intro:
            "Iris includes a language server for code intelligence in your editor. Use the Visual Studio Code extension, or connect any editor that supports the Language Server Protocol."
        , sections
        }

sections :: Array Documentation.Section
sections =
  [ { id: "editor-features"
    , title: "Editor features"
    , body:
        [ paragraph
            [ DOM.text
                "The language server provides hover information with inferred types, completion with automatic imports, go to definition, find references, scope-aware rename, document and workspace symbols, document highlights, semantic highlighting, typed-hole suggestions, and diagnostics."
            ]
        , paragraph
            [ link "/#editor" "Watch each feature in Visual Studio Code"
            , DOM.text " on the home page."
            ]
        ]
    }
  , { id: "visual-studio-code"
    , title: "Visual Studio Code"
    , body:
        [ paragraph
            [ DOM.text "Install the "
            , link
                "https://marketplace.visualstudio.com/items?itemName=purefunctor.purescript-analyzer"
                "Iris extension"
            , DOM.text
                " from the Visual Studio Marketplace. It starts the language server with the "
            , inlineCode "iris"
            , DOM.text " executable on your "
            , inlineCode "PATH"
            , DOM.text ". To use a particular executable instead, set "
            , inlineCode "iris.client.serverPath"
            , DOM.text "."
            ]
        ]
    }
  , { id: "other-editors"
    , title: "Other editors"
    , body:
        [ paragraph
            [ DOM.text "Configure your editor’s LSP client to start "
            , inlineCode "iris lsp --stdio"
            , DOM.text " for PureScript files. The "
            , inlineCode "lsp"
            , DOM.text " subcommand is required: "
            , inlineCode "iris"
            , DOM.text
                " alone no longer starts the server, and language-server options must follow "
            , inlineCode "lsp"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "Run "
            , inlineCode "iris lsp --help"
            , DOM.text " to see the available options."
            ]
        ]
    }
  , { id: "settings"
    , title: "Settings"
    , body:
        [ paragraph
            [ DOM.text "Editors that advertise the LSP "
            , inlineCode "workspace.configuration"
            , DOM.text " capability can provide settings in the "
            , inlineCode "iris.server"
            , DOM.text " configuration section. All settings are optional. The defaults are:"
            ]
        , CodeBlock.codeBlock
            { code:
                "{\n  \"diagnostics\": {\n    \"onOpen\": true,\n    \"onSave\": true,\n    \"onChange\": false\n  }\n}"
            , filename: "iris.server"
            , highlight: []
            , language: CodeBlock.JSON
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ DOM.text
                "The diagnostic settings publish diagnostics when a document opens, when it’s saved, and as it changes before saving. They control those document-event triggers, not all diagnostic publishing."
            ]
        , paragraph
            [ DOM.text "In Visual Studio Code, these are the "
            , inlineCode "iris.server.diagnostics.onOpen"
            , DOM.text ", "
            , inlineCode "iris.server.diagnostics.onSave"
            , DOM.text ", and "
            , inlineCode "iris.server.diagnostics.onChange"
            , DOM.text " settings."
            ]
        , paragraph
            [ DOM.text "Use the "
            , link
                "https://github.com/purefunctor/purescript-iris/blob/main/compiler-services/iris-configuration/configuration.schema.json"
                "configuration JSON Schema"
            , DOM.text
                " for editor validation. Associate it through your editor’s settings rather than adding a "
            , inlineCode "$schema"
            , DOM.text " property."
            ]
        ]
    }
  , { id: "configuration-updates"
    , title: "Configuration updates"
    , body:
        [ paragraph
            [ DOM.text "Iris requests the "
            , inlineCode "iris.server"
            , DOM.text
                " section for the first workspace folder after initialization, and again after each "
            , inlineCode "workspace/didChangeConfiguration"
            , DOM.text " notification. The notification’s "
            , inlineCode "settings"
            , DOM.text " value is only an invalidation signal."
            ]
        , paragraph
            [ DOM.text "Each response is a complete configuration. Missing or "
            , inlineCode "null"
            , DOM.text
                " fields take their defaults rather than values from the preceding response, and "
            , inlineCode "{}"
            , DOM.text " or a top-level "
            , inlineCode "null"
            , DOM.text " selects every default."
            ]
        , paragraph
            [ DOM.text
                "Unknown fields and invalid values are shown in the editor, and an invalid update leaves the last valid configuration active. Clients without workspace-configuration support use the defaults."
            ]
        ]
    }
  , { id: "workspace-preparation"
    , title: "Workspace preparation"
    , body:
        [ paragraph
            [ DOM.text
                "Iris prepares the Spago workspace during startup, before serving analysis. It runs "
            , inlineCode "spago fetch"
            , DOM.text " in the workspace root, then discovers sources from "
            , inlineCode "spago.yaml"
            , DOM.text
                " and package manifests, using the resolution written by that fetch to select fetched "
            , inlineCode ".spago"
            , DOM.text " checkouts exactly."
            ]
        , paragraph
            [ DOM.text "To find Spago, Iris uses the executable named by "
            , inlineCode "IRIS_SPAGO"
            , DOM.text ", then "
            , inlineCode "<workspace root>/node_modules/.bin"
            , DOM.text ", then your "
            , inlineCode "PATH"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text
                "Preparation runs off the protocol loop, so the server keeps accepting document notifications and replays them in order once the workspace is ready. Requests made before preparation completes are rejected with "
            , inlineCode "ContentModified"
            , DOM.text " and the message "
            , inlineCode "Workspace is loading"
            , DOM.text ", so clients that retry stale requests can try again."
            ]
        , paragraph
            [ DOM.text
                "If preparation fails, Iris reports the failure in the editor and doesn’t serve analysis from the partially installed project. Correct the project, for example by running "
            , inlineCode "spago fetch"
            , DOM.text ", then restart Iris. Iris doesn’t retry preparation automatically."
            ]
        ]
    }
  ]
