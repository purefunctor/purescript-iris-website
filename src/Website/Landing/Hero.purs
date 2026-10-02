module Website.Landing.Hero (hero) where

import Data.Maybe (Maybe(..))
import Iris.StyleX as StyleX
import Data.Nullable (Nullable)
import React.Basic (JSX, Ref, element)
import Web.DOM.Element (Element)
import Website.Components.Backdrop as Backdrop
import Website.Components.Button as Button
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Icon as Icon
import Website.Landing.Example as Example
import Website.Landing.Installation as Installation
import Yoga.React.DOM as DOM

styles = StyleX.create
  { section:
      { alignItems: "center"
      , display: "grid"
      , gap: 56
      , gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 460px), 1fr))"
      , marginInline: "auto"
      , maxWidth: "var(--container-wide)"
      , minHeight: 560
      , paddingBlock: "clamp(56px, 8vw, 96px) clamp(64px, 9vw, 112px)"
      , paddingInline: "var(--gutter)"
      }
  , copy:
      { alignItems: "flex-start"
      , display: "flex"
      , flexDirection: "column"
      , gap: 28
      , minWidth: 0
      }
  , release:
      { "WebkitBackdropFilter": "blur(12px)"
      , alignItems: "center"
      , backdropFilter: "blur(12px)"
      , backgroundColor: { default: "var(--glass-fill)", ":hover": "var(--glass-fill-strong)" }
      , borderColor: "var(--glass-border)"
      , borderRadius: 999
      , borderStyle: "solid"
      , borderWidth: 1
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 13
      , gap: 10
      , lineHeight: 1.3
      , maxWidth: "100%"
      , paddingBlock: 5
      , paddingInline: "5px 12px"
      , textDecoration: "none"
      , transition: "background-color 140ms var(--ease-out), color 140ms var(--ease-out)"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
  , badge:
      { alignItems: "center"
      , backgroundColor: "var(--accent)"
      , borderRadius: 999
      , color: "var(--text-on-accent)"
      , display: "inline-flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , fontWeight: 500
      , height: 20
      , paddingInline: 7
      }
  , releaseIcon: { display: "inline-flex", fontSize: 11 }
  , title:
      { fontSize: "clamp(44px, 6.4vw, 76px)"
      , fontWeight: 500
      , letterSpacing: "-0.03em"
      , lineHeight: 1
      , maxWidth: "100%"
      , overflowWrap: "break-word"
      , textWrap: "balance"
      }
  , emphasis: { color: "var(--text-emphasis)" }
  , lead:
      { color: "var(--text-secondary)"
      , fontSize: 17
      , lineHeight: 1.65
      , maxWidth: "52ch"
      , textWrap: "pretty"
      }
  , actions:
      { display: "flex"
      , flexDirection: "column"
      , gap: 16
      , maxWidth: "100%"
      }
  , buttons: { display: "flex", flexWrap: "wrap", gap: 10 }
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
              [ DOM.a
                  { className: styleProps.release.className
                  , href: "https://github.com/purefunctor/purescript-iris/releases"
                  }
                  [ DOM.span styleProps.badge "alpha"
                  , DOM.span {} "Expect breaking changes"
                  , DOM.span styleProps.releaseIcon
                      (element Icon.arrowRight { "aria-hidden": true, focusable: false })
                  ]
              , DOM.h1 { className: styleProps.title.className, id: "hero-title" }
                  [ DOM.text "Functional programming, "
                  , DOM.span styleProps.emphasis "everywhere in between."
                  ]
              , DOM.p styleProps.lead
                  "Iris is a superset of PureScript, written in Rust. It compiles Spago projects to JavaScript for the browser and the server, and brings the same incremental analysis to your editor."
              , DOM.div styleProps.actions
                  [ DOM.div styleProps.buttons
                      [ Button.buttonLink
                          { href: "https://github.com/purefunctor/purescript-iris"
                          , icon: Just Icon.arrowRight
                          , label: "View on GitHub"
                          , size: Button.Large
                          , variant: Button.Primary
                          }
                      , Button.buttonLink
                          { href: "#editor"
                          , icon: Just Icon.play
                          , label: "Watch the editor"
                          , size: Button.Large
                          , variant: Button.Glass
                          }
                      ]
                  , DOM.div { id: "install", ref: DOM.reactRef install }
                      Installation.installation
                  ]
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
