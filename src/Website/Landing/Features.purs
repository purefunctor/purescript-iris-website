module Website.Landing.Features (featuresSection) where

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Website.Components.ContentShell as ContentShell
import Website.Landing.Features.Code as Code
import Yoga.React.DOM as DOM

styles = StyleX.create
  { section:
      { backgroundColor: "var(--landing-color-paper)"
      , color: "var(--landing-color-ink)"
      , overflow: "hidden"
      , paddingBlock: "clamp(88px, 10vw, 152px) clamp(80px, 9vw, 128px)"
      }
  , stage:
      { alignItems: "center"
      , display: "grid"
      , gap: "clamp(48px, 5vw, 80px)"
      , gridTemplateColumns: "minmax(0, 0.85fr) minmax(0, 1.15fr)"
      , isolation: "isolate"
      , marginBlockEnd: "clamp(72px, 9vw, 120px)"
      , position: "relative"
      , "@media (max-width: 1279px)": { gridTemplateColumns: "minmax(0, 1fr)" }
      }
  , introduction:
      { gridColumn: 1
      , gridRow: 1
      }
  , heading:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "var(--landing-type-chapter)"
      , fontWeight: 520
      , letterSpacing: "-0.035em"
      , lineHeight: 1.05
      , marginBlockEnd: "clamp(32px, 4vw, 56px)"
      , textWrap: "balance"
      }
  , lead:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "var(--landing-type-lead)"
      , fontWeight: 530
      , letterSpacing: "-0.02em"
      , lineHeight: 1.25
      , maxWidth: 580
      , textWrap: "balance"
      }
  , explanation:
      { color: "var(--landing-color-muted)"
      , fontSize: "var(--landing-type-body)"
      , lineHeight: 1.65
      , marginBlockStart: 24
      , maxWidth: 520
      }
  , diagram:
      { alignItems: "center"
      , display: "grid"
      , gap: 72
      , gridColumn: 2
      , gridRow: 1
      , gridTemplateColumns: "minmax(0, 1fr) minmax(0, 1.3fr)"
      , justifySelf: "center"
      , maxWidth: 645
      , minHeight: 400
      , paddingBlock: 48
      , position: "relative"
      , width: "100%"
      , "@media (max-width: 1279px)":
          { gap: 52
          , gridColumn: 1
          , gridRow: 2
          , gridTemplateColumns: "minmax(0, 1fr)"
          , minHeight: 0
          , paddingBlock: 32
          }
      , "@media (max-width: 600px)":
          { paddingBlock: 28 }
      }
  , diagramBackdrop:
      { alignSelf: "stretch"
      , backgroundImage: "var(--landing-compiler-image)"
      , backgroundPosition: "center"
      , backgroundSize: "cover"
      , gridColumn: "1 / -1"
      , gridRow: 1
      , marginInline: "calc(50% - 50vw)"
      , pointerEvents: "none"
      , position: "relative"
      , width: "100vw"
      , zIndex: "-1"
      , "@media (max-width: 1279px)": { gridRow: 2 }
      }
  , node:
      { backgroundColor: "oklch(from var(--landing-color-paper) l c h / 87%)"
      , boxShadow: "0 0 0 1px oklch(from var(--landing-color-violet) l c h / 14%)"
      , display: "grid"
      , minHeight: 124
      , minWidth: 0
      , padding: "30px 16px 18px"
      , position: "relative"
      , width: "100%"
      , "@media (max-width: 600px)": { minHeight: 0 }
      }
  , sourceNode:
      { justifySelf:
          { default: "stretch"
          , "@media (max-width: 1279px)": "start"
          }
      , maxWidth:
          { default: "none"
          , "@media (max-width: 1279px)": 340
          , "@media (max-width: 800px)": "calc(100% / 3)"
          , "@media (max-width: 700px)": 280
          }
      }
  , outputs:
      { display: "grid"
      , gap: 28
      , minWidth: 0
      , width: "100%"
      , "@media (max-width: 1279px)": { gap: 52 }
      }
  , outputNode:
      { minHeight: 120
      }
  , semanticNode:
      { justifySelf: "end"
      , maxWidth: 280
      , minHeight: 88
      }
  , nodeLabel:
      { backgroundColor: "var(--landing-color-ink)"
      , color: "var(--landing-color-paper)"
      , fontFamily: "var(--landing-font-body)"
      , fontSize: "var(--landing-type-meta)"
      , fontWeight: 650
      , insetBlockStart: "-14px"
      , insetInlineStart: 0
      , lineHeight: 1.4
      , padding: "5px 9px"
      , position: "absolute"
      }
  , nodeValue:
      { fontFamily: "var(--landing-font-code)"
      , fontSize: 13
      , fontVariantLigatures: "none"
      , lineHeight: 1.5
      , minWidth: 0
      , overflowX: "auto"
      , whiteSpace: "pre"
      , ":focus-visible": { outline: "2px solid var(--landing-color-violet)", outlineOffset: 2 }
      }
  , scrollHint:
      { backgroundColor: "var(--landing-color-paper)"
      , color: "var(--landing-color-violet)"
      , fontFamily: "var(--landing-font-code)"
      , fontSize: 11
      , insetBlockEnd: 8
      , insetInlineEnd: 12
      , pointerEvents: "none"
      , position: "absolute"
      , "@media (min-width: 495px) and (max-width: 1279px)": { display: "none" }
      }
  , points:
      { display: "grid"
      , gap: "clamp(32px, 4vw, 64px)"
      , gridTemplateColumns: "repeat(3, minmax(0, 1fr))"
      , "@media (max-width: 800px)": { gridTemplateColumns: "minmax(0, 1fr)" }
      }
  , point:
      { borderTopColor: "var(--landing-color-line)"
      , borderTopStyle: "solid"
      , borderTopWidth: 1
      , paddingBlockStart: 24
      }
  , pointTitle:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "var(--landing-type-title)"
      , fontWeight: 600
      , lineHeight: 1.2
      , marginBlockEnd: 12
      }
  , pointCopy:
      { color: "var(--landing-color-muted)"
      , fontSize: "var(--landing-type-body)"
      , lineHeight: 1.65
      , maxWidth: 460
      }
  }

