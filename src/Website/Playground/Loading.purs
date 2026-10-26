module Website.Playground.Loading (loading) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import React.Basic.Events (handler_)
import Website.Components.CodeBlock (Language(..), Surface(..), codeBlock)
import Website.Components.Icon as Icon
import Website.Components.Logo (logo)
import Website.Playground.Button.Styles (buttonStyles)
import Website.Playground.Types (State)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { root:
      { alignItems: "center"
      , backgroundColor: "var(--bg-canvas)"
      , display: "flex"
      , inset: 0
      , justifyContent: "center"
      , paddingInline: "var(--gutter)"
      , position: "absolute"
      , zIndex: 1
      }
  , content:
      { alignItems: "center"
      , display: "flex"
      , flexDirection: "column"
      , gap: 24
      , maxWidth: 480
      , width: "100%"
      }
  , heading:
      { alignItems: "center"
      , display: "flex"
      , fontSize: "clamp(32px, 5vw, 44px)"
      , fontWeight: 600
      , gap: "0.3em"
      , letterSpacing: "-0.03em"
      , lineHeight: 1
      , margin: 0
      }
  , logo: { flexShrink: 0, height: "1em", width: "1em" }
  , progress:
      { appearance: "none"
      , backgroundColor: "var(--surface-2)"
      , borderStyle: "none"
      , color: "var(--accent)"
      , display: "block"
      , height: 8
      , width: "100%"
      , "::-webkit-progress-bar": { backgroundColor: "var(--surface-2)" }
      , "::-webkit-progress-value":
          { backgroundColor: "var(--accent)"
          , transitionDuration: "160ms"
          , transitionProperty: "width"
          , transitionTimingFunction: "var(--ease-out)"
          }
      , "::-moz-progress-bar": { backgroundColor: "var(--accent)" }
      }
  , figures:
      { color: "var(--text-secondary)"
      , display: "flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , gap: 16
      , justifyContent: "space-between"
      , marginTop: -12
      , minHeight: "1.5em"
      , width: "100%"
      }
  , error: { width: "100%" }
  , icon: { display: "inline-flex", fontSize: 12 }
  }

styleProps = StyleX.recordProps styles

loading :: State -> Effect Unit -> JSX
loading state retry =
  DOM.section { className: styleProps.root.className, "aria-labelledby": "playground-loading" }
    [ DOM.div styleProps.content if state.phase == "failed" then failed else progress ]
  where
  packages = state.packages

  heading text = DOM.h1 { className: styleProps.heading.className, id: "playground-loading" }
    [ DOM.text text, logo styleProps.logo ]

  progress =
    [ heading "Loading"
    , DOM.progress
        { className: styleProps.progress.className
        , "aria-label": "Packages downloaded"
        , max: show (max 1 packages.total)
        , value: show packages.loaded
        }
        []
    , DOM.div styleProps.figures
        if packages.total == 0
        then []
        else
          [ DOM.span {} (show packages.loaded <> " of " <> show packages.total <> " packages")
          , DOM.span {}
              (megabytes packages.bytes <> " of " <> megabytes packages.totalBytes <> " MB")
          ]
    ]

  failed =
    [ heading "Could not load"
    , DOM.div styleProps.error
        [ codeBlock
            { code: fromMaybe "Something went wrong." (toMaybe state.server.message)
            , filename: "Error"
            , highlight: []
            , language: Shell
            , lineNumbers: false
            , note: Nothing
            , surface: Flat
            }
        ]
    , DOM.button
        { className:
            ( StyleX.props [ buttonStyles.action, buttonStyles.raised, buttonStyles.accent ]
            ).className
        , onClick: handler_ retry
        , type: "button"
        }
        [ DOM.span styleProps.icon
            (element Icon.rotateCcw { "aria-hidden": true, focusable: false })
        , DOM.text "Try again"
        ]
    ]

megabytes :: Int -> String
megabytes bytes = show (tenths / 10) <> "." <> show (tenths `mod` 10)
  where
  tenths = (bytes + 50000) / 100000
