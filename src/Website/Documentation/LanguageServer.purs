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
            "Iris includes a language server that provides types, completion, and error reporting for PureScript in your editor. It is available in Visual Studio Code through the Iris extension and in any other editor that supports the Language Server Protocol (LSP)."
        , sections
        }

sections :: Array Documentation.Section
sections =
  [ { id: "editor-features"
    , title: "Editor features"
    , body:
        [ paragraph
            [ DOM.text
                "Hovering over a name shows its type, including types inferred by Iris. Completion suggests names from your project and its dependencies, and adds the matching import when you select one."
            ]
        , paragraph
            [ DOM.text
                "The language server also supports go to definition, find references, and rename across the workspace. Rename takes scope into account, so it does not change unrelated names that are spelled the same way."
            ]
        , paragraph
            [ DOM.text
                "Errors and warnings are reported as diagnostics. Iris also supports semantic highlighting, document highlights, document and workspace symbols, and suggestions for filling in typed holes such as "
            , inlineCode "?value"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "The "
            , link "/#editor" "editor demos on the home page"
            , DOM.text " show these features in Visual Studio Code."
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
                " from the Visual Studio Marketplace. The extension starts the language server with the "
            , inlineCode "iris"
            , DOM.text
                " executable on your PATH, so no further configuration is required if you followed "
            , link "/docs/getting-started/" "Getting started"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "To use a different executable, set "
            , inlineCode "iris.client.serverPath"
            , DOM.text " to its path."
            ]
        ]
    }
  , { id: "other-editors"
    , title: "Other editors"
    , body:
        [ paragraph
            [ DOM.text
                "Any editor with an LSP client can use the Iris language server. Configure the client to start "
            , inlineCode "iris lsp --stdio"
            , DOM.text " for PureScript files."
            ]
        , paragraph
            [ DOM.text "The "
            , inlineCode "lsp"
            , DOM.text " subcommand is required. Running "
            , inlineCode "iris"
            , DOM.text
                " without it does not start the language server, and language server options must follow "
            , inlineCode "lsp"
            , DOM.text ". Run "
            , inlineCode "iris lsp --help"
            , DOM.text " to list the available options."
            ]
        ]
    }
  , { id: "workspace-preparation"
    , title: "Workspace preparation"
    , body:
        [ paragraph
            [ DOM.text
                "When the language server starts, it prepares the Spago workspace before providing any features. It runs "
            , inlineCode "spago fetch"
            , DOM.text " in the workspace root to download missing dependencies, and then reads "
            , inlineCode "spago.yaml"
            , DOM.text " and each package's manifest to find your source files. Iris uses the "
            , inlineCode "spago.lock"
            , DOM.text " file written by the fetch to select the exact packages in "
            , inlineCode ".spago"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "To find Spago, Iris checks the "
            , inlineCode "IRIS_SPAGO"
            , DOM.text " environment variable first, then "
            , inlineCode "node_modules/.bin"
            , DOM.text " in the workspace root, and finally your PATH."
            ]
        , paragraph
            [ DOM.text
                "Preparation can take some time, particularly on the first run, when Spago downloads packages. During preparation, Iris records the files you open and edit, and applies those changes in order once the workspace is ready. Requests received before then, such as hover requests, fail with a "
            , inlineCode "ContentModified"
            , DOM.text
                " error and the message \"Workspace is loading\". Editors that retry requests after this error will resend them."
            ]
        , paragraph
            [ DOM.text
                "If preparation fails, Iris reports the error in your editor and does not provide features for the project. Iris does not retry preparation automatically. Run "
            , inlineCode "spago fetch"
            , DOM.text
                " to see the underlying error, fix the problem, and then restart the language server."
            ]
        ]
    }
  , { id: "settings"
    , title: "Settings"
    , body:
        [ paragraph
            [ DOM.text
                "The language server provides settings that control when diagnostics are reported. All settings are optional. The defaults are:"
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
                "By default, Iris reports diagnostics for a file when it is opened and when it is saved, but not while you type. Set "
            , inlineCode "onChange"
            , DOM.text " to "
            , inlineCode "true"
            , DOM.text " to update diagnostics as you type."
            ]
        , paragraph
            [ DOM.text
                "These settings apply only to opening, saving, and editing. Iris also updates diagnostics in other cases, such as when a file is closed or changes on disk."
            ]
        , paragraph
            [ DOM.text "In Visual Studio Code, the settings are named "
            , inlineCode "iris.server.diagnostics.onOpen"
            , DOM.text ", "
            , inlineCode "iris.server.diagnostics.onSave"
            , DOM.text ", and "
            , inlineCode "iris.server.diagnostics.onChange"
            , DOM.text ". In other editors, place them in the "
            , inlineCode "iris.server"
            , DOM.text " section of your LSP client's configuration."
            ]
        , paragraph
            [ DOM.text "Editors that validate settings can use the "
            , link
                "https://github.com/purefunctor/purescript-iris/blob/main/compiler-services/iris-configuration/configuration.schema.json"
                "configuration JSON Schema"
            , DOM.text ". Associate the schema through your editor's settings instead of adding a "
            , inlineCode "$schema"
            , DOM.text " field, because Iris rejects unrecognized fields."
            ]
        ]
    }
  , { id: "configuration-updates"
    , title: "Configuration updates"
    , body:
        [ paragraph
            [ DOM.text
                "This section describes how Iris reads its settings over LSP. It is mainly relevant when configuring an LSP client manually."
            ]
        , paragraph
            [ DOM.text "Iris requests the "
            , inlineCode "iris.server"
            , DOM.text " section with "
            , inlineCode "workspace/configuration"
            , DOM.text
                " once the server has initialized, using the first workspace folder. If your client does not support that request, Iris uses the defaults. When the client sends "
            , inlineCode "workspace/didChangeConfiguration"
            , DOM.text ", Iris requests the section again and ignores the "
            , inlineCode "settings"
            , DOM.text " value in the notification."
            ]
        , paragraph
            [ DOM.text "Each response replaces the previous configuration. A missing or "
            , inlineCode "null"
            , DOM.text
                " field reverts to its default rather than keeping its previous value, and a response of "
            , inlineCode "{}"
            , DOM.text " or "
            , inlineCode "null"
            , DOM.text " resets every setting."
            ]
        , paragraph
            [ DOM.text
                "If a response contains an unknown field or an invalid value, Iris reports an error in the editor and keeps the last valid configuration."
            ]
        ]
    }
  ]
