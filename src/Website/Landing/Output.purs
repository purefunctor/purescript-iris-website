module Website.Landing.Output (Compiled, examples, output) where

import Prelude

import Data.Array (last)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), split)
import Iris.StyleX as StyleX
import React.Basic (JSX, element, fragment)
import Website.Breakpoints (breakpoints)
import Website.Components.CodeBlock as CodeBlock
import Website.Components.ContentShell as ContentShell
import Website.Components.Icon as Icon
import Website.Components.Tabs as Tabs
import Website.Landing.Section as Section
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

type Compiled =
  { source :: String, output :: String, sourceHighlight :: Array Int, outputHighlight :: Array Int }

foreign import examples ::
  { factorial :: Compiled, shape :: Compiled, styles :: Compiled, greeter :: Compiled }

type Example =
  { id :: String
  , index :: String
  , title :: String
  , module :: String
  , compiled :: Compiled
  , caption :: Array JSX
  }

exampleList :: Array Example
exampleList =
  [ { id: "data"
    , index: "01"
    , title: "Tagged data"
    , module: "Website.Landing.Example.Shape"
    , compiled: examples.shape
    , caption:
        [ DOM.text "A constructor with arguments becomes a plain object with a string "
        , inlineCode "tag"
        , DOM.text " and positional fields. A "
        , inlineCode "case"
        , DOM.text " compares the tag and destructures the fields, and "
        , inlineCode "Number"
        , DOM.text " arithmetic compiles to plain operators."
        ]
    }
  , { id: "tail-calls"
    , index: "02"
    , title: "Tail calls"
    , module: "Website.Landing.Example.Factorial"
    , compiled: examples.factorial
    , caption:
        [ DOM.text "A function that calls itself in tail position becomes a "
        , inlineCode "while"
        , DOM.text
            " loop that reassigns its arguments, so deep recursion runs without growing the stack."
        ]
    }
  , { id: "stylex"
    , index: "03"
    , title: "StyleX"
    , module: "Website.Landing.Example.Styles"
    , compiled: examples.styles
    , caption:
        [ inlineCode "Iris.StyleX"
        , DOM.text " compiles to direct "
        , inlineCode "@stylexjs/stylex"
        , DOM.text
            " calls, which the StyleX bundler plugin turns into atomic CSS. This website styles every page this way."
        ]
    }
  ]

styles = StyleX.create
  { band:
      { backgroundColor: "var(--granite-900)"
      , backgroundImage:
          "linear-gradient(var(--grid-line) 1px, transparent 1px), linear-gradient(90deg, var(--grid-line) 1px, transparent 1px)"
      , backgroundPosition: "center top"
      , backgroundSize: "48px 48px"
      , borderBlockColor: "var(--border-subtle)"
      , borderBlockStyle: "solid"
      , borderBlockWidth: 1
      , boxShadow: "inset 0 1px 0 var(--glass-highlight)"
      }
  , header:
      { display: "grid"
      , gap: 20
      , gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 420px), 1fr))"
      , alignItems: "end"
      , marginBlockEnd: 40
      }
  , body: { display: "flex", flexDirection: "column", gap: 20 }
  , list:
      { borderBlockEndColor: "var(--border-default)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , marginBlockEnd: 20
      , overflowX: "auto"
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
      , flexShrink: 0
      , fontSize: 15
      , fontWeight: 500
      , gap: 10
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , paddingBlock: 14
      , paddingInline: StyleX.conditionalValue 18 [ StyleX.conditionalCase breakpoints.upTo480 12 ]
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color, box-shadow"
      , transitionTimingFunction: "var(--ease-out)"
      , whiteSpace: "nowrap"
      }
  , tabIndex:
      { color: "var(--accent-text)", fontFamily: "var(--font-mono)", fontSize: 12, opacity: 0.9 }
  , panel:
      { backgroundColor: "var(--granite-850)"
      , borderColor: "var(--border-default)"
      , borderStyle: "solid"
      , borderWidth: 1
      , boxShadow: "inset 0 1px 0 var(--glass-highlight), 0 40px 80px -50px oklch(0% 0 0 / 80%)"
      , display: "flex"
      , flexDirection: "column"
      , gap: 20
      , outlineColor: "var(--focus-ring)"
      , padding: StyleX.conditionalValue "clamp(16px, 2.4vw, 28px)"
          [ StyleX.conditionalCase breakpoints.upTo720 "12px" ]
      }
  , panes:
      { display: "grid"
      , gap: 16
      , gridTemplateColumns: StyleX.conditionalValue "repeat(2, minmax(0, 1fr))"
          [ StyleX.conditionalCase breakpoints.upTo960 "minmax(0, 1fr)" ]
      }
  , caption:
      { color: "var(--text-secondary)"
      , fontSize: 15
      , lineHeight: 1.65
      , maxWidth: "80ch"
      , textWrap: "pretty"
      }
  , inlineCode:
      { backgroundColor: "var(--surface-2)"
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: "0.88em"
      , paddingBlock: 1
      , paddingInline: 5
      , whiteSpace: "nowrap"
      }
  , more:
      { alignItems: "center"
      , color: { default: "var(--accent-text)", ":hover": "var(--signal-200)" }
      , display: "inline-flex"
      , fontSize: 15
      , gap: 8
      , marginBlockStart: 24
      , outlineColor: "var(--focus-ring)"
      , textDecoration: "none"
      }
  , moreIcon: { display: "inline-flex", fontSize: 14 }
  }

