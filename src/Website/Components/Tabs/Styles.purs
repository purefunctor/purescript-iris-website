module Website.Components.Tabs.Styles (tabStyles) where

import Iris.StyleX as StyleX

-- Shared by the installation platform tabs and the build benchmark tabs.
tabStyles = StyleX.create
  { tabList: { display: "flex", gap: 2 }
  , tab:
      { alignItems: "center"
      , backgroundColor:
          { default: "transparent"
          , ":hover": "var(--glass-fill)"
          , "[data-selected]": "var(--glass-fill-strong)"
          }
      , borderRadius: 5
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--text-primary)"
          , "[data-selected]": "var(--text-primary)"
          }
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "inline-flex"
      , fontSize: 13
      , fontWeight: 500
      , gap: 5
      , lineHeight: 1
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingBlock: 7
      , paddingInline: 10
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      , whiteSpace: "nowrap"
      }
  }
