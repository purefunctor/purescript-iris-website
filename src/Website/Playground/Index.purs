module Website.Playground.Index (component) where

import Prelude

import Data.Array (null)
import Data.Maybe (Maybe(..), fromMaybe, isNothing, maybe)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (handler_)
import React.Basic.Hooks as Hooks
import Website.Breakpoints (breakpoints)
import Website.Components.Icon as Icon
import Website.Components.Logo (logo)
import Website.Playground.FileTabs (fileTabs)
import Website.Playground.FileTree (fileTree)
import Website.Playground.Loading (loading)
import Website.Playground.Packages (packagesPanel)
import Website.Playground.Types (Line, Run, State, View)
import Yoga.React.DOM as DOM

foreign import playgroundImpl :: ReactComponent { theme :: Foreign, render :: View -> JSX }

foreign import panelTabsImpl ::
  ReactComponent
    { rootClassName :: String
    , tabListClassName :: String
    , tabClassName :: String
    , panelClassName :: String
    , badgeClassName :: String
    , output :: JSX
    , outputBadge :: String
    , packages :: JSX
    , packagesBadge :: String
    }

styles = StyleX.create
  { page:
      { backgroundColor: "var(--bg-canvas)"
      , color: "var(--text-primary)"
      , display: "flex"
      , flexDirection: "column"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , height: "100dvh"
      }
  -- The playground's own header replaces the site navigation: the brand leads home, and the
  -- project's controls take the rest of the row.
  , header:
      { alignItems: "center"
      , backgroundColor: "var(--granite-950)"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , gap: StyleX.conditionalValue 10 [ StyleX.conditionalCase breakpoints.upTo600 6 ]
      , height: "var(--nav-height)"
      , paddingInline: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo600 10 ]
      }
  , brand:
      { alignItems: "center"
      , color: "var(--text-primary)"
      , cursor: "default"
      , display: "inline-flex"
      , gap: 7
      , lineHeight: 1
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , marginInlineEnd: StyleX.conditionalValue 6 [ StyleX.conditionalCase breakpoints.upTo600 0 ]
      , outline: { default: "revert", ":focus-visible": "none" }
      , textDecoration: "none"
      }
  , logo: { flexShrink: 0, height: 24, width: 24 }
  , wordmark:
      { display:
          StyleX.conditionalValue "inline" [ StyleX.conditionalCase breakpoints.upTo600 "none" ]
      , fontSize: 19
      , fontWeight: 900
      , letterSpacing: "-0.04em"
      }
  , controls:
      { alignItems: "center"
      , display: "flex"
      , flexGrow: 1
      , gap: StyleX.conditionalValue 8 [ StyleX.conditionalCase breakpoints.upTo600 6 ]
      , minWidth: 0
      }
  , spacer: { flexGrow: 1 }
  , toggled: { backgroundColor: { default: "var(--surface-3)", ":hover": "var(--surface-3)" } }
  -- The editor and its panel meet at a hard edge; the panel drops below the editor on narrow
  -- screens.
  , workspace:
      { display: "flex"
      , flexDirection:
          StyleX.conditionalValue "row" [ StyleX.conditionalCase breakpoints.upTo960 "column" ]
      , flexGrow: 1
      , minHeight: 0
      , position: "relative"
      }
  , upper:
      { display: "flex"
      , flexBasis: 0
      , flexGrow: 1
      , minHeight: 0
      , minWidth: 0
      , position: "relative"
      }
  -- The sidebar sits beside the editor, and over it on phones.
  , sidebar:
      { borderInlineEndColor: StyleX.conditionalValue "var(--border-subtle)"
          [ StyleX.conditionalCase breakpoints.upTo720 "var(--border-strong)" ]
      , borderInlineEndStyle: "solid"
      , borderInlineEndWidth: 1
      , flexShrink: 0
      , insetBlock: 0
      , insetInlineStart: 0
      , position: StyleX.conditionalValue "relative"
          [ StyleX.conditionalCase breakpoints.upTo720 "absolute" ]
      , width: StyleX.conditionalValue "240px"
          [ StyleX.conditionalCase breakpoints.upTo720 "min(300px, 85vw)" ]
      , zIndex: 3
      }
  , editorColumn:
      { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0, minWidth: 0 }
  , tabsRow:
      { backgroundColor: "var(--granite-950)"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , height: 36
      , minWidth: 0
      }
  , editor:
      { backgroundColor: "var(--granite-900)", flexGrow: 1, minHeight: 0, position: "relative" }
  , editorHost: { inset: 0, position: "absolute" }
  , noFile:
      { alignItems: "center"
      , color: "var(--text-tertiary)"
      , display: "flex"
      , fontSize: 14
      , inset: 0
      , justifyContent: "center"
      , margin: 0
      , position: "absolute"
      }
  , panel:
      { backgroundColor: "var(--granite-950)"
      , borderInlineStartColor: "var(--border-subtle)"
      , borderInlineStartStyle:
          StyleX.conditionalValue "solid" [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
      , borderInlineStartWidth: 1
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle:
          StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo960 "solid" ]
      , borderBlockStartWidth: 1
      , display: "flex"
      , flexDirection: "column"
      , flexShrink: 0
      , height:
          StyleX.conditionalValue "auto" [ StyleX.conditionalCase breakpoints.upTo960 "40dvh" ]
      , minHeight: 0
      , minWidth: 0
      , width: StyleX.conditionalValue "380px" [ StyleX.conditionalCase breakpoints.upTo960 "100%" ]
      }
  , tabs: { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0 }
  , tabList:
      { borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , height: 36
      }
  , tab:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , boxShadow: { default: "none", "[data-selected]": "inset 0 -2px 0 var(--accent)" }
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--text-primary)"
          , "[data-selected]": "var(--text-primary)"
          }
      , cursor: "default"
      , display: "flex"
      , fontSize: 13
      , fontWeight: 500
      , gap: 8
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", "[data-focus-visible]": "solid" }
      , outlineWidth: 2
      , paddingInline: 16
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , badge:
      { backgroundColor: "var(--surface-3)"
      , borderRadius: 999
      , color: "var(--text-primary)"
      , fontSize: 11
      , fontWeight: 600
      , lineHeight: "16px"
      , minWidth: 16
      , paddingInline: 5
      , textAlign: "center"
      }
  , tabPanel:
      { display: "flex"
      , flexDirection: "column"
      , flexGrow: 1
      , minHeight: 0
      , outlineStyle: "none"
      , overflowY: "auto"
      }
  -- Status pills are sans-serif with flat, high-contrast fills.
  , status:
      { alignItems: "center"
      , borderRadius: 999
      , color: "var(--granite-950)"
      , display: "inline-flex"
      , fontSize: 12
      , fontWeight: 600
      , gap: 6
      , height: 26
      , maxWidth: 280
      , overflow: "hidden"
      , paddingInline: 11
      , textOverflow: "ellipsis"
      , whiteSpace: "nowrap"
      }
  , statusReady: { backgroundColor: "var(--green-400)" }
  , statusMock: { backgroundColor: "var(--yellow-400)" }
  , statusBusy:
      { backgroundColor: "var(--surface-2)"
      , boxShadow: "inset 0 0 0 1px var(--border-default)"
      , color: "var(--text-primary)"
      }
  , statusFailed: { backgroundColor: "var(--red-300)" }
  -- Transparent actions keep a subtle fill beside the tabs and strengthen it on hover.
  , action:
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
  , iconOnly: { paddingInline: 0, justifyContent: "center", width: 32 }
  , run:
      { backgroundColor:
          { default: "var(--accent)"
          , ":hover": "var(--accent-hover)"
          , ":active": "var(--accent-press)"
          , ":disabled": "var(--surface-2)"
          }
      , color: { default: "var(--text-on-accent)", ":disabled": "var(--text-tertiary)" }
      }
  -- Stop keeps Run's weight and padding, so only the color changes.
  , runShape: { fontWeight: 600, paddingInline: 16 }
  , icon: { display: "inline-flex", fontSize: 12 }
  , output:
      { display: "flex"
      , flexDirection: "column"
      , flexGrow: 1
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , lineHeight: 1.6
      , minHeight: 0
      }
  , outputHeader:
      { alignItems: "center"
      , color: "var(--text-tertiary)"
      , display: "flex"
      , fontFamily: "var(--font-sans)"
      , fontSize: 12
      , gap: 8
      , justifyContent: "space-between"
      , paddingBlock: 8
      , paddingInline: 16
      }
  , clear:
      { backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 999
      , borderStyle: "none"
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , fontFamily: "var(--font-sans)"
      , fontSize: 12
      , height: 24
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingInline: 10
      }
  , lines: { margin: 0, paddingBlockEnd: 16, paddingInline: 16 }
  , line: { overflowWrap: "anywhere", whiteSpace: "pre-wrap" }
  , logLine: { color: "var(--text-secondary)" }
  , infoLine: { color: "var(--text-tertiary)" }
  , warningLine: { color: "var(--yellow-300)" }
  , errorLine: { color: "var(--red-300)" }
  , empty:
      { color: "var(--text-tertiary)"
      , fontFamily: "var(--font-sans)"
      , fontSize: 13
      , lineHeight: 1.6
      , paddingInline: 16
      }
  , packageSet:
      { backgroundColor: "var(--granite-100)"
      , display: StyleX.conditionalValue "inline-flex"
          [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
      }
  -- Run, Compiling and Stop share one grid cell, so the button keeps the widest label's width.
  , runLabels: { display: "grid" }
  , runLabel:
      { alignItems: "center"
      , display: "inline-flex"
      , gap: 6
      , gridArea: "1 / 1"
      , justifyContent: "center"
      }
  , inactiveLabel: { visibility: "hidden" }
  , shareLabel:
      { display:
          StyleX.conditionalValue "inline" [ StyleX.conditionalCase breakpoints.upTo600 "none" ]
      }
  , frames: { height: 0, overflow: "hidden", position: "absolute", width: 0 }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent { theme :: Foreign }
component = unsafePerformEffect $ Hooks.reactComponent "Playground" \{ theme } ->
  pure $ element playgroundImpl { theme, render: playground }

playground :: View -> JSX
playground { state, actions, editor, frames } = DOM.div styleProps.page
  [ DOM.header styleProps.header
      [ DOM.a { className: styleProps.brand.className, href: "/", "aria-label": "Iris home" }
          [ logo { className: styleProps.logo.className }, DOM.span styleProps.wordmark "IRIS" ]
      , if ready then controls else mempty
      ]
  -- The children keep their positions in every phase, so that React keeps the editor host that
  -- the controller fills once loading finishes.
  , DOM.main styleProps.workspace
      [ DOM.div styleProps.upper
          [ if ready && state.sidebar then sidebar else mempty
          , DOM.div styleProps.editorColumn
              [ if ready then tabs else mempty
              , DOM.div styleProps.editor
                  [ DOM.div { className: styleProps.editorHost.className, ref: DOM.reactRef editor }
                      []
                  , if ready && noFile
                    then DOM.p styleProps.noFile "Open a file from Files."
                    else mempty
                  ]
              ]
          ]
      , if ready then panel else mempty
      , if ready then mempty else loading state actions.retry
      , DOM.div { className: styleProps.frames.className, ref: DOM.reactRef frames } []
      ]
  ]
  where
  ready = state.phase == "ready"
  noFile = isNothing (toMaybe state.active) && isNothing (toMaybe state.viewing)

  controls = DOM.div styleProps.controls
    [ DOM.button
        { className:
            ( StyleX.props
                [ styles.action, styles.iconOnly, StyleX.conditional state.sidebar styles.toggled ]
            ).className
        , onClick: handler_ actions.toggleSidebar
        , title: if state.sidebar then "Hide files" else "Show files"
        , type: "button"
        , "aria-controls": "playground-sidebar"
        , "aria-expanded": state.sidebar
        , "aria-label": "Files"
        }
        (DOM.span styleProps.icon (icon Icon.panelLeft))
    , DOM.div styleProps.spacer []
    , status state
    , case toMaybe state.packages.packageSet of
        Just packageSet -> DOM.span (StyleX.props [ styles.status, styles.packageSet ])
          ("Package set " <> packageSet)
        Nothing -> mempty
    , iconAction "Reset to the example" Icon.rotateCcw actions.reset
    , DOM.button
        { className: styleProps.action.className
        , onClick: handler_ actions.share
        , title: "Copy a link to this project"
        , type: "button"
        , "aria-label": if state.shared then "Link copied" else "Share"
        }
        [ DOM.span styleProps.icon (icon Icon.share)
        , DOM.span styleProps.shareLabel (if state.shared then "Link copied" else "Share")
        ]
    , runButton state actions.run actions.stop
    ]

  sidebar = DOM.div { className: styleProps.sidebar.className, id: "playground-sidebar" }
    [ fileTree { files: state.files, active: state.active, viewing: state.viewing, actions } ]

  tabs = DOM.div styleProps.tabsRow
    [ fileTabs
        { files: state.files
        , open: state.open
        , active: state.active
        , viewing: state.viewing
        , actions
        }
    ]

  panel = DOM.aside { className: styleProps.panel.className, "aria-label": "Output and packages" }
    [ element panelTabsImpl
        { rootClassName: styleProps.tabs.className
        , tabListClassName: styleProps.tabList.className
        , tabClassName: styleProps.tab.className
        , panelClassName: styleProps.tabPanel.className
        , badgeClassName: styleProps.badge.className
        , output: output state.run actions.clearOutput
        , outputBadge: ""
        , packages: packagesPanel { packages: state.packages }
        , packagesBadge: ""
        }
    ]

icon :: ReactComponent Icon.IconProps -> JSX
icon component' = element component' { "aria-hidden": true, focusable: false }

iconAction :: String -> ReactComponent Icon.IconProps -> Effect Unit -> JSX
iconAction label icon' onPress = DOM.button
  { className: (StyleX.props [ styles.action, styles.iconOnly ]).className
  , onClick: handler_ onPress
  , title: label
  , type: "button"
  , "aria-label": label
  }
  (DOM.span styleProps.icon (icon icon'))

runButton :: State -> Effect Unit -> Effect Unit -> JSX
runButton state run stop = DOM.button
  { className:
      ( StyleX.props [ styles.action, styles.runShape, StyleX.conditional (not running) styles.run ]
      ).className
  , disabled: compiling || state.server.status /= "ready" && not running
  , onClick: handler_ (if running then stop else run)
  , type: "button"
  }
  ( DOM.span styleProps.runLabels
      [ label "Run" Icon.play (not running && not compiling)
      , label "Compiling" Icon.play compiling
      , label "Stop" Icon.square running
      ]
  )
  where
  running = state.run.status == "running"
  compiling = state.run.status == "compiling"
  label text icon' current = DOM.span
    { className:
        ( StyleX.props [ styles.runLabel, StyleX.conditional (not current) styles.inactiveLabel ]
        ).className
    , "aria-hidden": not current
    }
    [ DOM.span styleProps.icon (icon icon'), DOM.text text ]

status :: State -> JSX
status state = DOM.span
  { className: (StyleX.props [ styles.status, tone ]).className
  , role: "status"
  , title: fromMaybe (label <> revision) (toMaybe state.server.message)
  }
  label
  where
  server = state.server
  version = fromMaybe "" (toMaybe server.version)
  revision = maybe "" (\commit -> " (" <> commit <> ")") (toMaybe server.revision)
  { label, tone } = case server.status, toMaybe server.kind of
    "failed", _ -> { label: "Language server stopped", tone: styles.statusFailed }
    "restarting", _ -> { label: "Restarting the language server", tone: styles.statusBusy }
    "starting", _ -> { label: "Starting the language server", tone: styles.statusBusy }
    _, Just "mock" -> { label: "Mock language server", tone: styles.statusMock }
    _, _ -> { label: "Iris " <> version, tone: styles.statusReady }

output :: Run -> Effect Unit -> JSX
output run clear = DOM.div styleProps.output
  [ DOM.div styleProps.outputHeader
      [ DOM.span {} (runLabel run.status)
      , if null run.lines
        then mempty
        else DOM.button
          { className: styleProps.clear.className, onClick: handler_ clear, type: "button" } "Clear"
      ]
  , if null run.lines
    then DOM.p styleProps.empty "Run the project to see what main prints."
    else DOM.div { className: styleProps.lines.className, role: "log", "aria-live": "polite" }
      (map outputLine run.lines)
  ]

runLabel :: String -> String
runLabel = case _ of
  "compiling" -> "Compiling…"
  "running" -> "Running"
  "done" -> "main returned"
  "stopped" -> "Stopped"
  "failed" -> "Failed"
  _ -> "Output"

outputLine :: Line -> JSX
outputLine line = DOM.div (StyleX.props [ styles.line, tone ]) line.text
  where
  tone = case line.kind of
    "error" -> styles.errorLine
    "warning" -> styles.warningLine
    "info" -> styles.infoLine
    _ -> styles.logLine
