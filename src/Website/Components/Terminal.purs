module Website.Components.Terminal (Entry, terminal) where

import Prelude

import Data.String (joinWith)
import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import Website.Components.CopyButton as CopyButton
import Website.Components.Icon as Icon
import Yoga.React.DOM as DOM

type Entry = { command :: String, output :: String }

styles =
  StyleX.create
    { root:
        { backgroundColor: "var(--syn-bg)"
        , borderColor: "var(--border-subtle)"
        , borderStyle: "solid"
        , borderWidth: 1
        , borderRadius: 8
        , minWidth: 0
        , overflow: "hidden"
        }
    , head:
        { display: "flex"
        , alignItems: "center"
        , gap: 8
        , height: 38
        , paddingInlineStart: 14
        , paddingInlineEnd: 8
        , borderBlockEndColor: "var(--border-subtle)"
        , borderBlockEndStyle: "solid"
        , borderBlockEndWidth: 1
        }
    , icon: { display: "inline-flex", color: "var(--text-tertiary)", fontSize: 12 }
    , title:
        { flexGrow: 1
        , fontFamily: "var(--font-sans)"
        , fontSize: 13
        , color: "var(--text-secondary)"
        }
    , pre:
        { fontFamily: "var(--font-mono)"
        , fontSize: 13
        , lineHeight: 1.7
        , paddingBlock: 16
        , paddingInline: 18
        , margin: 0
        , whiteSpace: "pre-wrap"
        , overflowWrap: "anywhere"
        }
    , entry: { display: "block", marginBlockEnd: 8 }
    , command: { display: "flex", gap: 10, color: "var(--syn-text)" }
    , prompt: { color: "var(--accent-text)", flexShrink: 0, userSelect: "none" }
    , input: { minWidth: 0 }
    , output: { display: "block", color: "var(--text-tertiary)", paddingBlockStart: 2 }
    }

styleProps = StyleX.recordProps styles

terminal :: Array Entry -> JSX
terminal entries =
  DOM.figure
    styleProps.root
    [ DOM.figcaption
        styleProps.head
        [ DOM.span
            styleProps.icon
            (element Icon.squareTerminal { "aria-hidden": true, focusable: false })
        , DOM.span styleProps.title "Terminal"
        , CopyButton.copyButton
            { label: "Copy terminal commands"
            , size: CopyButton.Small
            , text: joinWith "\n" (map _.command entries)
            }
        ]
    , DOM.pre styleProps.pre (DOM.code {} (map entry entries))
    ]
  where
  entry { command, output } =
    DOM.span
      styleProps.entry
      [ DOM.span
          styleProps.command
          [ DOM.span { className: styleProps.prompt.className, "aria-hidden": true } "$"
          , DOM.span styleProps.input command
          ]
      , if output == "" then mempty else DOM.span styleProps.output output
      ]
