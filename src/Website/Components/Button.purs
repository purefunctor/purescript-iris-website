module Website.Components.Button
  ( ButtonLink
  , Size(..)
  , Variant(..)
  , buttonLink
  ) where

import Data.Maybe (Maybe(..))
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Components.Icon as Icon
import Yoga.React.DOM as DOM

data Variant = Primary | Secondary | Glass

data Size = Small | Medium | Large

type ButtonLink =
  { href :: String
  , label :: String
  , icon :: Maybe (ReactComponent Icon.IconProps)
  , size :: Size
  , variant :: Variant
  }

styles = StyleX.create
  { button:
      { alignItems: "center"
      , borderColor: "transparent"
      , borderRadius: 8
      , borderStyle: "solid"
      , borderWidth: 1
      , cursor: "default"
      , display: "inline-flex"
      , flexShrink: 0
      , fontFamily: "var(--font-sans)"
      , fontWeight: 500
      , justifyContent: "center"
      , letterSpacing: "-0.005em"
      , lineHeight: 1
      , textDecoration: "none"
      , transform: { default: "none", ":active": "scale(0.98)" }
      , transition:
          "background-color 140ms var(--ease-out), border-color 140ms var(--ease-out), color 140ms var(--ease-out), transform 80ms var(--ease-out)"
      , userSelect: "none"
      , whiteSpace: "nowrap"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
  , small: { borderRadius: 5, fontSize: 13, gap: 6, height: 28, paddingInline: 10 }
  , medium: { fontSize: 14, gap: 8, height: 36, paddingInline: 14 }
  , large: { fontSize: 15, gap: 8, height: 44, paddingInline: 20 }
  , primary:
      { backgroundColor:
          { default: "var(--accent)"
          , ":hover": "var(--accent-hover)"
          , ":active": "var(--accent-press)"
          }
      , color: "var(--text-on-accent)"
      }
  , secondary:
      { backgroundColor: { default: "var(--surface-2)", ":hover": "var(--surface-3)" }
      , borderColor: { default: "var(--border-default)", ":hover": "var(--border-strong)" }
      , color: "var(--text-primary)"
      }
  , glass:
      { "WebkitBackdropFilter": "blur(12px)"
      , backdropFilter: "blur(12px)"
      , backgroundColor: { default: "var(--glass-fill)", ":hover": "var(--glass-fill-strong)" }
      , borderColor: { default: "var(--glass-border)", ":hover": "var(--border-strong)" }
      , boxShadow: "inset 0 1px 0 var(--glass-highlight)"
      , color: "var(--text-primary)"
      }
  -- Lucide icons render at 1.2em.
  , icon: { display: "inline-flex", flexShrink: 0 }
  , smallIcon: { fontSize: 12 }
  , mediumIcon: { fontSize: 13 }
  , largeIcon: { fontSize: 15 }
  }

sizeStyle :: Size -> StyleX.Style
sizeStyle = case _ of
  Small -> styles.small
  Medium -> styles.medium
  Large -> styles.large

iconSizeStyle :: Size -> StyleX.Style
iconSizeStyle = case _ of
  Small -> styles.smallIcon
  Medium -> styles.mediumIcon
  Large -> styles.largeIcon

variantStyle :: Variant -> StyleX.Style
variantStyle = case _ of
  Primary -> styles.primary
  Secondary -> styles.secondary
  Glass -> styles.glass

-- | A navigation link styled as a button. It keeps the regular arrow cursor on every platform.
buttonLink :: ButtonLink -> JSX
buttonLink { href, label, icon, size, variant } =
  DOM.a
    { className:
        (StyleX.props [ styles.button, sizeStyle size, variantStyle variant ]).className
    , href
    }
    case icon of
      Nothing -> [ DOM.text label ]
      Just component ->
        [ DOM.text label
        , DOM.span (StyleX.props [ styles.icon, iconSizeStyle size ])
            (element component { "aria-hidden": true, focusable: false })
        ]
