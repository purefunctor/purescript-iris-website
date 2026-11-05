module Website.Landing.Hero (hero) where

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Iris.StyleX as StyleX
import React.Basic (JSX, Ref, element)
import Web.DOM.Element (Element)
import Website.Breakpoints (breakpoints)
import Website.Components.Backdrop as Backdrop
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Installation as Installation
import Website.Components.Logo (logo)
import Website.Landing.Actions (actions)
import Website.Landing.Output (examples, step)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { section:
      { alignContent: "center"
      , alignItems: "center"
      , boxSizing: "border-box"
      , display: "grid"
      , gap: 56
      , gridTemplateColumns: StyleX.conditionalValue "minmax(0, 1fr) minmax(0, 1.2fr)"
          [ StyleX.conditionalCase breakpoints.upTo960 "minmax(0, 1fr)" ]
      , marginInline: "auto"
      , maxWidth: "var(--container-wide)"
      , minHeight: "min(calc(100svh - var(--nav-height) - 160px), 820px)"
      , paddingBlock: "clamp(32px, 5vw, 64px)"
      , paddingInline: "var(--gutter)"
      }
  , copy:
      { alignItems: "flex-start", display: "flex", flexDirection: "column", gap: 32, minWidth: 0 }
  , heading:
      { display: "flex"
      , flexDirection: "column"
      , fontSize: "clamp(96px, 13vw, 168px)"
      , gap: "0.1em"
      , maxWidth: "100%"
      }
  , lockup: { alignItems: "center", display: "flex", gap: "0.04em" }
  , mark: { flexShrink: 0, height: "1em", marginBlock: "-0.1em", width: "1em" }
  , wordmark:
      { color: "var(--text-primary)"
      , fontSize: "inherit"
      , fontWeight: 900
      , letterSpacing: "-0.05em"
      , lineHeight: 0.8
      , marginInlineStart: "-0.045em"
      }
  , subtitle:
      { color: "var(--text-secondary)"
      , fontSize: "clamp(26px, 2.8vw, 36px)"
      , fontWeight: 500
      , letterSpacing: "-0.025em"
      , lineHeight: 1.1
      }
  , lead:
      { color: "var(--text-secondary)"
      , fontSize: 17
      , lineHeight: 1.65
      , maxWidth: "52ch"
      , textWrap: "pretty"
      }
  , install: { maxWidth: "100%" }
  , code: { display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }
  , source:
      { display:
          StyleX.conditionalValue "block" [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
      , minWidth: 0
      }
  , disclosure:
      { display:
          StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo960 "block" ]
      , minWidth: 0
      }
  , summary:
      { color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , outlineColor: "var(--focus-ring)"
      , paddingBlock: 8
      }
  , disclosed: { marginBlockStart: 8, minWidth: 0 }
  }

styleProps = StyleX.recordProps styles

hero :: { install :: Ref (Nullable Element), ripples :: Int } -> JSX
hero { install, ripples } = element Backdrop.component
  { rippleOrigin: install
  , ripples
  , content:
      [ DOM.section { className: styleProps.section.className, "aria-labelledby": "hero-title" }
          [ DOM.div styleProps.copy
              [ DOM.createBuiltinElement "hgroup" styleProps.heading
                  [ DOM.div styleProps.lockup
                      [ DOM.h1 { className: styleProps.wordmark.className, id: "hero-title" } "IRIS"
                      , logo { className: styleProps.mark.className }
                      ]
                  , DOM.p styleProps.subtitle "a superset of PureScript"
                  ]
              , DOM.p styleProps.lead
                  "In our benchmark, Iris built all 648 packages in 4.25 seconds. It compiles PureScript to JavaScript you can read, and ships its language server, build server, formatter and agent skills in one binary, written in Rust."
              , DOM.div
                  { className: styleProps.install.className
                  , id: "install"
                  , ref: DOM.reactRef install
                  }
                  (Installation.installation { fill: false })
              , actions
              ]
          , DOM.div styleProps.code
              [ DOM.div styleProps.source source
              , DOM.details styleProps.disclosure
                  [ DOM.summary styleProps.summary "Show the source, Factorial.purs"
                  , DOM.div styleProps.disclosed source
                  ]
              , step { stacked: true, note: "tail call → while loop" }
              , CodeBlock.codeBlock
                  { code: examples.factorial.output
                  , filename: "Factorial/index.js"
                  , highlight: examples.factorial.outputHighlight
                  , language: CodeBlock.JavaScript
                  , lineNumbers: true
                  , note: Nothing
                  , surface: CodeBlock.Glass
                  }
              ]
          ]
      ]
  }
  where
  source = CodeBlock.codeBlock
    { code: examples.factorial.source
    , filename: "Factorial.purs"
    , highlight: examples.factorial.sourceHighlight
    , language: CodeBlock.PureScript
    , lineNumbers: true
    , note: Nothing
    , surface: CodeBlock.Glass
    }
