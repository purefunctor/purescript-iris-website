module Website.Playground.Index (component) where

import Prelude

import Data.Array (null)
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (handler_)
import React.Basic.Hooks as Hooks
import Website.Breakpoints (breakpoints)
import Website.Components.ExternalLink (newTabLabel)
import Website.Components.Icon as Icon
import Website.Components.IconButton.Styles (iconButtonStyles)
import Website.Playground.FileTabs (fileTabs)
import Website.Playground.FileTree (fileTree)
import Website.Playground.Loading (loading)
import Website.Playground.Packages (packagesPanel)
import Website.Playground.Types (Line, Run, State, View)
import Yoga.React.DOM as DOM

foreign import playgroundImpl :: ReactComponent { theme :: Foreign, render :: View -> JSX }

foreign import sidebarImpl ::
  ReactComponent
    { id :: String
    , open :: Boolean
    , width :: Int
    , resize :: Int -> Effect Unit
    , close :: Effect Unit
    , className :: String
    , handleClassName :: String
    , children :: JSX
    }

-- | A status pill with a tooltip. An empty `href` makes it a focusable label instead of a link.
foreign import pillImpl ::
  ReactComponent
    { href :: String
    , label :: String
    , accessibleLabel :: String
    , tooltip :: String
    , className :: String
    , iconClassName :: String
    , tooltipClassName :: String
    }

