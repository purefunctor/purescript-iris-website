module Website.Landing.Features.Code where

import Iris.StyleX as StyleX
import Website.Breakpoints (breakpoints)

styles =
  StyleX.create
    { preview:
        { color: "var(--landing-color-latte-text)"
        , fontFamily: "JetBrains Mono Variable, monospace"
        , fontSize:
            StyleX.conditionalValue
              "16px"
              [ StyleX.conditionalCase
                  breakpoints.upTo800
                  "clamp(11.5px, 3.1vw, 12.5px)"
              ]
        , height:
            StyleX.conditionalValue
              "100%"
              [ StyleX.conditionalCase breakpoints.upTo800 "auto" ]
        , lineHeight: 1.25
        , margin: 0
        , minWidth: 0
        , overflowX: "auto"
        , overflowY: "hidden"
        , paddingBlock:
            StyleX.conditionalValue
              0
              [ StyleX.conditionalCase breakpoints.upTo800 12 ]
        , paddingInline: 0
        , whiteSpace: "pre"
        , width: "100%"
        }
    , sourcePreview:
        { "WebkitMaskImage":
            "linear-gradient(to bottom, black 0%, black 42%, transparent 100%)"
        , maskImage:
            "linear-gradient(to bottom, black 0%, black 42%, transparent 100%)"
        }
    , sourceLine: { display: "block" }
    , sourceKeyword:
        { color: "var(--landing-color-latte-mauve)", fontWeight: 650 }
    , sourceReference: { color: "var(--landing-color-latte-yellow)" }
    , sourceSyntax: { color: "var(--landing-color-latte-mauve)" }
    , sourceDeclaration:
        { color: "var(--landing-color-latte-blue)", fontStyle: "italic" }
    , sourceType:
        { color: "var(--landing-color-latte-yellow)", fontStyle: "italic" }
    , sourceVariable:
        { color: "var(--landing-color-latte-red)", fontStyle: "italic" }
    , sourceString: { color: "var(--landing-color-latte-green)" }
    , sourceAccent: { color: "var(--landing-color-latte-teal)" }
    , sourceBracket: { color: "var(--landing-color-latte-red)" }
    , sourceText: { color: "var(--landing-color-latte-text)" }
    , sourceComment: { color: "var(--landing-color-latte-subtext-1)" }
    }

styleProps = StyleX.recordProps styles

sourcePreview = StyleX.props [ styles.preview, styles.sourcePreview ]
editorPreview = styleProps.preview
sourceLine = styleProps.sourceLine
sourceKeyword = styleProps.sourceKeyword
sourceReference = styleProps.sourceReference
sourceSyntax = styleProps.sourceSyntax
sourceDeclaration = styleProps.sourceDeclaration
sourceType = styleProps.sourceType
sourceVariable = styleProps.sourceVariable
sourceString = styleProps.sourceString
sourceAccent = styleProps.sourceAccent
sourceBracket = styleProps.sourceBracket
sourceText = styleProps.sourceText
sourceComment = styleProps.sourceComment
