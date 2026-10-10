module Website.Documentation.Prose (inlineCode, item, link, list, note, paragraph) where

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Yoga.React.DOM as DOM

styles =
  StyleX.create
    { paragraph: { maxWidth: "72ch" }
    , inlineCode:
        { fontFamily: "var(--font-mono)"
        , fontSize: "0.86em"
        , color: "var(--text-primary)"
        , backgroundColor: "var(--surface-1)"
        , paddingInline: 5
        , paddingBlock: 2
        }
    , list: { paddingInlineStart: 22, display: "flex", flexDirection: "column", gap: 10 }
    , link:
        { color: { default: "var(--accent-text)", ":hover": "var(--iris-200)" }
        , textUnderlineOffset: 4
        , outlineColor: "var(--focus-ring)"
        }
    , note:
        { backgroundColor: "var(--surface-1)"
        , display: "flex"
        , flexDirection: "column"
        , gap: 12
        , padding: 20
        , fontSize: 14
        , lineHeight: 1.7
        , color: "var(--text-secondary)"
        }
    }

styleProps = StyleX.recordProps styles

paragraph :: Array JSX -> JSX
paragraph = DOM.p styleProps.paragraph

inlineCode :: String -> JSX
inlineCode = DOM.code styleProps.inlineCode

link :: String -> String -> JSX
link href label = DOM.a { className: styleProps.link.className, href } label

list :: Array JSX -> JSX
list = DOM.ul styleProps.list

item :: Array JSX -> JSX
item = DOM.li {}

note :: Array JSX -> JSX
note = DOM.aside styleProps.note
