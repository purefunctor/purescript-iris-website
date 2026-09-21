module Website.Components.Header.Mobile
  ( brandIconStyle
  , externalLinkIconStyle
  , linkContentStyle
  , linkStyle
  , navigationDrawer
  , navigationIconStyle
  , navigationStyle
  ) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)

styles = StyleX.create
  { navigation:
      { display: "flex"
      , flexDirection: "column"
      , gap: 0
      , padding: "24px 20px"
      , position: "relative"
      }
  , navigationBackground:
      { display: "none" }
  , trigger:
      { "WebkitTapHighlightColor": "transparent"
      , alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "oklch(100% 0 0 / 0.12)" }
      , borderRadius: 999
      , color: "var(--landing-header-color, var(--landing-color-paper))"
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "none"
      , height: 42
      , justifyContent: "center"
      , width: 42
      , ":focus-visible":
          { outlineColor: "var(--landing-color-signal)"
          , outlineOffset: 2
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      , "@media (max-width: 700px)": { display: "inline-flex" }
      }
  , overlay:
      { alignItems: "stretch"
      , backgroundColor: "oklch(22.29% 0.0049 173.9 / 0.2)"
      , display: "flex"
      , inset: 0
      , justifyContent: "flex-end"
      , opacity: 1
      , position: "fixed"
      , transitionDuration: "100ms"
      , transitionProperty: "opacity"
      , transitionTimingFunction: "linear"
      , width: "100vw"
      , zIndex: 20
      , "@media (prefers-reduced-motion: reduce)": { transitionDuration: "0ms" }
      }
  , overlayTransition:
      { opacity: 0 }
  , modal:
      { backgroundColor: "var(--landing-color-paper)"
      , backgroundImage:
          "linear-gradient(90deg, var(--landing-color-paper) 0%, oklch(from var(--landing-color-paper) l c h / 88%) 58%, transparent 100%), url('/iris-digital-field.webp')"
      , backgroundPosition: "70% center"
      , backgroundSize: "auto 100%"
      , color: "var(--landing-color-ink)"
      , flexShrink: 0
      , height: "100dvh"
      , maxWidth: "none"
      , opacity: 1
      , padding: 0
      , transform: "translateX(0)"
      , transitionDuration: "140ms, 90ms"
      , transitionProperty: "transform, opacity"
      , transitionTimingFunction: "cubic-bezier(0.22, 1, 0.36, 1), ease-out"
      , width: "100vw"
      , "@media (prefers-reduced-motion: reduce)": { transitionDuration: "0ms" }
      }
  , modalTransition:
      { opacity: 0
      , transform: "translateX(24px)"
      }
  , dialog: { display: "flex", flexDirection: "column", gap: 0, height: "100%", outline: "none" }
  , closeRow:
      { display: "flex"
      , justifyContent: "flex-end"
      , minHeight: 68
      , paddingBottom: 13
      , paddingLeft: 24
      , paddingRight: 20
      , paddingTop: 13
      }
  , close:
      { "WebkitTapHighlightColor": "transparent"
      , alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "oklch(100% 0 0 / 0.12)" }
      , borderRadius: 999
      , color: "var(--landing-color-ink)"
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "inline-flex"
      , height: 42
      , justifyContent: "center"
      , width: 42
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 2
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , mobileLink:
      { alignItems: "center"
      , backgroundColor:
          { default: "oklch(from var(--landing-color-paper) l c h / 72%)"
          , ":hover": "oklch(from var(--landing-color-violet) l c h / 9%)"
          }
      , borderBottomColor: "oklch(from var(--landing-color-ink) l c h / 14%)"
      , borderBottomStyle: "solid"
      , borderBottomWidth: 1
      , borderRadius: 0
      , color: "var(--landing-color-ink)"
      , cursor: "default"
      , display: "grid"
      , fontFamily: "Anybody Variable, sans-serif"
      , fontSize: 24
      , fontStretch: "112%"
      , fontWeight: 620
      , gap: 16
      , gridTemplateColumns: "minmax(0, 1fr) auto"
      , minHeight: 76
      , paddingInline: 18
      , textDecoration: "none"
      , whiteSpace: "nowrap"
      , width: "100%"
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: "-3px"
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , githubLink: { color: "var(--landing-color-ink)" }
  , blueskyLink: { color: "var(--landing-color-ink)" }
  , documentationLink: { color: "var(--landing-color-ink)" }
  , linkContent:
      { alignItems: "center"
      , display: "inline-flex"
      , gap: 8
      , gridColumn: "1"
      , gridRow: 1
      , justifySelf: "start"
      }
  , externalLinkIcon:
      { alignItems: "center"
      , display: "inline-flex"
      , fontSize: 13
      , gridColumn: "2"
      , gridRow: 1
      , justifyContent: "center"
      , justifySelf: "end"
      , opacity: 0.6
      , width: "auto"
      }
  , brandIcon:
      { alignItems: "center"
      , color: "#000000"
      , display: "inline-flex"
      , flexShrink: 0
      , fontSize: 13
      , justifyContent: "center"
      , opacity: 0.6
      , width: 24
      }
  , navigationIcon:
      { alignItems: "center"
      , display: "inline-flex"
      , flexShrink: 0
      , fontSize: 13
      , justifyContent: "center"
      , opacity: 0.6
      , width: 24
      }
  }

navigationStyle = StyleX.props styles.navigation
linkContentStyle = StyleX.props styles.linkContent
externalLinkIconStyle = StyleX.props styles.externalLinkIcon
brandIconStyle = StyleX.props styles.brandIcon
navigationIconStyle = StyleX.props styles.navigationIcon

linkStyle destination =
  StyleX.props
    [ styles.mobileLink
    , StyleX.conditional (destination == "github") styles.githubLink
    , StyleX.conditional (destination == "bluesky") styles.blueskyLink
    , StyleX.conditional (destination == "documentation") styles.documentationLink
    ]

foreign import navigationDrawerImpl :: DrawerClasses -> JSX -> JSX -> JSX -> JSX

type DrawerClasses =
  { trigger :: String
  , navigationBackground :: String
  , overlay :: Boolean -> String
  , modal :: Boolean -> String
  , dialog :: String
  , closeRow :: String
  , close :: String
  }

navigationDrawer :: JSX -> JSX -> JSX -> JSX
navigationDrawer = navigationDrawerImpl
  { trigger: (StyleX.props styles.trigger).className
  , navigationBackground: (StyleX.props styles.navigationBackground).className
  , overlay: \transitioning ->
      ( StyleX.props
          [ styles.overlay
          , StyleX.conditional transitioning styles.overlayTransition
          ]
      ).className
  , modal: \transitioning ->
      ( StyleX.props
          [ styles.modal
          , StyleX.conditional transitioning styles.modalTransition
          ]
      ).className
  , dialog: (StyleX.props styles.dialog).className
  , closeRow: (StyleX.props styles.closeRow).className
  , close: (StyleX.props styles.close).className
  }
