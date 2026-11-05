module Website.Playground.Templates (templateList) where

import Prelude

import Data.Array (mapWithIndex)
import Iris.StyleX as StyleX
import React.Basic (JSX)
import React.Basic.Events (handler_)
import Website.Playground.Scroll (scroll)
import Website.Playground.Types (Actions, Template)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { root:
      { backgroundColor: "var(--granite-950)"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , display: "flex"
      , flexBasis: "auto"
      , flexDirection: "column"
      , flexGrow: 0
      , flexShrink: 1
      , maxHeight: "65%"
      , minHeight: 0
      }
  , scroll: { flexGrow: 1, minHeight: 0 }
  , header: { alignItems: "center", display: "flex", height: 36, paddingInlineStart: 14 }
  , title:
      { color: "var(--text-secondary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , fontWeight: 500
      , letterSpacing: "0.06em"
      , margin: 0
      , textTransform: "uppercase"
      }
  , list:
      { listStyle: "none", margin: 0, paddingBlockEnd: 8, paddingBlockStart: 0, paddingInline: 0 }
  , row:
      { backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderStyle: "none"
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , columnGap: 12
      , display: "grid"
      , fontFamily: "var(--font-sans)"
      , gridTemplateColumns: "auto minmax(0, 1fr)"
      , rowGap: 2
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
  , index:
      { color: "var(--accent-text)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , gridRow: "1 / span 2"
      , lineHeight: "18px"
      }
  , name: { fontSize: 13, fontWeight: 500, gridColumn: 2 }
  , description: { color: "var(--text-tertiary)", fontSize: 12, gridColumn: 2 }
  }

styleProps = StyleX.recordProps styles

templateList :: { templates :: Array Template, actions :: Actions } -> JSX
templateList { templates, actions } =
  DOM.nav { className: styleProps.root.className, "aria-labelledby": "playground-templates" }
    [ DOM.div styleProps.header
        [ DOM.h2 { className: styleProps.title.className, id: "playground-templates" } "Templates" ]
    , scroll styleProps.scroll.className [ DOM.ul styleProps.list (mapWithIndex item templates) ]
    ]
  where
  item number template = DOM.li {}
    [ DOM.button
        { className: styleProps.row.className
        , onClick: handler_ (actions.loadTemplate template.id)
        , title: "Replace the project with " <> template.name
        , type: "button"
        }
        [ DOM.span { className: styleProps.index.className, "aria-hidden": true }
            (if number < 9 then "0" <> show (number + 1) else show (number + 1))
        , DOM.span styleProps.name template.name
        , DOM.span styleProps.description template.description
        ]
    ]
