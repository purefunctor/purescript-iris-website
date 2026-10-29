module Website.Playground.FileTabs (fileTabs) where

import Prelude

import Data.Array (find)
import Data.Maybe (Maybe(..), fromMaybe, isNothing, maybe)
import Data.Nullable (Nullable, toMaybe)
import Data.String (Pattern(..), stripPrefix)
import Effect (Effect)
import Iris.StyleX as StyleX
import Iris.StyleX.When as When
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (handler_)
import Website.Playground.Types (Actions, File, Viewer)
import Yoga.React.DOM as DOM

foreign import lockIcon :: ReactComponent { "aria-label" :: String }

foreign import closeIcon :: ReactComponent { "aria-hidden" :: Boolean }

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

type FileTabsProps =
  { files :: Array File
  , open :: Array String
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , actions :: Actions
  }

fileTabs :: FileTabsProps -> JSX
fileTabs props =
  DOM.div { className: styleProps.root.className, role: "group", "aria-label": "Open files" }
    ( map (openFileTab props) props.open
        <> [ maybe mempty (viewerTab props.actions) (toMaybe props.viewing) ]
    )

openFileTab :: FileTabsProps -> String -> JSX
openFileTab props path =
  let
    selected :: Boolean
    selected = isNothing (toMaybe props.viewing) && toMaybe props.active == Just path
  in
    DOM.div { className: tabClassName selected, key: path }
      [ DOM.button
          { "aria-current": if selected then "true" else "false"
          , className: styleProps.name.className
          , onClick: handler_ (props.actions.openFile path)
          , title: path
          , type: "button"
          }
          [ DOM.text (label path)
          , case find (\file -> file.path == path) props.files of
              Just file
                | file.errors > 0 -> countBadge styles.errorCount file.errors "errors"
                | file.warnings > 0 -> countBadge styles.warningCount file.warnings "warnings"
              _ -> mempty
          ]
      , closeButton selected ("Close " <> label path) (props.actions.closeFile path)
      ]

viewerTab :: Actions -> Viewer -> JSX
viewerTab actions viewer = DOM.div { className: tabClassName true }
  [ DOM.span
      { "aria-current": "true"
      , className: styleProps.name.className
      , title: viewer.uri <> " (read-only)"
      }
      [ element lockIcon { "aria-label": "Read-only" }, DOM.text viewer.label ]
  , closeButton true ("Close " <> viewer.label) actions.closeViewer
  ]

tabClassName :: Boolean -> String
tabClassName selected =
  ( StyleX.props [ styles.tab, StyleX.conditional selected styles.activeTab, StyleX.defaultMarker ]
  ).className

countBadge :: StyleX.Style -> Int -> String -> JSX
countBadge tone count noun = DOM.span
  { className: (StyleX.props [ styles.count, tone ]).className
  , "aria-label": show count <> " " <> noun
  }
  (show count)

closeButton :: Boolean -> String -> Effect Unit -> JSX
closeButton selected accessibleLabel onClose = DOM.button
  { "aria-label": accessibleLabel
  , className:
      (StyleX.props [ styles.close, StyleX.conditional selected styles.activeClose ]).className
  , onClick: handler_ onClose
  , title: "Close"
  , type: "button"
  }
  (element closeIcon { "aria-hidden": true })

label :: String -> String
label path = fromMaybe path (stripPrefix (Pattern "src/") path)