foreign import panelImpl ::
  ReactComponent
    { open :: Boolean, id :: String, label :: String, className :: String, children :: JSX }

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
  -- The playground's own header replaces the site navigation with the project's controls.
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
  -- Motion stays short and eases out, and reduced motion turns it off. The controls rise in once
  -- the playground is ready, as the workspace fades in below them.
  , controls:
      { alignItems: "center"
      , animationDuration: "260ms"
      , animationName: { default: rise, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
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
  , revealed:
      { animationDuration: "320ms"
      , animationName: { default: fadeIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
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
      , width: StyleX.conditionalValue "var(--sidebar-width)"
          [ StyleX.conditionalCase breakpoints.upTo720 "min(300px, 85vw)" ]
      , zIndex: 3
      -- Opening and closing grow and shrink the sidebar, so the editor follows its edge.
      , animationDuration: "200ms"
      , animationFillMode: "forwards"
      , animationName: { default: "none", "[data-entering]": widthIn, "[data-exiting]": widthOut }
      , animationTimingFunction: "var(--ease-out)"
      , overflow: "hidden"
      }
  -- The sidebar's edge, which drags to resize and closes it below a minimum width. Phones open
  -- the sidebar over the editor instead, so they have no handle.
  , handle:
      { backgroundColor:
          { default: "transparent"
          , ":hover": "var(--accent)"
          , ":focus-visible": "var(--focus-ring)"
          , "[data-dragging]": "var(--accent)"
          }
      , backgroundClip: "content-box"
      , cursor: "col-resize"
      , display:
          StyleX.conditionalValue "block" [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
      , insetBlock: 0
      , outlineStyle: "none"
      , paddingInline: 2
      , position: "absolute"
      , transitionDelay: { default: "0ms", ":hover": "150ms" }
      , transitionDuration: "120ms"
      , transitionProperty: "background-color"
      , width: 6
      , zIndex: 4
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
      -- The panel's size is its flex basis, which runs along the workspace beside the editor and
      -- down it below, so one animation opens the panel in both places.
      , flexBasis:
          StyleX.conditionalValue "380px" [ StyleX.conditionalCase breakpoints.upTo960 "40dvh" ]
      , flexShrink: 0
      , minHeight: 0
      , minWidth: 0
      , overflow: "hidden"
      , animationDuration: "220ms"
      , animationFillMode: "forwards"
      , animationName: { default: "none", "[data-entering]": basisIn, "[data-exiting]": basisOut }
      , animationTimingFunction: "var(--ease-out)"
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
  -- Switching between Output and Packages fades the new panel in.
  , tabPanel:
      { animationDuration: "160ms"
      , animationName: { default: fadeIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      , display: "flex"
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
  -- The ready pill links to the release, so it brightens on hover like the other controls.
  -- The version and package set pills are raised like the Run key, from their own hues. The
  -- version links to its release, so it also brightens on hover and sinks while pressed.
  , statusLink:
      { backgroundColor: "var(--green-400)"
      , backgroundImage:
          { default:
              "linear-gradient(oklch(from var(--green-400) calc(l + 0.04) c h), oklch(from var(--green-400) calc(l - 0.04) c h))"
          , ":hover":
              "linear-gradient(oklch(from var(--green-400) calc(l + 0.07) c h), oklch(from var(--green-400) calc(l - 0.01) c h))"
          , ":active":
              "linear-gradient(oklch(from var(--green-400) calc(l - 0.04) c h), oklch(from var(--green-400) calc(l + 0.01) c h))"
          }
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(from var(--green-300) calc(l + 0.06) c h / 70%), inset 0 -1px 0 oklch(from var(--green-400) calc(l - 0.3) c h / 55%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active": "inset 0 1px 3px oklch(from var(--green-400) calc(l - 0.35) c h / 65%)"
          , ":focus-visible":
              "inset 0 1px 0 oklch(from var(--green-300) calc(l + 0.06) c h / 70%), inset 0 -1px 0 oklch(from var(--green-400) calc(l - 0.3) c h / 55%), var(--shadow-focus)"
          }
      , cursor: "default"
      , outline: { default: "revert", ":focus-visible": "none" }
      , textDecoration: "none"
      , textShadow: "0 1px 0 oklch(from var(--green-300) calc(l + 0.06) c h / 45%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      }
  , commit: { fontFamily: "var(--font-mono)" }
  -- Lucide icons render at 1.2em, so the arrow sits a little smaller than the pill's label.
  , externalIcon: { flexShrink: 0, fontSize: 10, marginInlineStart: -1 }
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
  -- Run, Compiling and Stop are one raised key, as on audio equipment of the period: lit from
  -- above by a translucent sheen, with a lip below and an engraved label, sinking while pressed.
  -- Only its color changes between states, and colors and shadows interpolate, so the key eases
  -- from one state to the next. Its shadows keep one shape for that reason.
  , runShape:
      { backgroundColor: "var(--surface-2)"
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active":
              "inset 0 1px 3px oklch(0% 0 0 / 45%), inset 0 0 0 oklch(0% 0 0 / 0%), 0 0 0 oklch(0% 0 0 / 0%)"
          , ":focus-visible":
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), var(--shadow-focus)"
          , ":disabled":
              "inset 0 1px 0 oklch(100% 0 0 / 10%), inset 0 -1px 0 oklch(0% 0 0 / 25%), 0 1px 2px oklch(0% 0 0 / 35%)"
          }
      , color: "var(--text-tertiary)"
      , fontWeight: 600
      , paddingInline: 16
      , textShadow: "0 -1px 0 oklch(0% 0 0 / 35%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      , transitionDuration: "180ms, 180ms, 180ms, 180ms, 80ms"
      , transitionProperty: "background-color, box-shadow, color, text-shadow, transform"
      }
  , run:
      { backgroundColor:
          { default: "var(--accent)"
          , ":hover": "var(--accent-hover)"
          , ":active": "var(--accent-press)"
          }
      , color: "var(--text-on-accent)"
      , textShadow: "0 1px 0 oklch(from var(--signal-200) l c h / 45%)"
      }
  , stop:
      { backgroundColor:
          { default: "var(--surface-3)"
          , ":hover": "oklch(from var(--surface-3) calc(l + 0.04) c h)"
          , ":active": "var(--surface-2)"
          }
      , color: "var(--text-primary)"
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
  -- Each printed line settles in as it arrives.
  , line:
      { animationDuration: "180ms"
      , animationName: { default: rise, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      , overflowWrap: "anywhere"
      , whiteSpace: "pre-wrap"
      }
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
      { backgroundColor: "var(--blue-300)"
      , backgroundImage:
          "linear-gradient(oklch(from var(--blue-300) calc(l + 0.04) c h), oklch(from var(--blue-300) calc(l - 0.04) c h))"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(from var(--blue-300) calc(l + 0.1) calc(c - 0.04) h / 70%), inset 0 -1px 0 oklch(from var(--blue-300) calc(l - 0.32) c h / 55%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":focus-visible":
              "inset 0 1px 0 oklch(from var(--blue-300) calc(l + 0.1) calc(c - 0.04) h / 70%), inset 0 -1px 0 oklch(from var(--blue-300) calc(l - 0.32) c h / 55%), var(--shadow-focus)"
          }
      , outline: { default: "revert", ":focus-visible": "none" }
      , textShadow: "0 1px 0 oklch(from var(--blue-300) calc(l + 0.1) calc(c - 0.04) h / 45%)"
      , display: StyleX.conditionalValue "inline-flex"
          [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
      }
  -- Run and Stop, and Share and Copied, share one grid cell, so each button keeps its widest
  -- label's width. Compiling keeps the Run label and turns its icon into a spinner.
  , labels: { display: "grid" }
  , label:
      { alignItems: "center"
      , display: "inline-flex"
      , gap: 6
      , gridArea: "1 / 1"
      , justifyContent: "center"
      , transitionDuration: { default: "160ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "opacity, visibility"
      , transitionTimingFunction: "var(--ease-out)"
      }
  -- Labels crossfade, and a hidden one stays in the grid to hold the button's width.
  , inactiveLabel: { opacity: 0, visibility: "hidden" }
  , popped:
      { animationDuration: "240ms"
      , animationName: { default: pop, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      }
  -- The panel toggle's icon shows where the panel sits: beside the editor, or below it.
  , besidePanel:
      { display: StyleX.conditionalValue "inline-flex"
          [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
      }
  , belowPanel:
      { display: StyleX.conditionalValue "none"
          [ StyleX.conditionalCase breakpoints.upTo960 "inline-flex" ]
      }
  , shareLabels:
      { display:
          StyleX.conditionalValue "grid" [ StyleX.conditionalCase breakpoints.upTo600 "none" ]
      }
  , spinner:
      { animationDuration: "900ms"
      , animationIterationCount: "infinite"
      , animationName: { default: spin, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "linear"
      , display: "inline-flex"
      , fontSize: 12
      }
  , frames: { height: 0, overflow: "hidden", position: "absolute", width: 0 }
  }

styleProps = StyleX.recordProps styles

spin = StyleX.keyframes { from: { transform: "rotate(0deg)" }, to: { transform: "rotate(360deg)" } }

fadeIn = StyleX.keyframes { from: { opacity: 0 }, to: { opacity: 1 } }

rise = StyleX.keyframes
  { from: { opacity: 0, transform: "translateY(4px)" }, to: { opacity: 1, transform: "none" } }

pop = StyleX.keyframes
  { from: { transform: "scale(0.5)" }
  , "60%": { transform: "scale(1.15)" }
  , to: { transform: "none" }
  }

-- Without a `to` frame, these open to the element's own size.
widthIn = StyleX.keyframes { from: { width: 0 } }

widthOut = StyleX.keyframes { to: { width: 0 } }

basisIn = StyleX.keyframes { from: { flexBasis: 0 } }

basisOut = StyleX.keyframes { to: { flexBasis: 0 } }

component :: ReactComponent { theme :: Foreign }
component = unsafePerformEffect $ Hooks.reactComponent "Playground" \{ theme } ->
  pure $ element playgroundImpl { theme, render: playground }

playground :: View -> JSX
playground { state, actions, editor, frames } = DOM.div styleProps.page
  [ DOM.header styleProps.header [ if ready then controls else mempty ]
  -- The children keep their positions in every phase, so that React keeps the editor host that
  -- the controller fills once loading finishes.
  , DOM.main (StyleX.props [ styles.workspace, StyleX.conditional ready styles.revealed ])
      [ DOM.div styleProps.upper
          [ if ready then sidebar else mempty
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
        Just packageSet -> element pillImpl
          { href: ""
          , label: packageSet
          , accessibleLabel: "Package set " <> packageSet
          , tooltip: "Package set"
          , className: (StyleX.props [ styles.status, styles.packageSet ]).className
          , iconClassName: ""
          , tooltipClassName: (StyleX.props iconButtonStyles.tooltip).className
          }
        Nothing -> mempty
    , iconAction "Reset to the example" Icon.rotateCcw actions.reset
    , DOM.button
        { className: styleProps.action.className
        , onClick: handler_ actions.share
        , title: "Copy a link to this project"
        , type: "button"
        , "aria-label": if state.shared then "Copied" else "Share"
        }
        [ DOM.span (StyleX.props [ styles.icon, StyleX.conditional state.shared styles.popped ])
            (icon (if state.shared then Icon.check else Icon.share))
        , DOM.span (StyleX.props [ styles.labels, styles.shareLabels ])
            [ stackedLabel "Share" (not state.shared), stackedLabel "Copied" state.shared ]
        ]
    , runButton state actions.run actions.stop
    , DOM.button
        { className:
            ( StyleX.props
                [ styles.action, styles.iconOnly, StyleX.conditional state.panel styles.toggled ]
            ).className
        , onClick: handler_ actions.togglePanel
        , title: if state.panel then "Hide output" else "Show output"
        , type: "button"
        , "aria-controls": "playground-panel"
        , "aria-expanded": state.panel
        , "aria-label": "Output and packages"
        }
        [ DOM.span (StyleX.props [ styles.icon, styles.besidePanel ]) (icon Icon.panelRight)
        , DOM.span (StyleX.props [ styles.icon, styles.belowPanel ]) (icon Icon.panelBottom)
        ]
    ]

  sidebar = element sidebarImpl
    { id: "playground-sidebar"
    , open: state.sidebar
    , width: state.sidebarWidth
    , resize: actions.resizeSidebar
    , close: actions.closeSidebar
    , className: styleProps.sidebar.className
    , handleClassName: styleProps.handle.className
    , children:
        fileTree { files: state.files, active: state.active, viewing: state.viewing, actions }
    }

  tabs = DOM.div styleProps.tabsRow
    [ fileTabs
        { files: state.files
        , open: state.open
        , active: state.active
        , viewing: state.viewing
        , actions
        }
    ]

  panel = element panelImpl
    { open: state.panel
    , id: "playground-panel"
    , label: "Output and packages"
    , className: styleProps.panel.className
    , children: element panelTabsImpl
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
    }

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
      ( StyleX.props
          [ styles.action
          , styles.runShape
          , if running then styles.stop else if disabled then styles.runShape else styles.run
          ]
      ).className
  , disabled
  , onClick: handler_ (if running then stop else run)
  , type: "button"
  , "aria-label": if running then "Stop" else if compiling then "Compiling" else "Run"
  }
  ( DOM.span styleProps.labels
      [ label "Run" (not running)
          [ if compiling
            then DOM.span styleProps.spinner (icon Icon.loaderCircle)
            else DOM.span styleProps.icon (icon Icon.play)
          ]
      , label "Stop" running [ DOM.span styleProps.icon (icon Icon.square) ]
      ]
  )
  where
  running = state.run.status == "running"
  compiling = state.run.status == "compiling"
  disabled = compiling || state.server.status /= "ready" && not running
  label text current icons = DOM.span
    { className:
        ( StyleX.props [ styles.label, StyleX.conditional (not current) styles.inactiveLabel ]
        ).className
    , "aria-hidden": not current
    }
    (icons <> [ DOM.text text ])

-- | One of several labels that share a grid cell, so that a button keeps its widest label's
-- | width as the label changes.
stackedLabel :: String -> Boolean -> JSX
stackedLabel text current = DOM.span
  { className:
      ( StyleX.props [ styles.label, StyleX.conditional (not current) styles.inactiveLabel ]
      ).className
  , "aria-hidden": not current
  }
  text

status :: State -> JSX
status state = case server.status, toMaybe server.kind, toMaybe server.version of
  "failed", _, _ -> pill "Language server stopped" styles.statusFailed
  "restarting", _, _ -> pill "Restarting the language server" styles.statusBusy
  "starting", _, _ -> pill "Starting the language server" styles.statusBusy
  _, Just "mock", _ -> pill "Mock language server" styles.statusMock
  _, _, Just version -> element pillImpl
    { href: "https://github.com/purefunctor/purescript-iris/releases/tag/" <> version
    , label: version
    , accessibleLabel: "Iris " <> version <> " release" <> newTabLabel
    , tooltip: fromMaybe version (toMaybe server.revision)
    , className: (StyleX.props [ styles.status, styles.statusLink ]).className
    , iconClassName: styleProps.externalIcon.className
    , tooltipClassName: (StyleX.props [ iconButtonStyles.tooltip, styles.commit ]).className
    }
  _, _, Nothing -> pill "Iris language server" styles.statusReady
  where
  server = state.server
  pill label tone = DOM.span
    { className: (StyleX.props [ styles.status, tone ]).className
    , role: "status"
    , title: fromMaybe label (toMaybe server.message)
    }
    label

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
