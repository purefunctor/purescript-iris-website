module Website.Playground.FileTabs (fileTabs) where

import Prelude

import Data.Nullable (Nullable)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Playground.Types (Actions, File, Viewer)

foreign import fileTabsImpl ::
  ReactComponent
    { files :: Array File
    , active :: Nullable String
    , viewing :: Nullable Viewer
    , actions :: Actions
    , rootClassName :: String
    , tabClassName :: String
    , activeTabClassName :: String
    , nameClassName :: String
    , errorCountClassName :: String
    , warningCountClassName :: String
    , iconButtonClassName :: String
    , inputClassName :: String
    , errorClassName :: String
    , addClassName :: String
    }

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
      , paddingInlineStart: 14
      , paddingInlineEnd: 8
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
  , iconButton:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 4
      , borderStyle: "none"
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 12
      , height: 24
      , justifyContent: "center"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , width: 24
      }
  , input:
      { alignSelf: "center"
      , backgroundColor: "var(--granite-950)"
      , borderColor: "var(--accent)"
      , borderRadius: 4
      , borderStyle: "solid"
      , borderWidth: 1
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , height: 28
      , marginInline: 8
      , outlineStyle: "none"
      , paddingInline: 8
      }
  , error:
      { backgroundColor: "var(--red-300)"
      , color: "var(--granite-950)"
      , fontSize: 12
      , fontWeight: 500
      , paddingBlock: 6
      , paddingInline: 10
      , position: "fixed"
      , whiteSpace: "nowrap"
      , zIndex: 10
      }
  , add:
      { alignItems: "center"
      , alignSelf: "stretch"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderStyle: "none"
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , flexShrink: 0
      , fontSize: 14
      , justifyContent: "center"
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , width: 44
      }
  }

styleProps = StyleX.recordProps styles

-- | The project's files as tabs, with controls to add, rename and delete them.
fileTabs ::
  { files :: Array File
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , actions :: Actions
  } -> JSX
fileTabs { files, active, viewing, actions } = element fileTabsImpl
  { files
  , active
  , viewing
  , actions
  , rootClassName: styleProps.root.className
  , tabClassName: styleProps.tab.className
  , activeTabClassName: (StyleX.props [ styles.tab, styles.activeTab ]).className
  , nameClassName: styleProps.name.className
  , errorCountClassName: (StyleX.props [ styles.count, styles.errorCount ]).className
  , warningCountClassName: (StyleX.props [ styles.count, styles.warningCount ]).className
  , iconButtonClassName: styleProps.iconButton.className
  , inputClassName: styleProps.input.className
  , errorClassName: styleProps.error.className
  , addClassName: styleProps.add.className
  }
