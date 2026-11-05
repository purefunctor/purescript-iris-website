module Website.Playground.Embed (component) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (notNull, null, toMaybe)
import Data.String (Pattern(..), stripPrefix, stripSuffix)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element, fragment)
import React.Basic.Events (handler_)
import React.Basic.Hooks (Hook, unsafeHook)
import React.Basic.Hooks as Hooks
import Website.Breakpoints (breakpoints)
import Website.Components.ExternalLink (newTabLabel)
import Website.Components.Icon as Icon
import Website.Components.Logo (logo)
import Website.Jotai as Jotai
import Website.Playground.Button.Styles (buttonStyles)
import Website.Playground.Hooks (usePlayground)
import Website.Playground.Index (output, runButton)
import Website.Playground.Loading (loading)
import Website.Playground.Scroll (scroll)
import Website.Playground.Types (File, State, Template, View, Actions)
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

foreign import pureScriptIcon :: ReactComponent { "aria-hidden" :: Boolean, className :: String }

foreign import javaScriptIcon :: ReactComponent { "aria-hidden" :: Boolean, className :: String }

foreign import afterPick :: Effect Unit -> Effect Unit

foreign import data UseCloseOnEscape :: Type -> Type

foreign import useCloseOnEscapeImpl :: { open :: Boolean, close :: Effect Unit } -> Effect Unit

useCloseOnEscape :: { open :: Boolean, close :: Effect Unit } -> Hook UseCloseOnEscape Unit
useCloseOnEscape options = unsafeHook (useCloseOnEscapeImpl options)

slideIn = StyleX.keyframes { from: { transform: "translateX(-100%)" }, to: { transform: "none" } }

fadeIn = StyleX.keyframes { from: { opacity: 0 }, to: { opacity: 1 } }

