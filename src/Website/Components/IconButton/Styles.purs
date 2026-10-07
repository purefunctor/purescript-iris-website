module Website.Components.IconButton.Styles (iconButtonStyles) where

import Iris.StyleX as StyleX

-- Shared by the copy and information buttons in code block and command line headers.
iconButtonStyles = StyleX.create
  { button:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 8
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "inline-flex"
      , flexShrink: 0
      , justifyContent: "center"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , transform: { default: "none", ":active": "scale(0.94)" }
      , transitionDuration: "140ms, 140ms, 80ms"
      , transitionProperty: "background-color, color, transform"
      , transitionTimingFunction: "var(--ease-out)"
      }
  -- Lucide icons render at 1.2em.
  , small: { borderRadius: 5, fontSize: 12, height: 28, width: 28 }
  , medium: { fontSize: 13, height: 36, width: 36 }
  , tooltip:
      { backgroundColor: "var(--surface-3)"
      , borderColor: "var(--border-default)"
      , borderRadius: 5
      , borderStyle: "solid"
      , borderWidth: 1
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-sans)"
      , fontSize: 12
      , fontWeight: 500
      , whiteSpace: "nowrap"
      , opacity: { default: 1, "[data-entering]": 0, "[data-exiting]": 0 }
      , paddingBlock: 5
      , paddingInline: 8
      , transform:
          { default: "none"
          , "[data-entering]": "translateY(3px)"
          , "[data-exiting]": "translateY(3px)"
          }
      , transitionDuration: { default: "140ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "opacity, transform"
      , transitionTimingFunction: "var(--ease-out)"
      }
  }
