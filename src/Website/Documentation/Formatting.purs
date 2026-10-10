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
component = unsafePerformEffect $ Hooks.reactComponent "Formatting" \_ -> Hooks.do
  Hooks.useEffectOnce Documentation.configurePlatform
  pure
    $ Documentation.documentation
        { page: Documentation.Formatting
        , intro: "Format your PureScript sources from the command line, in CI, or in your editor."
        , sections
        }

sections :: Array Documentation.Section
sections =
  [ { id: "format-a-workspace"
    , title: "Format a workspace"
    , body:
        [ paragraph
            [ inlineCode "iris format"
            , DOM.text " formats every package’s "
            , inlineCode "src"
            , DOM.text " and "
            , inlineCode "test"
            , DOM.text " sources in the current Spago workspace in place:"
            ]
        , Terminal.terminal [ { command: "iris format", output: "" } ]
        , paragraph
            [ DOM.text "Use "
            , inlineCode "--check"
            , DOM.text
                " in CI to check formatting without changing files. It lists the files that need formatting and exits with status 1:"
            ]
        , Terminal.terminal [ { command: "iris format --check", output: "" } ]
        ]
    }
  , { id: "format-a-single-file"
    , title: "Format a single file"
    , body:
        [ paragraph
            [ DOM.text "Pass "
            , inlineCode "--file"
            , DOM.text " to print a file’s formatted output without writing it:"
            ]
        , Terminal.terminal [ { command: "iris format --file src/Main.purs", output: "" } ]
        ]
    }
  , { id: "format-in-your-editor"
    , title: "Format in your editor"
    , body:
        [ paragraph
            [ DOM.text "Editors can use the same formatter through "
            , DOM.strong {} "Format Document"
            , DOM.text ", which the "
            , link "/docs/language-server" "Iris language server"
            , DOM.text " provides."
            ]
        ]
    }
  , { id: "options-and-layout"
    , title: "Options and layout"
    , body:
        [ paragraph
            [ DOM.text "See the "
            , link
                "https://github.com/purefunctor/purescript-iris/blob/main/documentation/formatting.md"
                "formatting guide"
            , DOM.text " for file selection, standard input, "
            , inlineCode "--width"
            , DOM.text ", "
            , inlineCode "--indent"
            , DOM.text ", "
            , inlineCode "--unicode"
            , DOM.text ", and layout conventions."
            ]
        ]
    }
  ]
