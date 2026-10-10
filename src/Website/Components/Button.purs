module Website.Components.Button (ButtonAction, Size(..), Variant(..), buttonAction) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (handler_)
import Website.Components.Icon as Icon
import Yoga.React.DOM as DOM

data Variant = Primary | Secondary | Glass

data Size = Small | Medium | Large

type ButtonAction =
  { label :: String
  , icon :: Maybe (ReactComponent Icon.IconProps)
  , onPress :: Effect Unit
  , size :: Size
  , variant :: Variant
  }

styles =
  StyleX.create
    { button:
        { alignItems: "center"
        , borderColor: "transparent"
        , borderRadius: 8
        , borderStyle: "solid"
        , borderWidth: 1
        -- Buttons keep the platform's control cursor; macOS uses the regular arrow.
        , cursor: "var(--landing-interactive-cursor, pointer)"
        , display: "inline-flex"
        , flexShrink: 0
        , fontFamily: "var(--font-sans)"
        , fontWeight: 500
        , justifyContent: "center"
        , letterSpacing: "-0.005em"
        , lineHeight: 1
        , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , textDecoration: "none"
        , transform: { default: "none", ":active": "scale(0.98)" }
        , transitionDuration: "140ms, 140ms, 140ms, 80ms"
        , transitionProperty: "background-color, border-color, color, transform"
        , transitionTimingFunction: "var(--ease-out)"
        , userSelect: "none"
        , whiteSpace: "nowrap"
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
        , boxShadow:
            { default: "inset 0 1px 0 var(--glass-highlight)"
            , ":focus-visible": "var(--shadow-focus)"
            }
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

-- | An action styled as a button.
buttonAction :: ButtonAction -> JSX
buttonAction { label, icon, onPress, size, variant } =
  DOM.button
    { className: (StyleX.props [ styles.button, sizeStyle size, variantStyle variant ]).className
    , onClick: handler_ onPress
    , type: "button"
    }
    (buttonContent label icon size)

buttonContent :: String -> Maybe (ReactComponent Icon.IconProps) -> Size -> Array JSX
buttonContent label icon size = case icon of
  Nothing -> [ DOM.text label ]
  Just component ->
    [ DOM.text label
    , DOM.span
        (StyleX.props [ styles.icon, iconSizeStyle size ])
        (element component { "aria-hidden": true, focusable: false })
    ]
