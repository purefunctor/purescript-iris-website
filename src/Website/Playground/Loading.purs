module Website.Playground.Loading (loading) where

import Prelude

import Data.Array (range)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import React.Basic.Events (handler_)
import Website.Breakpoints (breakpoints)
import Website.Components.Icon as Icon
import Website.Playground.Button.Styles (buttonStyles)
import Website.Playground.Types (State)
import Yoga.React.DOM as DOM

data Stage = Pending | Active | Done | Interrupted

derive instance Eq Stage

segmentCount :: Int
segmentCount = 32

pulse = StyleX.keyframes { from: { opacity: 1 }, "50%": { opacity: 0.35 }, to: { opacity: 1 } }

styles = StyleX.create
  { root:
      { alignItems: "center"
      , backgroundColor: "var(--bg-canvas)"
      , display: "flex"
      , flexDirection: "column"
      , inset: 0
      , justifyContent: "flex-start"
      , overflowY: "auto"
      , paddingBlock: 24
      , paddingInline: "var(--gutter)"
      , position: "absolute"
      , zIndex: 1
      , backgroundImage:
          "linear-gradient(var(--grid-line) 1px, transparent 1px), linear-gradient(90deg, var(--grid-line) 1px, transparent 1px)"
      , backgroundPosition: "center"
      , backgroundSize: "48px 48px"
      }
  , panel:
      { backgroundColor: "var(--granite-850)"
      , backgroundImage:
          "radial-gradient(circle at 18px 18px, var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), radial-gradient(circle at calc(100% - 18px) 18px, var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), radial-gradient(circle at 18px calc(100% - 18px), var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), radial-gradient(circle at calc(100% - 18px) calc(100% - 18px), var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), linear-gradient(100deg, transparent 15%, oklch(from var(--granite-50) l c h / 4%) 40%, transparent 65%), repeating-linear-gradient(0deg, oklch(from var(--granite-50) l c h / 2.5%) 0 1px, transparent 1px 3px), linear-gradient(180deg, oklch(from var(--granite-50) l c h / 5%), transparent 30%, oklch(0% 0 0 / 20%))"
      , borderColor: "oklch(0% 0 0 / 70%)"
      , borderStyle: "solid"
      , borderWidth: 1
      , boxShadow:
          "inset 0 1px 0 oklch(from var(--granite-50) l c h / 16%), inset 0 -1px 0 oklch(0% 0 0 / 60%), inset 0 0 0 5px oklch(from var(--granite-950) l c h / 25%), 0 40px 80px -40px oklch(0% 0 0 / 80%)"
      , display: "flex"
      , flexDirection: "column"
      , gap: 24
      , flexShrink: 0
      , marginBlock: "auto"
      , maxWidth: 560
      , paddingBlock: StyleX.conditionalValue 40 [ StyleX.conditionalCase breakpoints.upTo480 28 ]
      , paddingInline: StyleX.conditionalValue 44 [ StyleX.conditionalCase breakpoints.upTo480 22 ]
      , width: "100%"
      }
  , top:
      { alignItems: "center"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: "8px 16px"
      , justifyContent: "space-between"
      }
  , heading: { fontSize: 22, fontWeight: 600, letterSpacing: "-0.02em", lineHeight: 1.2 }
  , readout:
      { alignItems: "baseline"
      , backgroundColor: "oklch(from var(--granite-950) calc(l - 0.03) c h)"
      , boxShadow:
          "inset 0 2px 6px oklch(0% 0 0 / 60%), inset 0 0 0 1px oklch(0% 0 0 / 50%), 0 1px 0 var(--glass-highlight)"
      , display: "flex"
      , flexDirection: "column"
      , gap: 14
      , paddingBlock: 16
      , paddingInline: StyleX.conditionalValue 18 [ StyleX.conditionalCase breakpoints.upTo480 14 ]
      }
  , figures:
      { alignItems: "baseline"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: "6px 16px"
      , justifyContent: "space-between"
      , width: "100%"
      }
  , count: { alignItems: "baseline", display: "flex", gap: 6 }
  , value:
      { color: "var(--signal-300)"
      , fontSize: StyleX.conditionalValue 40 [ StyleX.conditionalCase breakpoints.upTo480 32 ]
      , fontVariantNumeric: "tabular-nums"
      , fontWeight: 600
      , letterSpacing: "-0.04em"
      , lineHeight: 1
      , textShadow: "0 0 18px oklch(from var(--signal-400) l c h / 55%)"
      }
  , unit: { color: "var(--signal-400)", fontFamily: "var(--font-mono)", fontSize: 13, opacity: 0.9 }
  , meter:
      { display: "grid", gap: 3, gridTemplateColumns: "repeat(32, minmax(0, 1fr))", width: "100%" }
  , segment:
      { backgroundColor: "var(--granite-800)"
      , boxShadow: "inset 0 1px 0 oklch(0% 0 0 / 40%)"
      , height: 12
      , transitionDuration: "160ms"
      , transitionProperty: "background-color, box-shadow"
      }
  , litSegment:
      { backgroundColor: "var(--accent)"
      , boxShadow: "0 0 8px oklch(from var(--signal-400) l c h / 60%)"
      }
  , stages: { display: "flex", flexDirection: "column", gap: 2, listStyle: "none", padding: 0 }
  , stage:
      { alignItems: "center"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , color: "var(--text-tertiary)"
      , display: "flex"
      , fontSize: 14
      , gap: 12
      , paddingBlock: 10
      }
  , lit: { color: "var(--text-primary)" }
  , leading:
      { backgroundColor: "oklch(from var(--signal-400) l c h / 6%)"
      , boxShadow: "inset 2px 0 0 var(--accent)"
      , fontWeight: 500
      , marginInline: -12
      , paddingInline: 12
      }
  , led:
      { backgroundColor: "var(--granite-700)"
      , boxShadow: "inset 0 1px 1px oklch(0% 0 0 / 50%)"
      , flexShrink: 0
      , height: 6
      , width: 6
      }
  , doneLed: { backgroundColor: "var(--accent)", boxShadow: "0 0 8px var(--accent)" }
  , activeLed:
      { animationDirection: "normal"
      , animationDuration: "1.2s"
      , animationIterationCount: "infinite"
      , animationName: { default: pulse, "@media (prefers-reduced-motion: reduce)": "none" }
      , backgroundColor: "var(--accent)"
      , boxShadow: "0 0 8px var(--accent)"
      }
  , stageName: { flexGrow: 1 }
  , stageState:
      { fontFamily: "var(--font-mono)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      , textAlign: "end"
      }
  , note:
      { borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , color: "var(--text-tertiary)"
      , fontSize: 12
      , lineHeight: 1.5
      , marginBlockStart: -8
      , paddingBlockStart: 16
      , textWrap: "pretty"
      }
  , visuallyHidden:
      { clipPath: "inset(50%)"
      , height: 1
      , overflow: "hidden"
      , position: "absolute"
      , whiteSpace: "nowrap"
      , width: 1
      }
  , error:
      { backgroundColor: "oklch(from var(--granite-950) calc(l - 0.03) c h)"
      , boxShadow: "inset 0 2px 6px oklch(0% 0 0 / 60%), inset 2px 0 0 var(--red-300)"
      , color: "var(--text-secondary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , lineHeight: 1.6
      , margin: 0
      , overflowWrap: "anywhere"
      , paddingBlock: 14
      , paddingInline: 16
      , whiteSpace: "pre-wrap"
      }
  , fault:
      { alignItems: "center"
      , color: "var(--red-300)"
      , display: "inline-flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , gap: 6
      , letterSpacing: "0.06em"
      }
  , faultLed:
      { backgroundColor: "var(--red-300)"
      , boxShadow: "0 0 8px var(--red-300)"
      , height: 6
      , width: 6
      }
  , frozen: { color: "var(--text-secondary)", textShadow: "none" }
  , dimSegment: { backgroundColor: "var(--granite-500)", boxShadow: "none" }
  , retry: { alignSelf: "flex-start" }
  , icon: { display: "inline-flex", fontSize: 12 }
  }

