module Website.Playground.Button.Styles (buttonStyles) where

import Iris.StyleX as StyleX

-- Shared by the playground's header and its loading screen.
buttonStyles = StyleX.create
  -- Transparent actions keep a subtle fill beside the tabs and strengthen it on hover.
  { action:
      { alignItems: "center"
      , backgroundColor: { default: "var(--surface-1)", ":hover": "var(--surface-3)" }
      , borderRadius: 999
      , borderStyle: "none"
      , color: "var(--text-primary)"
      , cursor: "default"
      , display: "inline-flex"
      , fontFamily: "var(--font-sans)"
      , fontSize: 13
      , fontWeight: 500
      , gap: 6
      , height: 32
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingInline: 12
      , transform: { default: "none", ":active": "scale(0.98)" }
      , transitionDuration: "140ms, 80ms"
      , transitionProperty: "background-color, transform"
      , transitionTimingFunction: "var(--ease-out)"
      , whiteSpace: "nowrap"
      }
  -- Run, Compiling, Stop, Try again, Share and Reset are one raised key, as on audio equipment of
  -- the period: lit from above by a translucent sheen, with a lip below and an engraved label,
  -- sinking while pressed.
  -- Only its color changes between states, and colors and shadows interpolate, so the key eases
  -- from one state to the next. Its shadows keep one shape for that reason.
  , raised:
      { backgroundColor: "var(--surface-2)"
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active":
              "inset 0 1px 3px oklch(0% 0 0 / 45%), inset 0 0 0 oklch(0% 0 0 / 0%), 0 0 0 oklch(0% 0 0 / 0%)"
          , ":focus-visible":
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), var(--shadow-focus)"
          , ":disabled":
              "inset 0 1px 0 oklch(100% 0 0 / 10%), inset 0 -1px 0 oklch(0% 0 0 / 25%), 0 1px 2px oklch(0% 0 0 / 35%)"
          }
      , color: "var(--text-tertiary)"
      , fontWeight: 600
      , paddingInline: 16
      , textShadow: "0 -1px 0 oklch(0% 0 0 / 35%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      , transitionDuration: "180ms, 180ms, 180ms, 180ms, 80ms"
      , transitionProperty: "background-color, box-shadow, color, text-shadow, transform"
      }
  , accent:
      { backgroundColor:
          { default: "var(--accent)"
          , ":hover": "var(--accent-hover)"
          , ":active": "var(--accent-press)"
          }
      , color: "var(--text-on-accent)"
      , textShadow: "0 1px 0 oklch(from var(--signal-200) l c h / 45%)"
      }
  }