styles = StyleX.create
  { page:
      { backgroundColor: "var(--bg-canvas)"
      , color: "var(--text-primary)"
      , display: "flex"
      , flexDirection: "column"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , inset: 0
      , overflow: "hidden"
      , position: "fixed"
      }
  , header:
      { alignItems: "center"
      , backgroundColor: "var(--granite-950)"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , gap: StyleX.conditionalValue 8 [ StyleX.conditionalCase breakpoints.upTo400 4 ]
      , height: 48
      , paddingInline: StyleX.conditionalValue 10 [ StyleX.conditionalCase breakpoints.upTo400 6 ]
      }
  , brand:
      { alignItems: "center"
      , color: "var(--text-primary)"
      , display: "inline-flex"
      , flexShrink: 0
      , gap: 6
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , minHeight: 32
      , paddingInline: 4
      , textDecoration: "none"
      }
  , brandMark: { flexShrink: 0, height: 18, width: 18 }
  , brandWordmark: { fontSize: 17, fontWeight: 900, letterSpacing: "-0.05em", lineHeight: 1 }
  , brandLabel:
      { borderInlineStartColor: "var(--border-default)"
      , borderInlineStartStyle: "solid"
      , borderInlineStartWidth: 1
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , display:
          StyleX.conditionalValue "inline" [ StyleX.conditionalCase breakpoints.upTo400 "none" ]
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , letterSpacing: "0.06em"
      , marginInlineStart: 4
      , paddingInlineStart: 10
      , textTransform: "uppercase"
      }
  , iconOnly: { flexShrink: 0, justifyContent: "center", paddingInline: 0, width: 32 }
  , iconPressed: { backgroundColor: "var(--surface-3)", color: "var(--accent-text)" }
  , icon: { display: "inline-flex", fontSize: 14 }
  , spacer: { flexGrow: 1 }
  , body: { display: "flex", flexGrow: 1, minHeight: 0, position: "relative" }
  , sidebar:
      { backgroundColor: "var(--granite-950)"
      , borderInlineEndColor: "var(--border-subtle)"
      , borderInlineEndStyle: "solid"
      , borderInlineEndWidth: 1
      , boxShadow: "12px 0 32px oklch(0% 0 0 / 55%)"
      , display: "flex"
      , flexDirection: "column"
      , flexShrink: 0
      , insetBlock: 0
      , insetInlineStart: 0
      , position: "absolute"
      , width: "min(200px, 82%)"
      , zIndex: 3
      , animationDuration: "200ms"
      , animationName: { default: slideIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      }
  , scrim:
      { animationDuration: "200ms"
      , animationName: { default: fadeIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , backgroundColor: "oklch(0% 0 0 / 45%)"
      , inset: 0
      , position: "absolute"
      , zIndex: 2
      }
  , section: { display: "flex", flexDirection: "column", minHeight: 0 }
  , files: { flexShrink: 0, maxHeight: "50%" }
  , examples:
      { borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , flexGrow: 1
      , flexShrink: 1
      }
  , sectionHeader:
      { alignItems: "center", display: "flex", flexShrink: 0, height: 32, paddingInline: 12 }
  , title:
      { color: "var(--text-secondary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , fontWeight: 500
      , letterSpacing: "0.06em"
      , margin: 0
      , textTransform: "uppercase"
      }
  , scroll: { flexGrow: 1, minHeight: 0 }
  , list:
      { listStyle: "none", margin: 0, paddingBlockEnd: 8, paddingBlockStart: 0, paddingInline: 0 }
  , row:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderStyle: "none"
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "flex"
      , gap: 8
      , height: 28
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingInline: 12
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
  , fileName: { fontFamily: "var(--font-mono)", fontSize: 12 }
  , fileIcon: { flexShrink: 0, height: 15, width: 15 }
  , number:
      { color: "var(--accent-text)"
      , flexShrink: 0
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , width: 16
      }
  , exampleName: { fontSize: 13, fontWeight: 500 }
  , ellipsis: { minWidth: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }
  , main: { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0, minWidth: 0 }
  , growOutput: { flexGrow: 3 }
  , editor:
      { backgroundColor: "var(--granite-900)"
      , flexBasis: 0
      , flexGrow: 3
      , minHeight: 0
      , position: "relative"
      }
  , editorHost: { insetBlock: 0, insetInlineEnd: 0, insetInlineStart: 6, position: "absolute" }
  , output:
      { backgroundColor: "var(--granite-950)"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , display: "flex"
      , flexBasis: 0
      , flexDirection: "column"
      , flexGrow: 2
      , minHeight: 0
      , overflowY: "auto"
      }
  , frames: { height: 0, overflow: "hidden", position: "absolute", width: 0 }
  }

styleProps = StyleX.recordProps styles

sidebarId :: String
sidebarId = "embed-sidebar"

component :: ReactComponent { theme :: Foreign }
component = unsafePerformEffect $ Hooks.reactComponent "PlaygroundEmbed" \{ theme } ->
  pure $ element Jotai.provider { children: element embed { theme } }

embed :: ReactComponent { theme :: Foreign }
embed = unsafePerformEffect $ Hooks.reactComponent "PlaygroundEmbedWorkspace" \{ theme } -> Hooks.do
  view <- usePlayground { theme, embedded: true }
  useCloseOnEscape { open: view.state.sidebar, close: view.actions.closeSidebar }
  pure (playground view)

playground :: View -> JSX
playground { state, actions, editor, generated, frames } = DOM.div styleProps.page
  [ DOM.header styleProps.header
      [ DOM.a
          { className: styleProps.brand.className
          , href: "/playground/"
          , onClick: actions.openFullPlayground
          , onAuxClick: actions.openFullPlayground
          , rel: "noopener"
          , target: targetBlank
          , "aria-label": "Open in the Iris playground" <> newTabLabel
          }
          [ logo styleProps.brandMark
          , DOM.span styleProps.brandWordmark "IRIS"
          , DOM.span styleProps.brandLabel "Playground"
          ]
      , if ready then sidebarToggle else mempty
      , DOM.div styleProps.spacer []
      , if ready
        then element runButton
          { status: state.run.status
          , ready: state.server.status == "ready"
          , run: actions.run
          , stop: actions.stop
          }
        else mempty
      ]
  , DOM.div styleProps.body
      [ if ready && state.sidebar then sidebar state actions else mempty
      , DOM.createBuiltinElement "main" { className: styleProps.main.className, inert: covered }
          [ DOM.div styleProps.editor
              [ DOM.div { className: styleProps.editorHost.className, ref: DOM.reactRef editor } []
              ]
          , DOM.section
              { className:
                  ( StyleX.props
                      [ styles.output, StyleX.conditional state.run.view styles.growOutput ]
                  ).className
              , "aria-label": "Output"
              }
              [ if ready then output state actions frames else mempty ]
          ]
      , if ready then mempty else loading state actions.retry
      ]
  , DOM.createBuiltinElement "div"
      { className: styleProps.frames.className, ref: DOM.reactRef frames, inert: covered } []
  , DOM.div { className: styleProps.frames.className, ref: DOM.reactRef generated } []
  ]
  where
  ready = state.phase == "ready"
  covered = if state.sidebar then notNull "" else null

  sidebarToggle = DOM.createBuiltinElement "button"
    { className:
        ( StyleX.props
            [ buttonStyles.action
            , styles.iconOnly
            , StyleX.conditional state.sidebar styles.iconPressed
            ]
        ).className
    , id: "embed-sidebar-toggle"
    , onClick: handler_ actions.toggleSidebar
    , title: if state.sidebar then "Hide files and examples" else "Show files and examples"
    , type: "button"
    , "aria-controls": if state.sidebar then notNull sidebarId else null
    , "aria-expanded": state.sidebar
    , "aria-label": "Files and examples"
    }
    (DOM.span styleProps.icon (element Icon.panelLeft { "aria-hidden": true, focusable: false }))

sidebar :: State -> Actions -> JSX
sidebar state actions = fragment
  [ DOM.div
      { className: styleProps.scrim.className
      , onClick: handler_ (afterPick actions.closeSidebar)
      , "aria-hidden": true
      }
      []
  , DOM.createBuiltinElement "nav"
      { className: styleProps.sidebar.className, id: sidebarId, "aria-label": "Files and examples" }
      [ DOM.div (StyleX.props [ styles.section, styles.files ])
          [ sectionHeader "embed-files" "Files"
          , scroll styleProps.scroll.className
              [ DOM.ul { className: styleProps.list.className, "aria-labelledby": "embed-files" }
                  (map fileRow state.files)
              ]
          ]
      , DOM.div (StyleX.props [ styles.section, styles.examples ])
          [ sectionHeader "embed-examples" "Examples"
          , scroll styleProps.scroll.className
              [ DOM.ul { className: styleProps.list.className, "aria-labelledby": "embed-examples" }
                  (mapWithIndex exampleRow state.templates)
              ]
          ]
      ]
  ]
  where
  active = toMaybe state.active
  template = toMaybe state.template

  sectionHeader :: String -> String -> JSX
  sectionHeader id text =
    DOM.div styleProps.sectionHeader [ DOM.h2 { className: styleProps.title.className, id } text ]

  fileRow :: File -> JSX
  fileRow file = DOM.li {}
    [ DOM.button
        { className: rowClassName current
        , onClick: handler_ (afterPick (actions.openFile file.path))
        , title: file.path
        , type: "button"
        , "aria-current": if current then "true" else "false"
        }
        [ element (if isPureScript then pureScriptIcon else javaScriptIcon)
            { "aria-hidden": true, className: styleProps.fileIcon.className }
        , DOM.span (StyleX.props [ styles.fileName, styles.ellipsis ]) (displayPath file.path)
        ]
    ]
    where
    current = active == Just file.path
    isPureScript = stripSuffix (Pattern ".purs") file.path /= Nothing

  exampleRow :: Int -> Template -> JSX
  exampleRow index example = DOM.li {}
    [ DOM.button
        { className: rowClassName current
        , onClick: handler_ (afterPick (actions.loadTemplate example.id))
        , title: example.description
        , type: "button"
        , "aria-current": if current then "true" else "false"
        }
        [ DOM.span { className: styleProps.number.className, "aria-hidden": true }
            (if index < 9 then "0" <> show (index + 1) else show (index + 1))
        , DOM.span (StyleX.props [ styles.exampleName, styles.ellipsis ]) example.name
        ]
    ]
    where
    current = template == Just example.id

  rowClassName current =
    (StyleX.props [ styles.row, StyleX.conditional current styles.activeRow ]).className

displayPath :: String -> String
displayPath path = fromMaybe path (stripPrefix (Pattern "src/") path)
