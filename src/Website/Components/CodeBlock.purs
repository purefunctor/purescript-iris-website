module Website.Components.CodeBlock
  ( CodeBlock
  , Language(..)
  , Surface(..)
  , codeBlock
  ) where

import Prelude

import Data.Array (elem, mapWithIndex, null)
import Data.Foldable (foldMap)
import Data.Maybe (Maybe)
import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import Website.Breakpoints (breakpoints)
import Website.Components.CopyButton as CopyButton
import Website.Components.Icon as Icon
import Website.Components.InfoButton as InfoButton
import Yoga.React.DOM as DOM

type Token = { kind :: String, text :: String }

foreign import tokenizeImpl :: String -> String -> Array (Array Token)

data Language = PureScript | JavaScript

data Surface = Flat | Glass

type CodeBlock =
  { code :: String
  , filename :: String
  , highlight :: Array Int
  , language :: Language
  , lineNumbers :: Boolean
  , note :: Maybe String
  , surface :: Surface
  }

styles = StyleX.create
  { root:
      { borderRadius: 12
      , borderStyle: "solid"
      , borderWidth: 1
      , minWidth: 0
      , overflow: "hidden"
      , position: "relative"
      }
  , flat:
      { backgroundColor: "var(--syn-bg)"
      , borderColor: "var(--border-subtle)"
      }
  , glass:
      { "WebkitBackdropFilter": "blur(18px) saturate(1.25)"
      , backdropFilter: "blur(18px) saturate(1.25)"
      , backgroundColor: "var(--glass-fill)"
      , borderColor: "var(--glass-border)"
      , boxShadow: "var(--shadow-glass)"
      }
  , head:
      { alignItems: "center"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , gap: 8
      , height: 38
      , paddingInlineStart: 14
      , paddingInlineEnd: 8
      }
  , fileIcon: { color: "var(--text-tertiary)", display: "inline-flex", fontSize: 12 }
  , filename:
      { color: "var(--text-secondary)"
      , flexGrow: 1
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , lineHeight: 1
      , minWidth: 0
      , overflow: "hidden"
      , textOverflow: "ellipsis"
      , whiteSpace: "nowrap"
      }
  , pre:
      { color: "var(--syn-text)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , lineHeight: 1.62
      , margin: 0
      , paddingBlock: 14
      , tabSize: 2
      }
  , code: { display: "block" }
  , line: { display: "flex", paddingInline: 18 }
  , highlighted:
      { backgroundColor: "var(--syn-highlight)"
      , boxShadow: "inset 2px 0 0 var(--ochre-400)"
      }
  , lineNumber:
      { color: "var(--syn-line-number)"
      , flexShrink: 0
      , marginInlineEnd: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo480 12 ]
      , textAlign: "right"
      , userSelect: "none"
      , width: StyleX.conditionalValue 28 [ StyleX.conditionalCase breakpoints.upTo480 18 ]
      }
  , content: { minWidth: 0, overflowWrap: "anywhere", whiteSpace: "pre-wrap" }
  , keyword: { color: "var(--syn-keyword)" }
  , type: { color: "var(--syn-type)" }
  , string: { color: "var(--syn-string)" }
  , number: { color: "var(--syn-number)" }
  , comment: { color: "var(--syn-comment)", fontStyle: "italic" }
  , function: { color: "var(--syn-function)" }
  , operator: { color: "var(--syn-operator)" }
  , punct: { color: "var(--syn-punct)" }
  , text: { color: "var(--syn-text)" }
  }

styleProps = StyleX.recordProps styles

surfaceStyle :: Surface -> StyleX.Style
surfaceStyle = case _ of
  Flat -> styles.flat
  Glass -> styles.glass

tokenStyle :: String -> StyleX.Style
tokenStyle = case _ of
  "keyword" -> styles.keyword
  "type" -> styles.type
  "string" -> styles.string
  "number" -> styles.number
  "comment" -> styles.comment
  "function" -> styles.function
  "operator" -> styles.operator
  "punct" -> styles.punct
  _ -> styles.text

languageName :: Language -> String
languageName = case _ of
  PureScript -> "purescript"
  JavaScript -> "javascript"

codeBlock :: CodeBlock -> JSX
codeBlock { code, filename, highlight, language, lineNumbers, note, surface } =
  DOM.figure (StyleX.props [ styles.root, surfaceStyle surface ])
    [ DOM.figcaption styleProps.head
        [ DOM.span styleProps.fileIcon
            (element Icon.fileCode { "aria-hidden": true, focusable: false })
        , DOM.span styleProps.filename filename
        , foldMap InfoButton.infoButton note
        , CopyButton.copyButton
            { label: "Copy " <> filename, size: CopyButton.Small, text: code }
        ]
    , DOM.pre styleProps.pre
        ( DOM.code styleProps.code
            (mapWithIndex renderLine (tokenizeImpl (languageName language) code))
        )
    ]
  where
  renderLine index tokens =
    DOM.span
      ( StyleX.props
          [ styles.line, StyleX.conditional (elem (index + 1) highlight) styles.highlighted ]
      )
      ( ( if lineNumbers then
            [ DOM.span { className: styleProps.lineNumber.className, "aria-hidden": true }
                (show (index + 1))
            ]
          else []
        ) <>
          [ DOM.span styleProps.content
              if null tokens then [ DOM.text " " ] else map renderToken tokens
          ]
      )

  renderToken { kind, text } = DOM.span (StyleX.props (tokenStyle kind)) text
