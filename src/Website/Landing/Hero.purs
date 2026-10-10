module Website.Landing.Hero (hero) where

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Iris.StyleX as StyleX
import React.Basic (JSX, Ref, element)
import Web.DOM.Element (Element)
import Website.Components.Backdrop as Backdrop
import Website.Components.CodeBlock as CodeBlock
import Website.Components.ExternalLink as ExternalLink
import Website.Components.Icon as Icon
import Website.Components.Installation as Installation
import Website.Landing.Example as Example
import Yoga.React.DOM as DOM

styles =
  StyleX.create
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
        { alignItems: "flex-start", display: "flex", flexDirection: "column", gap: 28, minWidth: 0 }
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
        , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , paddingBlock: 5
        , paddingInlineStart: 5
        , paddingInlineEnd: 12
        , textDecoration: "none"
        , transitionDuration: "140ms"
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
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
hero { install, ripples } =
  element
    Backdrop.component
    { rippleOrigin: install
    , ripples
    , content:
        [ DOM.section
            { className: styleProps.section.className, "aria-labelledby": "hero-title" }
            [ DOM.div
                styleProps.copy
                [ ExternalLink.externalLink
                    { className: styleProps.release.className
                    , href: "https://github.com/purefunctor/purescript-iris/releases"
                    }
                    [ DOM.span styleProps.badge "alpha"
                    , DOM.span {} "Expect breaking changes"
                    , DOM.span
                        styleProps.releaseIcon
                        (element Icon.arrowRight { "aria-hidden": true, focusable: false })
                    ]
                , DOM.h1
                    { className: styleProps.title.className, id: "hero-title" }
                    "IRIS, a superset of PureScript."
                , DOM.p
                    styleProps.lead
                    "Iris is a superset of the PureScript programming language, written in Rust. Tooling is vertically integrated into a single binary, such as feature-rich language analysis, a queryable build server, and skills for agents."
                , DOM.div
                    { className: styleProps.install.className
                    , id: "install"
                    , ref: DOM.reactRef install
                    }
                    Installation.installation
                ]
            , DOM.div
                styleProps.code
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
