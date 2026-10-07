module Website.Landing.Section (heading, lead, section) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Yoga.React.DOM as DOM

styles =
  StyleX.create
    -- Every section shares this padding, so consecutive sections sit the same distance apart.
    { section:
        { paddingBlock: "clamp(40px, 5vw, 64px)"
        , scrollMarginTop: "var(--nav-height)"
        }
    , heading:
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

-- | A section heading whose second beat, when given, shifts to the emphasis color.
heading :: { id :: String, text :: String, emphasis :: String } -> JSX
heading { id, text, emphasis } =
  DOM.h2
    { className: (StyleX.props styles.heading).className, id }
    if emphasis == ""
    then [ DOM.text text ]
    else [ DOM.text text, DOM.span (StyleX.props styles.emphasis) emphasis ]

lead :: String -> JSX
lead = DOM.p (StyleX.props styles.lead)

-- | Shared spacing for the landing page's content sections.
section :: StyleX.Props
section = StyleX.props styles.section
