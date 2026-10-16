module Website.Documentation.Formatting (component) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.Documentation as Documentation
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, link, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "Formatting" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.Formatting
    , intro:
        "Iris includes a code formatter for PureScript. It can be run from the command line, used to check formatting in CI, or invoked from your editor."
    , sections
    }

sections :: Array Documentation.Section
sections =
  [ { id: "format-a-workspace"
    , title: "Format a workspace"
    , body:
        [ paragraph
            [ DOM.text "To format an entire workspace, run "
            , inlineCode "iris format"
            , DOM.text " from any directory inside it:"
            ]
        , Terminal.terminal [ { command: "iris format", output: "" } ]
        , paragraph
            [ DOM.text "Iris formats the "
            , inlineCode "src"
            , DOM.text " and "
            , inlineCode "test"
            , DOM.text
                " directories of every package in the workspace and writes the changes in place. Downloaded dependencies in "
            , inlineCode ".spago"
            , DOM.text " are not formatted."
            ]
        ]
    }
  , { id: "check-formatting"
    , title: "Check formatting in CI"
    , body:
        [ paragraph
            [ DOM.text "To check formatting without modifying any files, for example in CI, add "
            , inlineCode "--check"
            , DOM.text ":"
            ]
        , Terminal.terminal [ { command: "iris format --check", output: "" } ]
        , paragraph
            [ DOM.text
                "If any files need formatting, Iris lists them and exits with status 1, which causes the CI job to fail."
            ]
        ]
    }
  , { id: "format-a-single-file"
    , title: "Format a single file"
    , body:
        [ paragraph
            [ DOM.text "To format one file, pass its path with "
            , inlineCode "--file"
            , DOM.text
                ". Iris prints the formatted code to standard output and does not modify the file:"
            ]
        , Terminal.terminal [ { command: "iris format --file src/Main.purs", output: "" } ]
        , paragraph
            [ DOM.text "Add "
            , inlineCode "--write"
            , DOM.text " to write the result back to the file."
            ]
        ]
    }
  , { id: "format-in-your-editor"
    , title: "Format in your editor"
    , body:
        [ paragraph
            [ DOM.text "When your editor is connected to the "
            , link "/docs/language-server/" "Iris language server"
            , DOM.text
                ", the editor's Format Document command formats the current file. It uses the same formatter as "
            , inlineCode "iris format"
            , DOM.text "."
            ]
        ]
    }
  , { id: "options-and-layout"
    , title: "Options and layout"
    , body:
        [ paragraph
            [ DOM.text "The formatter supports additional options, including "
            , inlineCode "--width"
            , DOM.text ", "
            , inlineCode "--indent"
            , DOM.text ", and "
            , inlineCode "--unicode"
            , DOM.text ". The "
            , link
                "https://github.com/purefunctor/purescript-iris/blob/main/documentation/formatting.md"
                "formatting guide"
            , DOM.text
                " in the compiler repository describes these options, as well as file selection, formatting from standard input, and the layout rules that the formatter follows."
            ]
        ]
    }
  ]
