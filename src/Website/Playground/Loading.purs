module Website.Playground.Loading (loading) where

import Prelude

import Data.Maybe (fromMaybe)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX)
import React.Basic.Events (handler_)
import Website.Breakpoints (breakpoints)
import Website.Playground.Types (State)
import Yoga.React.DOM as DOM

styles = StyleX.create
  -- Covers the workspace, whose editor host stays mounted underneath for the controller.
  { root:
      { backgroundColor: "var(--bg-canvas)"
      , display: "flex"
      , flexDirection: "column"
      , inset: 0
      , paddingBlock: "clamp(48px, 12vh, 140px)"
      , paddingInline: "var(--gutter)"
      , position: "absolute"
      , zIndex: 1
      }
  , content: { display: "flex", flexDirection: "column", gap: 28, maxWidth: 760, width: "100%" }
  , heading:
      { fontSize: "clamp(44px, 7vw, 88px)"
      , fontWeight: 700
      , letterSpacing: "-0.045em"
      , lineHeight: 0.92
      , margin: 0
      , textWrap: "balance"
      }
  , emphasis: { color: "var(--text-tertiary)", display: "block" }
  -- A native progress bar, so progress needs no inline style, which the site's policy would block
  -- on the server-rendered page.
  , progress:
      { appearance: "none"
      , backgroundColor: "var(--surface-2)"
      , borderStyle: "none"
      , color: "var(--accent)"
      , display: "block"
      , height: 12
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
      , flexWrap: "wrap"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , gap: 16
      , justifyContent: "space-between"
      }
  , note:
      { color: "var(--text-tertiary)"
      , fontSize: 15
      , lineHeight: 1.6
      , margin: 0
      , maxWidth: "56ch"
      , textWrap: "pretty"
      }
  , error:
      { backgroundColor: "var(--red-300)"
      , color: "var(--granite-950)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , lineHeight: 1.6
      , margin: 0
      , overflowWrap: "anywhere"
      , paddingBlock: 12
      , paddingInline: 16
      }
  , retry:
      { alignSelf: "flex-start"
      , backgroundColor:
          { default: "var(--accent)"
          , ":hover": "var(--accent-hover)"
          , ":active": "var(--accent-press)"
          }
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , color: "var(--text-on-accent)"
      , cursor: "default"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , fontWeight: 600
      , height: 40
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingInline: 20
      }
  , hiddenOnPhones:
      { display:
          StyleX.conditionalValue "inline" [ StyleX.conditionalCase breakpoints.upTo600 "none" ]
      }
  }

styleProps = StyleX.recordProps styles

-- | What the page shows while the package set downloads and the language server loads, and when
-- | either failed.
loading :: State -> Effect Unit -> JSX
loading state retry =
  DOM.section { className: styleProps.root.className, "aria-labelledby": "playground-loading" }
    [ DOM.div styleProps.content if state.phase == "failed" then failed else progress ]
  where
  packages = state.packages
  packageSet = fromMaybe "" (toMaybe packages.packageSet)

  progress =
    [ DOM.h1 { className: styleProps.heading.className, id: "playground-loading" }
        [ DOM.text "Loading the ", DOM.span styleProps.emphasis "package set" ]
    , DOM.progress
        { className: styleProps.progress.className
        , "aria-label": "Packages downloaded"
        , max: show (max 1 packages.total)
        , value: show packages.loaded
        }
        []
    , DOM.div styleProps.figures
        [ DOM.span {}
            if packages.total == 0
            then "Starting…"
            else show packages.loaded <> " of " <> show packages.total <> " packages"
        , if packages.totalBytes == 0
          then mempty
          else DOM.span {}
            (megabytes packages.bytes <> " of " <> megabytes packages.totalBytes <> " MB")
        ]
    , DOM.p styleProps.note
        [ DOM.text "Every package in the PureScript Registry's package set"
        , DOM.text (if packageSet == "" then "" else " " <> packageSet)
        , DOM.text ", ready to import. "
        , DOM.span styleProps.hiddenOnPhones
            "Your browser keeps them, so later visits start sooner."
        ]
    ]

  failed =
    [ DOM.h1 { className: styleProps.heading.className, id: "playground-loading" }
        [ DOM.text "The playground ", DOM.span styleProps.emphasis "could not start" ]
    , DOM.p styleProps.error (fromMaybe "Something went wrong." (toMaybe state.server.message))
    , DOM.p styleProps.note
        "Packages that finished downloading are kept, so trying again picks up where this stopped."
    , DOM.button { className: styleProps.retry.className, onClick: handler_ retry, type: "button" }
        "Try again"
    ]

-- | Bytes in megabytes, to one decimal place.
megabytes :: Int -> String
megabytes bytes = show (tenths / 10) <> "." <> show (tenths `mod` 10)
  where
  tenths = (bytes + 50000) / 100000
