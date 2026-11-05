module Website.Landing.Actions (actions) where

import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import Website.Components.Icon as Icon
import Yoga.React.DOM as DOM

styles = StyleX.create
  { root: { display: "flex", flexWrap: "wrap", gap: 12 }
  , action:
      { alignItems: "center"
      , borderStyle: "solid"
      , borderWidth: 1
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 15
      , fontWeight: 600
      , gap: 10
      , height: 46
      , letterSpacing: "-0.01em"
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingInline: 20
      , textDecoration: "none"
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, border-color, color, box-shadow"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , primary:
      { backgroundColor:
          { default: "var(--accent)"
          , ":hover": "var(--accent-hover)"
          , ":active": "var(--accent-press)"
          }
      , borderColor: "transparent"
      , boxShadow:
          { default: "inset 0 1px 0 oklch(100% 0 0 / 30%), 0 10px 30px -10px var(--accent)"
          , ":focus-visible": "var(--shadow-focus)"
          }
      , color: "var(--text-on-accent)"
      }
  , secondary:
      { backgroundColor: { default: "var(--glass-fill)", ":hover": "var(--surface-2)" }
      , borderColor: { default: "var(--border-default)", ":hover": "var(--border-strong)" }
      , boxShadow:
          { default: "inset 0 1px 0 var(--glass-highlight)"
          , ":focus-visible": "var(--shadow-focus)"
          }
      , color: "var(--text-primary)"
      }
  , icon: { display: "inline-flex", fontSize: 15 }
  }

styleProps = StyleX.recordProps styles

actions :: JSX
actions = DOM.div styleProps.root
  [ DOM.a
      { className: (StyleX.props [ styles.action, styles.primary ]).className
      , href: "/docs/getting-started/"
      }
      [ DOM.text "Get started"
      , DOM.span styleProps.icon (element Icon.arrowRight { "aria-hidden": true, focusable: false })
      ]
  , DOM.a
      { className: (StyleX.props [ styles.action, styles.secondary ]).className
      , href: "/playground/"
      }
      [ DOM.span styleProps.icon (element Icon.play { "aria-hidden": true, focusable: false })
      , DOM.text "Open the playground"
      ]
  ]
