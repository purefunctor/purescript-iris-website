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
      }
  , stage:
      { display: "grid"
      , gap: "clamp(56px, 7vw, 96px)"
      , isolation: "isolate"
      , position: "relative"
      , "@media (max-width: 1279px)": { gap: "clamp(48px, 5vw, 80px)" }
      }
  , introduction:
      { gridColumn: 1
      , gridRow: 1
      , paddingBlockStart: "clamp(88px, 10vw, 152px)"
      }
  , introductionCopy:
      { backgroundColor: "oklch(from var(--landing-color-paper) l c h / 60%)"
      , padding: "clamp(20px, 2vw, 28px)"
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
      , textWrap: "balance"
      }
  , explanation:
      { color: "var(--landing-color-muted)"
      , fontSize: "var(--landing-type-body)"
      , lineHeight: 1.65
      , marginBlockStart: 24
      }
  , diagram:
      { alignItems: "start"
      , display: "grid"
      , columnGap: 24
      , gridColumn: 1
      , gridRow: 2
      , gridTemplateColumns: "340px minmax(0, 1fr) 280px"
      , justifySelf: "center"
      , maxWidth: 1100
      , paddingBlock: "32px clamp(80px, 9vw, 128px)"
      , position: "relative"
      , rowGap: 28
      , width: "100%"
      , "@media (max-width: 1279px)":
          { gridTemplateColumns: "340px 280px"
          , maxWidth: 645
          , rowGap: 52
          }
      , "@media (max-width: 800px)": { gridTemplateColumns: "minmax(0, 1fr)" }
      , "@media (max-width: 600px)":
          { paddingBlockStart: 28 }
      }
  , diagramBackdrop:
      { alignSelf: "stretch"
      , backgroundImage: "var(--landing-compiler-image)"
      , backgroundPosition: "center"
      , backgroundSize: "cover"
      , gridColumn: "1 / -1"
      , gridRow: "1 / 3"
      , marginInline: "calc(50% - 50vw)"
      , pointerEvents: "none"
      , position: "relative"
      , width: "100vw"
      , zIndex: "-1"
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
          , "@media (max-width: 800px)": "stretch"
          }
      , "@media (min-width: 801px)": { gridColumn: 1, gridRow: 1 }
      , "@media (max-width: 800px)": { gridRow: 1 }
      }
  , outputs:
      { display: "contents" }
  , javascriptNode:
      { "@media (min-width: 1280px)": { gridColumn: 2, gridRow: 1 }
      , "@media (min-width: 801px) and (max-width: 1279px)":
          { gridColumn: "1 / -1", gridRow: 2 }
      , "@media (max-width: 800px)": { gridRow: 3 }
      }
  , outputNode:
      { minHeight: 120
      }
  , semanticNode:
      { justifySelf: "end"
      , maxWidth: 280
      , minHeight: 88
      , "@media (min-width: 1280px)": { gridColumn: 3, gridRow: 1 }
      , "@media (min-width: 801px) and (max-width: 1279px)":
          { alignSelf: "center", gridColumn: 2, gridRow: 1 }
      , "@media (max-width: 800px)":
          { gridRow: 2, justifySelf: "stretch", maxWidth: "none" }
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
  , javascriptValue:
      { "@media (max-width: 600px)":
          { overflowWrap: "anywhere"
          , whiteSpace: "pre-wrap"
          }
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
                [ DOM.div styleProps.introductionCopy
                    [ DOM.h2 { className: styleProps.heading.className, id: "about-heading" }
                        "What is Iris?"
                    , DOM.p styleProps.lead
                        "Iris is a superset of PureScript, written in Rust."
                    , DOM.p styleProps.explanation
                        "Iris compiles PureScript projects managed by Spago and provides code intelligence via its language server implementation. It is designed with incremental compilation from the ground up, making it fast and responsive once the build server is primed."
                    ]
                ]
            , DOM.div { className: styleProps.diagramBackdrop.className, "aria-hidden": true }
                []
            , DOM.div
                { className: styleProps.diagram.className
                , "aria-label":
                    "PureScript source is checked by Iris and becomes JavaScript; the same analysis serves the editor"
                }
                [ DOM.div styleProps.outputs
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
                                    , DOM.span Code.sourceKeyword " do"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceReference "  greet"
                                    , DOM.span Code.sourceString " \"Hello, world!\""
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceReference "  greet"
                                    , DOM.span Code.sourceString " \"Hello again!\""
                                    ]
                                ]
                            )
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
                    , DOM.div
                        (StyleX.props [ styles.node, styles.outputNode, styles.javascriptNode ])
                        [ DOM.span styleProps.nodeLabel "JavaScript"
                        , DOM.pre
                            { className:
                                (StyleX.props [ styles.nodeValue, styles.javascriptValue ]).className
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
                                    , DOM.span Code.sourceComment " /* @__PURE__ */"
                                    , DOM.span {} " (() => {"
                                    ]
                                , DOM.span Code.sourceLine
                                    [ DOM.span Code.sourceKeyword "  const"
                                    , DOM.span Code.sourceVariable " $action"
                                    , DOM.span Code.sourceAccent " ="
                                    , DOM.span Code.sourceReference " greet("
                                    , DOM.span Code.sourceString "\"Hello, world!\""
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
                                    , DOM.span Code.sourceReference " greet("
                                    , DOM.span Code.sourceString "\"Hello again!\""
                                    , DOM.span {} ")();"
                                    ]
                                , DOM.span Code.sourceLine "  };"
                                , DOM.span Code.sourceLine "})();"
                                ]
                            )
                        ]
                    ]
                ]
            ]
        ]
    ]
