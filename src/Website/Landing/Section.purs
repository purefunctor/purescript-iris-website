module Website.Landing.Section (eyebrow, heading, headingStyle, lead, section, sectionStyle) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { section: { paddingBlock: "clamp(56px, 7vw, 96px)", scrollMarginTop: "var(--nav-height)" }
  , eyebrow:
      { alignItems: "center"
      , color: "var(--text-secondary)"
      , display: "flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , gap: 10
      , letterSpacing: "0.06em"
      , lineHeight: 1
      , marginBlockEnd: 20
      , textTransform: "uppercase"
      }
  , led:
      { backgroundColor: "var(--accent)"
      , boxShadow: "0 0 10px var(--accent)"
      , flexShrink: 0
      , height: 6
      , width: 6
      }
  , index: { color: "var(--accent-text)" }
  , rule: { backgroundColor: "var(--border-default)", height: 1, width: 24 }
  , heading:
      { fontSize: "clamp(32px, 4vw, 46px)"
      , fontWeight: 600
      , letterSpacing: "-0.03em"
      , lineHeight: 1.05
      , overflowWrap: "break-word"
      , textWrap: "balance"
      }
  , lead: { color: "var(--text-secondary)", fontSize: 17, lineHeight: 1.65, textWrap: "pretty" }
  }

styleProps = StyleX.recordProps styles

eyebrow :: { index :: String, label :: String } -> JSX
eyebrow { index, label } = DOM.p styleProps.eyebrow
  [ DOM.span { className: styleProps.led.className, "aria-hidden": true } []
  , DOM.span styleProps.index index
  , DOM.span { className: styleProps.rule.className, "aria-hidden": true } []
  , DOM.span {} label
  ]

heading :: { id :: String, text :: String } -> JSX
heading { id, text } = DOM.h2 { className: styleProps.heading.className, id } text

lead :: String -> JSX
lead = DOM.p styleProps.lead

section :: StyleX.Props
section = styleProps.section

sectionStyle :: StyleX.Style
sectionStyle = styles.section

headingStyle :: StyleX.Style
headingStyle = styles.heading
