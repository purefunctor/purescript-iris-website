module Website.Playground.FileTabs (fileTabs) where

import Prelude

import Data.Nullable (Nullable)
import Iris.StyleX as StyleX
import Iris.StyleX.When as When
import React.Basic (JSX, ReactComponent, element)
import Website.Playground.Types (Actions, File, Viewer)

foreign import fileTabsImpl ::
  ReactComponent
    { files :: Array File
    , open :: Array String
    , active :: Nullable String
    , viewing :: Nullable Viewer
    , actions :: Actions
    , rootClassName :: String
    , tabClassName :: String
    , activeTabClassName :: String
    , nameClassName :: String
    , errorCountClassName :: String
    , warningCountClassName :: String
    , closeClassName :: String
    , activeCloseClassName :: String
    }

tabIn = StyleX.keyframes
  { from: { opacity: 0, transform: "translateY(4px)" }, to: { opacity: 1, transform: "none" } }

styles = StyleX.create
  { root:
      { alignItems: "stretch"
      , alignSelf: "stretch"
      , display: "flex"
      , flexGrow: 1
      , minWidth: 0
      , overflowX: "auto"
      , scrollbarWidth: "none"
      }
  -- Flat tabs that fill the toolbar's height; the open file takes the editor's surface.
  , tab:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderInlineEndColor: "var(--border-subtle)"
      , borderInlineEndStyle: "solid"
      , borderInlineEndWidth: 1
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , display: "flex"
      , flexShrink: 0
      , gap: 2
      , paddingInlineEnd: 6
      , position: "relative"
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      -- A newly opened tab settles into the strip.
      , animationDuration: "180ms"
      , animationName: { default: tabIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      }
  , activeTab:
      { backgroundColor: { default: "var(--granite-900)", ":hover": "var(--granite-900)" }
      , color: { default: "var(--text-primary)", ":hover": "var(--text-primary)" }
      , boxShadow: "inset 0 2px 0 var(--accent)"
      }
  , name:
      { alignItems: "center"
      , alignSelf: "stretch"
      , backgroundColor: "transparent"
      , borderStyle: "none"
      , color: "inherit"
      , cursor: "default"
      , display: "inline-flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , gap: 7
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingInlineStart: 12
      , paddingInlineEnd: 6
      , whiteSpace: "nowrap"
      }
  , count:
      { borderRadius: 999
      , fontFamily: "var(--font-sans)"
      , fontSize: 11
      , fontWeight: 600
      , lineHeight: "16px"
      , minWidth: 16
      , paddingInline: 5
      , textAlign: "center"
      }
  , errorCount: { backgroundColor: "var(--red-300)", color: "var(--granite-950)" }
  , warningCount: { backgroundColor: "var(--yellow-400)", color: "var(--granite-950)" }
  -- Inactive tabs show their close button on hover or focus, and always on touch screens.
  , close:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 4
      , borderStyle: "none"
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 12
      , height: 22
      , justifyContent: "center"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , opacity: StyleX.conditionalValue 0.0
          [ When.ancestor ":hover" 1.0
          , When.ancestor ":focus-within" 1.0
          , StyleX.conditionalCase "@media (hover: none)" 1.0
          ]
      , outline: { default: "revert", ":focus-visible": "none" }
      , width: 22
      }
  , activeClose: { opacity: 1 }
  }

styleProps = StyleX.recordProps styles

-- | The open files as tabs, with the read-only source that navigation opened.
fileTabs ::
  { files :: Array File
  , open :: Array String
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , actions :: Actions
  } -> JSX
fileTabs { files, open, active, viewing, actions } = element fileTabsImpl
  { files
  , open
  , active
  , viewing
  , actions
  , rootClassName: styleProps.root.className
  , tabClassName: (StyleX.props [ styles.tab, StyleX.defaultMarker ]).className
  , activeTabClassName:
      (StyleX.props [ styles.tab, styles.activeTab, StyleX.defaultMarker ]).className
  , nameClassName: styleProps.name.className
  , errorCountClassName: (StyleX.props [ styles.count, styles.errorCount ]).className
  , warningCountClassName: (StyleX.props [ styles.count, styles.warningCount ]).className
  , closeClassName: (StyleX.props [ styles.close ]).className
  , activeCloseClassName: (StyleX.props [ styles.close, styles.activeClose ]).className
  }
