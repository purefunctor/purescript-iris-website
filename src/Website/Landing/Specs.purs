module Website.Landing.Specs (component) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (ReactComponent, Ref)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Website.Breakpoints (breakpoints)
import Website.Components.ContentShell as ContentShell
import Yoga.React.DOM as DOM

foreign import countIn :: Ref (Nullable Element) -> String -> Effect (Effect Unit)

type Spec = { value :: String, unit :: String, label :: String, note :: String, href :: String }

specList :: Array Spec
specList =
  [ { value: "11.6"
    , unit: "×"
    , label: "faster cold builds than purs compile"
    , note: "Median of 5 builds · M3 Pro"
    , href: "#benchmarks-cold"
    }
  , { value: "0.28"
    , unit: "s"
    , label: "to rebuild after an edit in iris watch"
    , note: "Median of 20 edits · M3 Pro"
    , href: "#benchmarks-hot"
    }
  ]

styles = StyleX.create
  { root:
      { backgroundColor: "var(--granite-900)"
      , backgroundImage:
          "repeating-linear-gradient(90deg, oklch(from var(--granite-50) l c h / 1.2%) 0 1px, transparent 1px 3px), linear-gradient(180deg, oklch(from var(--granite-50) l c h / 4%), transparent 60%)"
      , borderBlockColor: "var(--border-default)"
      , borderBlockStyle: "solid"
      , borderBlockWidth: 1
      , boxShadow:
          "inset 0 1px 0 var(--glass-highlight), inset 0 -1px 0 oklch(0% 0 0 / 50%), 0 30px 60px -40px oklch(0% 0 0 / 80%)"
      , paddingBlock: "clamp(8px, 1.6vw, 20px)"
      }
  , panel:
      { display: "grid"
      , gridTemplateColumns: "repeat(2, minmax(0, 1fr))"
      , listStyle: "none"
      , padding: 0
      }
  , item: { display: "flex", minWidth: 0 }
  , cell:
      { backgroundColor:
          { default: "transparent", ":hover": "oklch(from var(--granite-50) l c h / 2.5%)" }
      , color: "inherit"
      , flexGrow: 1
      , minWidth: 0
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , textDecoration: "none"
      , transitionDuration: "140ms"
      , transitionProperty: "background-color"
      , borderInlineStartColor: "var(--border-subtle)"
      , borderInlineStartStyle: "solid"
      , borderInlineStartWidth: 1
      , boxShadow: "inset 1px 0 0 oklch(0% 0 0 / 35%)"
      , display: "flex"
      , flexDirection: "column"
      , gap: 10
      , paddingBlock: "clamp(18px, 2.4vw, 28px)"
      , paddingInline: StyleX.conditionalValue "clamp(16px, 2.4vw, 28px)"
          [ StyleX.conditionalCase breakpoints.upTo480 "12px" ]
      }
  , firstCell: { borderInlineStartWidth: 0, boxShadow: "none" }
  , display:
      { alignItems: "baseline"
      , backgroundColor: "oklch(from var(--granite-950) calc(l - 0.03) c h)"
      , boxShadow:
          "inset 0 2px 6px oklch(0% 0 0 / 60%), inset 0 0 0 1px oklch(0% 0 0 / 50%), 0 1px 0 var(--glass-highlight)"
      , display: "flex"
      , gap: 6
      , minWidth: 0
      , overflow: "hidden"
      , paddingBlock: 10
      , paddingInline: StyleX.conditionalValue 14 [ StyleX.conditionalCase breakpoints.upTo480 10 ]
      }
  , value:
      { color: "var(--signal-300)"
      , fontFamily: "var(--font-sans)"
      , fontSize: StyleX.conditionalValue "clamp(36px, 4.6vw, 64px)"
          [ StyleX.conditionalCase breakpoints.upTo960 "clamp(26px, 7.4vw, 48px)"
          , StyleX.conditionalCase breakpoints.upTo480 "clamp(22px, 7vw, 30px)"
          ]
      , fontVariantNumeric: "tabular-nums"
      , fontWeight: 600
      , letterSpacing: "-0.045em"
      , lineHeight: 1
      , textShadow: "0 0 18px oklch(from var(--signal-400) l c h / 55%)"
      }
  , unit:
      { color: "var(--signal-400)"
      , fontFamily: "var(--font-mono)"
      , fontSize: StyleX.conditionalValue 20 [ StyleX.conditionalCase breakpoints.upTo960 13 ]
      , letterSpacing: "0"
      , opacity: 0.9
      }
  , label: { color: "var(--text-secondary)", fontSize: 14, lineHeight: 1.45, textWrap: "pretty" }
  , note:
      { color: "var(--text-tertiary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , letterSpacing: "0.02em"
      , marginBlockStart: "auto"
      }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "Specs" \_ -> Hooks.do
  panel <- Hooks.useRef Nullable.null
  Hooks.useEffectOnce (countIn panel styleProps.value.className)
  pure $ DOM.div styleProps.root
    [ DOM.div ContentShell.contentShell
        [ DOM.ul
            { className: styleProps.panel.className
            , "aria-label": "Iris at a glance"
            , ref: DOM.reactRef panel
            }
            (mapWithIndex spec specList)
        ]
    ]
  where
  spec index { value, unit, label, note, href } = DOM.li styleProps.item
    [ DOM.a
        { className:
            ( StyleX.props [ styles.cell, StyleX.conditional (index == 0) styles.firstCell ]
            ).className
        , href
        }
        [ DOM.span styleProps.display
            [ DOM.span styleProps.value value, DOM.span styleProps.unit unit ]
        , DOM.span styleProps.label label
        , if note == "" then mempty else DOM.span styleProps.note note
        ]
    ]
