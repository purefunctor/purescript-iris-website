module Website.Landing.Section (heading, lead) where

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { heading:
      { fontSize: "clamp(32px, 4.4vw, 44px)"
      , fontWeight: 500
      , letterSpacing: "-0.03em"
      , lineHeight: 1.1
      , overflowWrap: "break-word"
      , textWrap: "balance"
      }
  , emphasis: { color: "var(--text-emphasis)" }
  , lead:
      { color: "var(--text-secondary)"
      , fontSize: 17
      , lineHeight: 1.65
      , textWrap: "pretty"
      }
  }

-- | A section heading whose second beat shifts to the emphasis color.
heading :: { id :: String, text :: String, emphasis :: String } -> JSX
heading { id, text, emphasis } =
  DOM.h2 { className: (StyleX.props styles.heading).className, id }
    [ DOM.text text, DOM.span (StyleX.props styles.emphasis) emphasis ]

lead :: String -> JSX
lead = DOM.p (StyleX.props styles.lead)
