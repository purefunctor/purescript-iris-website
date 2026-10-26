module Website.Playground.Templates (templateList) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)
import React.Basic.Events (handler_)
import Website.Playground.Types (Actions, Template)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { root:
      { backgroundColor: "var(--granite-950)"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , flexBasis: 0
      , flexGrow: 1
      , minHeight: 0
      , overflowY: "auto"
      }
  , header: { alignItems: "center", display: "flex", height: 36, paddingInlineStart: 14 }
  , title: { color: "var(--text-tertiary)", fontSize: 12, fontWeight: 600, margin: 0 }
  , list:
      { listStyle: "none", margin: 0, paddingBlockEnd: 8, paddingBlockStart: 0, paddingInline: 0 }
  , row:
      { backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderStyle: "none"
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "flex"
      , flexDirection: "column"
      , fontFamily: "var(--font-sans)"
      , gap: 2
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingBlock: 6
      , paddingInline: 14
      , textAlign: "start"
      , transitionDuration: "120ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      , width: "100%"
      }
  , name: { fontSize: 13, fontWeight: 500 }
  , description: { color: "var(--text-tertiary)", fontSize: 12 }
  }

styleProps = StyleX.recordProps styles

templateList :: { templates :: Array Template, actions :: Actions } -> JSX
templateList { templates, actions } =
  DOM.nav { className: styleProps.root.className, "aria-labelledby": "playground-templates" }
    [ DOM.div styleProps.header
        [ DOM.h2 { className: styleProps.title.className, id: "playground-templates" } "Templates" ]
    , DOM.ul styleProps.list (map item templates)
    ]
  where
  item template = DOM.li {}
    [ DOM.button
        { className: styleProps.row.className
        , onClick: handler_ (actions.loadTemplate template.id)
        , title: "Replace the project with " <> template.name
        , type: "button"
        }
        [ DOM.span styleProps.name template.name
        , DOM.span styleProps.description template.description
        ]
    ]
