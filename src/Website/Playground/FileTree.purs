module Website.Playground.FileTree (fileTree) where

import Prelude

import Data.Nullable (Nullable)
import Iris.StyleX as StyleX
import Iris.StyleX.When as When
import React.Basic (JSX, ReactComponent, element)
import Website.Playground.Types (Actions, File, Viewer)

foreign import fileTreeImpl ::
  ReactComponent
    { files :: Array File
    , active :: Nullable String
    , viewing :: Nullable Viewer
    , actions :: Actions
    , rootClassName :: String
    , headerClassName :: String
    , titleClassName :: String
    , newFileClassName :: String
    , scrollClassName :: String
    , listClassName :: String
    , folderClassName :: String
    , itemClassName :: String
    , rowClassName :: String
    , activeRowClassName :: String
    , chevronClassName :: String
    , openChevronClassName :: String
    , iconClassName :: String
    , nameClassName :: String
    , errorCountClassName :: String
    , warningCountClassName :: String
    , errorDotClassName :: String
    , actionsClassName :: String
    , actionClassName :: String
    , inputClassName :: String
    , problemClassName :: String
    }

listIn = StyleX.keyframes
  { from: { opacity: 0, transform: "translateY(-3px)" }, to: { opacity: 1, transform: "none" } }

styles = StyleX.create
  { root:
      { backgroundColor: "var(--granite-950)"
      , display: "flex"
      , flexDirection: "column"
      , height: "100%"
      , minHeight: 0
      }
  , header:
      { alignItems: "center"
      , display: "flex"
      , flexShrink: 0
      , height: 36
      , justifyContent: "space-between"
      , paddingInlineEnd: 6
      , paddingInlineStart: 14
      }
  , title: { color: "var(--text-tertiary)", fontSize: 12, fontWeight: 600, margin: 0 }
  , scroll: { flexGrow: 1, minHeight: 0, overflowY: "auto", paddingBlockEnd: 12 }
  -- An expanded folder's files settle in below it.
  , list:
      { animationDuration: "180ms"
      , animationName: { default: listIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      , listStyle: "none"
      , margin: 0
      , padding: 0
      }
  , item: { position: "relative" }
  -- Rows indent by the depth that the tree sets as a variable on each row.
  , row:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderStyle: "none"
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , gap: 6
      , height: 28
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingInlineEnd: 64
      , paddingInlineStart: "calc(10px + var(--depth) * 14px)"
      , textAlign: "start"
      , transitionDuration: "120ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      , width: "100%"
      }
  , activeRow:
      { backgroundColor: { default: "var(--surface-2)", ":hover": "var(--surface-2)" }
      , boxShadow: "inset 2px 0 0 var(--accent)"
      , color: { default: "var(--text-primary)", ":hover": "var(--text-primary)" }
      }
  , chevron:
      { color: "var(--text-tertiary)"
      , flexShrink: 0
      , fontSize: 14
      , transitionDuration: { default: "120ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "transform"
      }
  , openChevron: { transform: "rotate(90deg)" }
  , icon: { flexShrink: 0, height: 16, width: 16 }
  , name: { minWidth: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }
  , count:
      { borderRadius: 999
      , flexShrink: 0
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
  , errorDot:
      { backgroundColor: "var(--red-300)", borderRadius: 999, flexShrink: 0, height: 7, width: 7 }
  -- A file's actions show while its row is hovered or focused, and always on touch screens.
  , actions:
      { display: "flex"
      , gap: 2
      , insetBlockStart: 2
      , insetInlineEnd: 6
      , opacity: StyleX.conditionalValue 0.0
          [ When.ancestor ":hover" 1.0
          , When.ancestor ":focus-within" 1.0
          , StyleX.conditionalCase "@media (hover: none)" 1.0
          ]
      , position: "absolute"
      , transitionDuration: { default: "120ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "opacity"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , action:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-3)" }
      , borderRadius: 4
      , borderStyle: "none"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 12
      , height: 24
      , justifyContent: "center"
      , outline: { default: "revert", ":focus-visible": "none" }
      , width: 24
      }
  , input:
      { backgroundColor: "var(--granite-950)"
      , borderColor: "var(--accent)"
      , borderRadius: 4
      , borderStyle: "solid"
      , borderWidth: 1
      , boxSizing: "border-box"
      , color: "var(--text-primary)"
      , display: "block"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , height: 28
      , marginInlineStart: "calc(6px + var(--depth) * 14px)"
      , outlineStyle: "none"
      , paddingInline: 6
      , width: "calc(100% - 12px - var(--depth) * 14px)"
      }
  , problem:
      { backgroundColor: "var(--red-300)"
      , color: "var(--granite-950)"
      , fontSize: 12
      , fontWeight: 500
      , maxWidth: 320
      , paddingBlock: 6
      , paddingInline: 10
      , position: "fixed"
      , zIndex: 30
      }
  }

styleProps = StyleX.recordProps styles

-- | The project's files as a tree of the folders in their paths.
fileTree ::
  { files :: Array File
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , actions :: Actions
  } -> JSX
fileTree { files, active, viewing, actions } = element fileTreeImpl
  { files
  , active
  , viewing
  , actions
  , rootClassName: styleProps.root.className
  , headerClassName: styleProps.header.className
  , titleClassName: styleProps.title.className
  , newFileClassName: styleProps.action.className
  , scrollClassName: styleProps.scroll.className
  , listClassName: styleProps.list.className
  -- Only file items carry the marker, so hovering a file reveals that file's actions alone.
  , folderClassName: styleProps.item.className
  , itemClassName: (StyleX.props [ styles.item, StyleX.defaultMarker ]).className
  , rowClassName: styleProps.row.className
  , activeRowClassName: (StyleX.props [ styles.row, styles.activeRow ]).className
  , chevronClassName: styleProps.chevron.className
  , openChevronClassName: (StyleX.props [ styles.chevron, styles.openChevron ]).className
  , iconClassName: styleProps.icon.className
  , nameClassName: styleProps.name.className
  , errorCountClassName: (StyleX.props [ styles.count, styles.errorCount ]).className
  , warningCountClassName: (StyleX.props [ styles.count, styles.warningCount ]).className
  , errorDotClassName: styleProps.errorDot.className
  , actionsClassName: styleProps.actions.className
  , actionClassName: styleProps.action.className
  , inputClassName: styleProps.input.className
  , problemClassName: styleProps.problem.className
  }