styleProps = StyleX.recordProps styles

featuresSection :: JSX
featuresSection =
  DOM.section
    { className: styleProps.section.className
    , id: "about"
    , "aria-labelledby": "about-heading"
    }
    [ DOM.div ContentShell.contentShell
        [ DOM.div styleProps.stage
            [ DOM.div styleProps.introduction
                [ DOM.h2 { className: styleProps.heading.className, id: "about-heading" }
                    "What is Iris?"
                , DOM.p styleProps.lead
                    "Iris is a superset of PureScript, written in Rust."
                , DOM.p styleProps.explanation
                    "Iris compiles PureScript projects managed by Spago and provides code intelligence via its language server implementation. It is designed with incremental compilation from the ground up, making it fast and responsive once the build server is primed."
                ]
            , DOM.div { className: styleProps.diagramBackdrop.className, "aria-hidden": true }
                []
            , DOM.div
                { className: styleProps.diagram.className
                , "aria-label":
                    "PureScript source is checked by Iris and becomes JavaScript; the same analysis serves the editor"
                }
                [ DOM.div (StyleX.props [ styles.node, styles.sourceNode ])
                    [ DOM.span styleProps.nodeLabel "PureScript"
                    , DOM.pre styleProps.nodeValue
                        ( DOM.code {}
                            [ DOM.span Code.sourceLine
                                [ DOM.span Code.sourceDeclaration "greet"
                                , DOM.span Code.sourceVariable " name"
                                , DOM.span Code.sourceAccent " ="
                                , DOM.span Code.sourceKeyword " do"
                                ]
                            , DOM.span Code.sourceLine
                                [ DOM.span Code.sourceReference "  log"
                                , DOM.span Code.sourceVariable " name"
                                ]
                            , DOM.span Code.sourceLine
                                [ DOM.span Code.sourceReference "  log"
                                , DOM.span Code.sourceString " \"Iris is ready.\""
                                ]
                            , DOM.span Code.sourceLine " "
                            , DOM.span Code.sourceLine
                                [ DOM.span Code.sourceDeclaration "main"
                                , DOM.span Code.sourceAccent " ="
                                ]
                            , DOM.span Code.sourceLine
                                [ DOM.span Code.sourceReference "  greet"
                                , DOM.span Code.sourceString " \"Hello, world!\""
                                ]
                            ]
                        )
                    ]
                , DOM.div styleProps.outputs
                    [ DOM.div (StyleX.props [ styles.node, styles.outputNode ])
                        [ DOM.span styleProps.nodeLabel "JavaScript"
                        , DOM.pre
                            { className: styleProps.nodeValue.className
                            , tabIndex: 0
                            , "aria-label": "Generated JavaScript"
                            }
                            ( DOM.code {}
                                [ DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "export function"
                                    , DOM.span Code.sourceDeclaration " greet"
                                    , DOM.span {} "("
                                    , DOM.span Code.sourceVariable "name"
                                    , DOM.span {} ") {"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "  const"
                                    , DOM.span Code.sourceVariable " $action"
                                    , DOM.span Code.sourceAccent " ="
                                    , DOM.span Code.sourceReference " Effect_Console.log("
                                    , DOM.span Code.sourceVariable "name"
                                    , DOM.span {} ");"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "  return"
                                    , DOM.span {} " () => {"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "    const"
                                    , DOM.span Code.sourceVariable " $unit"
                                    , DOM.span Code.sourceAccent " ="
                                    , DOM.span Code.sourceVariable " $action"
                                    , DOM.span {} "();"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "    return"
                                    , DOM.span Code.sourceReference " Effect_Console.log("
                                    , DOM.span Code.sourceString "\"Iris is ready.\""
                                    , DOM.span {} ")();"
                                    ]
                                , DOM.span Code.sourceLine "  };"
                                , DOM.span Code.sourceLine "}"
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "export const"
                                    , DOM.span Code.sourceDeclaration " main"
                                    , DOM.span Code.sourceAccent " ="
                                    , DOM.span Code.sourceReference " greet("
                                    , DOM.span Code.sourceString "\"Hello, world!\""
                                    , DOM.span {} ");"
                                    ]
                                ]
                            )
                        , DOM.span
                            { className: styleProps.scrollHint.className, "aria-hidden": true }
                            "SCROLL ↔"
                        ]
                    , DOM.div (StyleX.props [ styles.node, styles.outputNode, styles.semanticNode ])
                        [ DOM.span styleProps.nodeLabel "Semantic"
                        , DOM.pre styleProps.nodeValue
                            ( DOM.code {}
                                [ DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceDeclaration "greet"
                                    , DOM.span Code.sourceSyntax " :: "
                                    , DOM.span Code.sourceType "String"
                                    , DOM.span Code.sourceSyntax " -> "
                                    , DOM.span Code.sourceType "Effect Unit"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceDeclaration "main"
                                    , DOM.span Code.sourceSyntax " :: "
                                    , DOM.span Code.sourceType "Effect Unit"
                                    ]
                                ]
                            )
                        ]
                    ]
                ]
            ]
        , DOM.div styleProps.points
            [ point "Write the idea. See the types."
                "Leave signatures off small functions without giving up type checking. Iris infers the types of values and effects as it checks your program—annotations are there when you want them, not required on every binding."
            , point "Answers beside your code"
                "Complete names, inspect inferred types, jump to definitions and rename within scope. Diagnostics run on open and save; on-change checks are there when you opt in."
            , point "Your project comes along"
                "Start with a Spago workspace and the JavaScript foreign modules you already use. Iris tests compatibility against curated Registry packages, so support is earned rather than simply assumed."
            ]
        ]
    ]

point :: String -> String -> JSX
point title copy =
  DOM.div styleProps.point
    [ DOM.h3 styleProps.pointTitle title
    , DOM.p styleProps.pointCopy copy
    ]
