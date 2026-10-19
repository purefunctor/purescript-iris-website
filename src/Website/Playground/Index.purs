module Website.Playground.Index (component) where

import Prelude

import Data.Array (null)
import Data.Maybe (Maybe(..), fromMaybe)
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
import Website.Components.SiteNav as SiteNav
import Website.Playground.FileTabs (fileTabs)
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
      , display: "grid"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , gridTemplateRows: "var(--nav-height) minmax(0, 1fr)"
      , height:
          StyleX.conditionalValue "100dvh" [ StyleX.conditionalCase breakpoints.upTo960 "auto" ]
      , minHeight: "100dvh"
      }
  , navigation: { alignSelf: "stretch", display: "flex", flexGrow: 1, minWidth: 0 }
  -- The editor and its panel meet at a hard edge; the panel drops below the editor on narrow
  -- screens.
  , workspace:
      { display: "grid"
      , gridTemplateColumns: StyleX.conditionalValue "minmax(0, 1fr) minmax(320px, 400px)"
          [ StyleX.conditionalCase breakpoints.upTo960 "minmax(0, 1fr)" ]
      , gridTemplateRows: StyleX.conditionalValue "auto minmax(0, 1fr)"
          [ StyleX.conditionalCase breakpoints.upTo960 "auto 62dvh auto" ]
      , minHeight: 0
      , position: "relative"
      }
  , toolbar:
      { alignItems: "stretch"
      , backgroundColor: "var(--granite-950)"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexWrap:
          StyleX.conditionalValue "nowrap" [ StyleX.conditionalCase breakpoints.upTo600 "wrap" ]
      , gridColumn: "1 / -1"
      , minHeight: 48
      , minWidth: 0
      }
  , actions:
      { alignItems: "center"
      , display: "flex"
      , flexShrink: 0
      , gap: 8
      , justifyContent: "flex-end"
      , marginInlineStart: "auto"
      , paddingBlock: 8
      , paddingInline: 12
      , width: StyleX.conditionalValue "auto" [ StyleX.conditionalCase breakpoints.upTo600 "100%" ]
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle:
          StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo600 "solid" ]
      , borderBlockStartWidth: 1
      }
  , editor:
      { backgroundColor: "var(--granite-900)", minHeight: 0, minWidth: 0, position: "relative" }
  , editorHost: { inset: 0, position: "absolute" }
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
      , minHeight: StyleX.conditionalValue 0 [ StyleX.conditionalCase breakpoints.upTo960 360 ]
      , minWidth: 0
      }
  , tabs: { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0 }
  , tabList:
      { borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , height: 44
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
      , fontWeight: 600
      , paddingInline: 16
      }
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
  , frames: { height: 0, overflow: "hidden", position: "absolute", width: 0 }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent { theme :: Foreign }
component = unsafePerformEffect $ Hooks.reactComponent "Playground" \{ theme } ->
  pure $ element playgroundImpl { theme, render: playground }

playground :: View -> JSX
playground { state, actions, editor, frames } = DOM.div styleProps.page
  [ SiteNav.siteHeader { contained: false }
      [ DOM.nav { className: styleProps.navigation.className, "aria-label": "Iris" }
          [ SiteNav.headerLink
              { href: "/docs/getting-started/", label: "Documentation", current: false }
          , SiteNav.headerLink { href: "/playground/", label: "Playground", current: true }
          ]
      ]
  -- The children keep their positions in every phase, so that React keeps the editor host that
  -- the controller fills once loading finishes.
  , DOM.main styleProps.workspace
      [ if ready then toolbar else mempty
      , DOM.div styleProps.editor
          [ DOM.div { className: styleProps.editorHost.className, ref: DOM.reactRef editor } [] ]
      , if ready then panel else mempty
      , if ready then mempty else loading state actions.retry
      , DOM.div { className: styleProps.frames.className, ref: DOM.reactRef frames } []
      ]
  ]
  where
  ready = state.phase == "ready"

  toolbar = DOM.div styleProps.toolbar
    [ fileTabs { files: state.files, active: state.active, viewing: state.viewing, actions }
    , DOM.div styleProps.actions
        [ status state
        , iconAction "Reset to the example" Icon.rotateCcw actions.reset
        , DOM.button
            { className: styleProps.action.className
            , onClick: handler_ actions.share
            , type: "button"
            }
            [ DOM.span styleProps.icon (icon Icon.share)
            , DOM.text (if state.shared then "Link copied" else "Share")
            ]
        , runButton state actions.run actions.stop
        ]
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
runButton state run stop = case state.run.status of
  "running" -> button false stop Icon.square "Stop" [ styles.action ]
  "compiling" -> button true run Icon.play "Compiling" [ styles.action, styles.run ]
  _ -> button (state.server.status /= "ready") run Icon.play "Run" [ styles.action, styles.run ]
  where
  button disabled onPress icon' label style = DOM.button
    { className: (StyleX.props style).className
    , disabled
    , onClick: handler_ onPress
    , type: "button"
    }
    [ DOM.span styleProps.icon (icon icon'), DOM.text label ]

status :: State -> JSX
status state = DOM.span
  { className: (StyleX.props [ styles.status, tone ]).className
  , role: "status"
  , title: fromMaybe label (toMaybe state.server.message)
  }
  label
  where
  server = state.server
  version = fromMaybe "" (toMaybe server.version)
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