styleProps = StyleX.recordProps styles

loading :: State -> Effect Unit -> JSX
loading state retry =
  DOM.section { className: styleProps.root.className, "aria-labelledby": "playground-loading" }
    [ DOM.div styleProps.panel
        ( [ DOM.div styleProps.top
              [ DOM.h1 { className: styleProps.heading.className, id: "playground-loading" }
                  (if failed then "The playground could not start" else "Starting the playground")
              , if failed
                then DOM.span { className: styleProps.fault.className, "aria-hidden": true }
                  [ DOM.span styleProps.faultLed [], DOM.text "FAULT" ]
                else mempty
              ]
          , DOM.p { className: styleProps.visuallyHidden.className, role: "status" } announcement
          , readout
          , DOM.ol { className: styleProps.stages.className, role: "list" }
              [ stage "Load packages" packagesStage packagesDetail false
              , stage "Load the language server" serverStage serverDetail downloaded
              , stage "Open the editor" editorStage "" true
              ]
          ]
            <> if failed
               then failure
               else
                 [ DOM.p styleProps.note
                     "Packages stay in this browser's cache when it allows, so later visits can start faster."
                 ]
        )
    ]
  where
  packages = state.packages
  failed = state.phase == "failed"
  serverReady = state.server.status == "ready"
  known = packages.total > 0
  downloaded = serverReady || (known && packages.loaded >= packages.total)

  progressing isDone
    | isDone = Done
    | failed = Interrupted
    | otherwise = Active

  packagesStage = progressing downloaded
  serverStage = progressing serverReady
  editorStage = if serverReady then progressing false else Pending

  announcement
    | failed = ""
    | serverReady = "Opening the editor"
    | downloaded = "Packages loaded. Loading the language server"
    | otherwise = "Loading packages and the language server"

  packagesDetail
    | packagesStage == Done && known = show packages.total <> " packages"
    | packagesStage == Active && packages.totalBytes > 0 =
      megabytes packages.bytes <> " of " <> megabytes packages.totalBytes <> " MB"
    | otherwise = ""

  serverDetail
    | serverStage /= Active = ""
    | state.server.status == "restarting" = "Restarting"
    | otherwise = "Starting"

  lit
    | downloaded = segmentCount
    | not known = 0
    | otherwise = (packages.loaded * segmentCount) / packages.total

  segments = map
    ( \index -> DOM.span
        ( StyleX.props
            [ styles.segment
            , StyleX.conditional (index < lit) styles.litSegment
            , StyleX.conditional (index < lit && failed) styles.dimSegment
            ]
        )
        []
    )
    (range 0 (segmentCount - 1))

  meter =
    if known
    then DOM.div
      { className: styleProps.meter.className
      , role: "progressbar"
      , "aria-label": "Packages loaded"
      , "aria-valuemin": 0
      , "aria-valuemax": packages.total
      , "aria-valuenow": packages.loaded
      , "aria-valuetext": show packages.loaded <> " of " <> show packages.total <> " packages"
      }
      segments
    else DOM.div
      { className: styleProps.meter.className
      , role: "progressbar"
      , "aria-label": "Packages loaded"
      , "aria-valuetext": "Preparing packages"
      }
      segments

  readout = DOM.div styleProps.readout
    [ DOM.div styleProps.figures
        [ DOM.span styleProps.count
            [ DOM.span (StyleX.props [ styles.value, StyleX.conditional failed styles.frozen ])
                (if known then show packages.loaded else "--")
            , DOM.span (StyleX.props [ styles.unit, StyleX.conditional failed styles.frozen ])
                (if known then "of " <> show packages.total <> " packages" else "packages")
            ]
        ]
    , meter
    ]

  stage name status detail emphasis = DOM.li
    ( StyleX.props
        [ styles.stage
        , StyleX.conditional (status /= Pending) styles.lit
        , StyleX.conditional (emphasis && status == Active) styles.leading
        ]
    )
    [ DOM.span
        { className:
            ( StyleX.props
                [ styles.led
                , StyleX.conditional (status == Done) styles.doneLed
                , StyleX.conditional (status == Active) styles.activeLed
                ]
            ).className
        , "aria-hidden": true
        }
        []
    , DOM.span styleProps.stageName name
    , DOM.span styleProps.stageState
        ( case status of
            Done -> if detail == "" then "Ready" else detail
            Active -> if detail == "" then "Working" else detail
            Interrupted -> "Interrupted"
            Pending -> if failed then "Not started" else "Waiting"
        )
    ]

  failure =
    [ DOM.pre { className: styleProps.error.className, role: "alert" }
        (fromMaybe "Something went wrong." (toMaybe state.server.message))
    , DOM.button
        { className:
            ( StyleX.props
                [ buttonStyles.action, buttonStyles.raised, buttonStyles.accent, styles.retry ]
            ).className
        , onClick: handler_ retry
        , type: "button"
        }
        [ DOM.span styleProps.icon
            (element Icon.rotateCcw { "aria-hidden": true, focusable: false })
        , DOM.text "Try again"
        ]
    ]

megabytes :: Int -> String
megabytes bytes = show (tenths / 10) <> "." <> show (tenths `mod` 10)
  where
  bytesPerTenth = 100000
  tenths = (bytes + bytesPerTenth / 2) / bytesPerTenth
