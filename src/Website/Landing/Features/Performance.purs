module Website.Landing.Features.Performance (performanceMedia) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Website.Breakpoints (breakpoints)
import Yoga.React.DOM as DOM

styles =
  StyleX.create
    { performanceOutput:
        { color: "var(--landing-color-latte-text)"
        , fontFamily: "JetBrains Mono Variable, monospace"
        , fontSize:
            StyleX.conditionalValue
              "16px"
              [ StyleX.conditionalCase
                  breakpoints.upTo800
                  "clamp(11.5px, 3.1vw, 12.5px)"
              ]
        , fontVariantNumeric: "tabular-nums"
        , lineHeight: 1.25
        , margin: 0
        , maxWidth: "100%"
        , overflowX: "auto"
        , paddingBlock:
            StyleX.conditionalValue
              0
              [ StyleX.conditionalCase breakpoints.upTo800 12 ]
        , paddingInline: 0
        , width: "100%"
        }
    , performanceLine: { display: "block" }
    , performancePhase: { fontWeight: 600 }
    , performanceBar: { color: "var(--landing-color-latte-teal)" }
    , performanceFinished:
        { color: "var(--landing-color-latte-green)", fontWeight: 650 }
    , performanceBarTail:
        { display:
            StyleX.conditionalValue
              "inline"
              [ StyleX.conditionalCase breakpoints.upTo800 "none" ]
        }
    }

styleProps = StyleX.recordProps styles

performanceBarTail =
  StyleX.props [ styles.performanceBar, styles.performanceBarTail ]

performanceMedia :: JSX
performanceMedia =
  DOM.pre
    styleProps.performanceOutput
    [ DOM.code
        {}
        [ performanceProgressLine "  Analyse"
        , performanceProgressLine "Elaborate"
        , performanceProgressLine "  Codegen"
        , performanceProgressLine "   Output"
        , DOM.span
            styleProps.performanceLine
            [ DOM.span styleProps.performanceFinished " Finished"
            , DOM.span {} " in 3.08s via 12 jobs"
            ]
        ]
    ]

performanceProgressLine :: String -> JSX
performanceProgressLine label =
  DOM.span
    styleProps.performanceLine
    [ DOM.span styleProps.performancePhase label
    , DOM.span {} " ["
    , DOM.span styleProps.performanceBar "==================="
    , DOM.span performanceBarTail "===="
    , DOM.span {} "] 7355/7355"
    ]
