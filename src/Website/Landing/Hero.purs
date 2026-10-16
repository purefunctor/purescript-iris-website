module Website.Landing.Hero (hero) where

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Iris.StyleX as StyleX
import React.Basic (JSX, Ref, element)
import Web.DOM.Element (Element)
import Website.Components.Backdrop as Backdrop
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Installation as Installation
import Website.Components.Logo (logo)
import Website.Landing.Example as Example
import Yoga.React.DOM as DOM

styles = StyleX.create
  -- The hero fills the first screen below the navigation and grows when its content is taller.
  { section:
      { alignContent: "center"
      , alignItems: "center"
      , boxSizing: "border-box"
      , display: "grid"
      , gap: 56
      , gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 460px), 1fr))"
      , marginInline: "auto"
      , maxWidth: "var(--container-wide)"
      , minHeight: "calc(100svh - var(--nav-height))"
      , paddingBlock: "clamp(32px, 5vw, 64px)"
      , paddingInline: "var(--gutter)"
      }
  , copy:
      { alignItems: "flex-start", display: "flex", flexDirection: "column", gap: 32, minWidth: 0 }
  -- The heading's font size is the wordmark's. Its gaps, and the lockup's, leave the same visible
  -- space beside and below the wordmark, tighter than the gaps between the copy's blocks.
  , heading:
      { display: "flex"
      , flexDirection: "column"
      , fontSize: "clamp(96px, 13vw, 168px)"
      , gap: "0.1em"
      , maxWidth: "100%"
      }
  , lockup: { alignItems: "center", display: "flex", gap: "0.04em" }
  -- The dots span 72% of the mark's box, so a 1em mark matches Geist's cap height. Its margins
  -- keep the box within the wordmark's line height.
  , mark: { flexShrink: 0, height: "1em", marginBlock: "-0.1em", width: "1em" }
  , wordmark:
      { color: "var(--text-primary)"
      , fontSize: "inherit"
      , fontWeight: 900
      , letterSpacing: "-0.05em"
      , lineHeight: 0.8
      -- Pulls the I's side bearing back to the column edge.
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
  , code: { minWidth: 0 }
  }

styleProps = StyleX.recordProps styles

-- | `install` marks the installation commands, where the header's Install action starts a ripple.
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
                  "Iris is a superset of the PureScript programming language, written in Rust. Tooling is vertically integrated into a single binary, such as feature-rich language analysis, a queryable build server, and skills for agents."
              , DOM.div
                  { className: styleProps.install.className
                  , id: "install"
                  , ref: DOM.reactRef install
                  }
                  (Installation.installation { fill: false })
              ]
          , DOM.div styleProps.code
              ( CodeBlock.codeBlock
                  { code: Example.source
                  , filename: "src/Main.purs"
                  , highlight: []
                  , language: CodeBlock.PureScript
                  , lineNumbers: true
                  , note: Nothing
                  , surface: CodeBlock.Glass
                  }
              )
          ]
      ]
  }
