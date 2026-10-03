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
      , padding: "7px 10px"
      , transition: "background-color 140ms var(--ease-out), color 140ms var(--ease-out)"
      , whiteSpace: "nowrap"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
  }