styleProps = StyleX.recordProps styles

shortName :: String -> String
shortName name = fromMaybe name (last (split (Pattern ".") name))

inlineCode :: String -> JSX
inlineCode = DOM.code styleProps.inlineCode

output :: JSX
output = DOM.section
  { className: (StyleX.props [ Section.sectionStyle, styles.band ]).className
  , id: "output"
  , "aria-labelledby": "output-heading"
  }
  [ DOM.div ContentShell.contentShell
      [ DOM.div styleProps.header
          [ DOM.div {}
              [ Section.eyebrow { index: "02", label: "Output" }
              , Section.heading { id: "output-heading", text: "Readable, performant JavaScript" }
              ]
          , Section.lead
              "Constructors become tagged objects, tail calls become loops, and styles become StyleX calls. Every pane is a module from this website's source beside the JavaScript Iris generated for it, read from the build output."
          ]
      , Tabs.tabs
          { label: "Compiled examples"
          , items: map item exampleList
          , classes:
              { root: ""
              , list: styleProps.list.className
              , tab: styleProps.tab.className
              , panel: styleProps.panel.className
              }
          }
      , DOM.a
          { className: styleProps.more.className
          , href:
              "https://github.com/purefunctor/purescript-iris/blob/main/documentation/javascript-output.md"
          , rel: "noopener noreferrer"
          , target: targetBlank
          }
          [ DOM.text "How Iris represents PureScript in JavaScript"
          , DOM.span styleProps.moreIcon
              (element Icon.arrowRight { "aria-hidden": true, focusable: false })
          ]
      ]
  ]
  where
  item { id, index, title, module: name, compiled, caption } =
    { id
    , tab: fragment [ DOM.span styleProps.tabIndex index, DOM.text title ]
    , panel: DOM.div styleProps.body
        [ DOM.p styleProps.caption caption
        , DOM.div styleProps.panes
            [ CodeBlock.codeBlock
                { code: compiled.source
                , filename: shortName name <> ".purs"
                , highlight: compiled.sourceHighlight
                , language: CodeBlock.PureScript
                , lineNumbers: true
                , note: Nothing
                , surface: CodeBlock.Flat
                }
            , CodeBlock.codeBlock
                { code: compiled.output
                , filename: shortName name <> "/index.js"
                , highlight: compiled.outputHighlight
                , language: CodeBlock.JavaScript
                , lineNumbers: true
                , note: Nothing
                , surface: CodeBlock.Flat
                }
            ]
        ]
    }
