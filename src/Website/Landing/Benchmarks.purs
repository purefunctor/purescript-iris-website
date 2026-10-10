module Website.Landing.Benchmarks (benchmarks) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element, fragment)
import Website.Breakpoints (breakpoints)
import Website.Components.ContentShell as ContentShell
import Website.Components.Icon as Icon
import Website.Components.Tabs.Styles (tabStyles)
import Website.Landing.Section as Section
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

-- Medians of five runs (twenty edits for `iris watch`) of `scripts/benchmark-builds.ts` on acme:
-- an Apple M3 Pro with 12 cores and 36 GB of memory, macOS 27.0.1, Iris 0.1.2-dev.759b9415a48e,
-- purs 0.15.16 and Spago 1.0.4.
--
-- The site's content security policy rules out inline styles, so every position is a fixed
-- style below. Positions are percentages of the axis: 70 s for cold builds, 4 s for rebuilds.
-- The bars race in over 1.5 s once the chart is on screen. Switching between the two morphs the
-- one chart over 0.8 s: the bars resize, the axis rescales and the figures crossfade.

foreign import benchmarkChartImpl ::
  ReactComponent
    { chart :: { selected :: String, started :: Boolean } -> JSX
    , controlsClassName :: String
    , footer :: JSX
    , headerClassName :: String
    , iconClassName :: String
    , introduction :: JSX
    , panelClassName :: String
    , rootClassName :: String
    , tabClassName :: String
    , tabListClassName :: String
    , tabs :: Array { icon :: ReactComponent Icon.IconProps, id :: String, label :: String }
    }

-- | A value for each measurement: a cold build, and a rebuild after an edit.
type Measured a = { cold :: a, hot :: a }

type Bar =
  { tool :: Measured String
  , seconds :: Measured String
  , iris :: Boolean
  , width :: Measured StyleX.Style
  }

type Tick = { label :: String, position :: Measured StyleX.Style }

grow = StyleX.keyframes { from: { transform: "scaleX(0)" }, to: { transform: "scaleX(1)" } }

styles =
  StyleX.create
    { root: { display: "flex", flexDirection: "column", gap: 32 }
    , panel: { display: "flex", flexDirection: "column" }
    , header:
        { alignItems: "flex-end"
        , display: "flex"
        , flexWrap: "wrap"
        , rowGap: 24
        , columnGap: 40
        , justifyContent: "space-between"
        }
    , introduction: { display: "flex", flexDirection: "column", gap: 14 }
    , controls: { alignItems: "center", display: "flex", gap: 8 }
    -- Lucide icons render at 1.2em.
    , tabIcon: { flexShrink: 0, fontSize: 11 }
    , chart: { position: "relative" }
    -- Use responsive properties directly: StyleX's unlayered custom-property defaults
    -- otherwise outrank the layered overrides generated from imported conditions.
    , grid:
        { columnGap: StyleX.conditionalValue 24 [ StyleX.conditionalCase breakpoints.upTo600 10 ]
        , display: "grid"
        , gridTemplateColumns:
            StyleX.conditionalValue
              "168px minmax(0, 1fr) 96px"
              [ StyleX.conditionalCase breakpoints.upTo600 "92px minmax(0, 1fr) 64px" ]
        }
    -- Gridlines and the Iris marker sit behind the bars, across the plot column. Ticks that are off
    -- the current axis wait far beyond it, so the overlay and the axis clip just past its end.
    -- Match the grid's label/value widths and gaps, leaving 16px past the plot's end.
    , overlay:
        { insetBlock: 0
        , insetInlineEnd:
            StyleX.conditionalValue
              "calc(96px + 24px - 16px)"
              [ StyleX.conditionalCase breakpoints.upTo600 "calc(64px + 10px - 16px)" ]
        , insetInlineStart:
            StyleX.conditionalValue
              "calc(168px + 24px)"
              [ StyleX.conditionalCase breakpoints.upTo600 "calc(92px + 10px)" ]
        , overflow: "hidden"
        , pointerEvents: "none"
        , position: "absolute"
        }
    , plotArea: { insetBlock: 0, insetInlineEnd: 16, insetInlineStart: 0, position: "absolute" }
    , gridline:
        { backgroundColor: "var(--border-subtle)"
        , insetBlock: 0
        , position: "absolute"
        , transitionDuration: { default: "0.8s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionProperty: "left, opacity"
        , transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)"
        , width: 1
        }
    , marker:
        { backgroundColor: "var(--accent)"
        , insetBlock: 0
        , position: "absolute"
        , transitionDuration: { default: "0.8s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionProperty: "left"
        , transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)"
        , width: 1
        }
    , rows: { listStyle: "none", padding: 0, position: "relative" }
    , row:
        { alignItems: "center"
        , minHeight: StyleX.conditionalValue 88 [ StyleX.conditionalCase breakpoints.upTo600 64 ]
        }
    , tool:
        { color: "var(--text-secondary)"
        , fontFamily: "var(--font-mono)"
        , fontSize: StyleX.conditionalValue 15 [ StyleX.conditionalCase breakpoints.upTo600 12 ]
        , whiteSpace: "nowrap"
        }
    , irisTool: { color: "var(--text-primary)" }
    , plot: { alignItems: "center", display: "flex", minWidth: 0, position: "relative" }
    , bar:
        { backgroundColor: "var(--surface-3)"
        , display: "block"
        , height: StyleX.conditionalValue 32 [ StyleX.conditionalCase breakpoints.upTo600 24 ]
        , transformOrigin: "left"
        , transitionDuration: { default: "0.8s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionProperty: "width"
        , transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)"
        }
    , irisBar: { backgroundColor: "var(--accent)" }
    , waiting:
        { transform: { default: "scaleX(0)", "@media (prefers-reduced-motion: reduce)": "none" } }
    , racing:
        { animationDuration: "1.5s"
        , animationFillMode: "both"
        , animationName: { default: grow, "@media (prefers-reduced-motion: reduce)": "none" }
        -- A strong ease-out: bars shoot out and settle on their result without overshooting it.
        , animationTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)"
        }
    , badge:
        { backgroundColor: "var(--surface-2)"
        , borderRadius: 5
        , color: "var(--text-secondary)"
        , fontFamily: "var(--font-mono)"
        , fontSize: StyleX.conditionalValue 13 [ StyleX.conditionalCase breakpoints.upTo600 11 ]
        , paddingBlock: 4
        , paddingInline: 8
        , position: "absolute"
        , transitionDuration: { default: "0.8s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionProperty: "left"
        , transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)"
        , whiteSpace: "nowrap"
        }
    , badgeComparison:
        { display:
            StyleX.conditionalValue "inline" [ StyleX.conditionalCase breakpoints.upTo600 "none" ]
        }
    , value:
        { alignItems: "center"
        , color: "var(--text-secondary)"
        , display: "flex"
        , fontFamily: "var(--font-mono)"
        , fontSize: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo600 12 ]
        , fontVariantNumeric: "tabular-nums"
        , justifyContent: "flex-end"
        }
    , irisValue: { color: "var(--text-primary)", fontWeight: 600 }
    -- Both figures share one grid cell; the outgoing one fades before the incoming one appears.
    , swap: { display: "inline-grid", justifyItems: "center" }
    , variant:
        { gridRowStart: 1
        , gridColumnStart: 1
        , transitionDelay: { default: "0.1s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionDuration: { default: "0.25s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionProperty: "opacity, filter"
        , transitionTimingFunction: "var(--ease-out)"
        }
    , concealed:
        { filter: "blur(2px)"
        , opacity: 0
        , transitionDelay: "0s"
        , transitionDuration: { default: "0.1s", "@media (prefers-reduced-motion: reduce)": "0s" }
        }
    , axis: { paddingBlockStart: 12 }
    , ticks: { height: 16, marginInlineEnd: -16, overflow: "hidden", position: "relative" }
    , tick:
        { color: "var(--text-tertiary)"
        , fontFamily: "var(--font-mono)"
        , fontSize: 12
        , position: "absolute"
        , transitionDuration: { default: "0.8s", "@media (prefers-reduced-motion: reduce)": "0s" }
        , transitionProperty: "left, opacity"
        , transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)"
        }
    , methodology:
        { color: "var(--text-tertiary)"
        , fontSize: 13
        , lineHeight: 1.5
        , marginBlockStart: 32
        , textWrap: "pretty"
        }
    , link:
        { color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
        , textDecorationLine: "underline"
        , textUnderlineOffset: 3
        }
    , tick0: { left: "0%" }
    -- Cold build on a 70 s axis: 4.25 s, 49.3 s and 66.3 s. The rebuild's ticks fade out at 0 s.
    , coldIrisWidth: { width: "6.07%" }
    , coldPursWidth: { width: "70.43%" }
    , coldSpagoWidth: { width: "94.71%" }
    , coldMarker: { left: "6.07%" }
    , coldBadge: { left: "calc(6.07% + 12px)" }
    , cold1s: { left: "1.429%", opacity: 0 }
    , cold2s: { left: "2.857%", opacity: 0 }
    , cold3s: { left: "4.286%", opacity: 0 }
    , cold4s: { left: "5.714%", opacity: 0 }
    , cold20s: { left: "28.571%" }
    , cold40s: { left: "57.143%" }
    , cold60s: { left: "85.714%" }
    -- Rebuild after an edit on a 4 s axis: 0.28 s, 2.71 s and 3.57 s. The cold build's ticks fade
    -- out past the clipped end of the axis.
    , hotIrisWidth: { width: "7%" }
    , hotPursWidth: { width: "67.75%" }
    , hotSpagoWidth: { width: "89.25%" }
    , hotMarker: { left: "7%" }
    , hotBadge: { left: "calc(7% + 12px)" }
    , hot1s: { left: "25%" }
    , hot2s: { left: "50%" }
    , hot3s: { left: "75%" }
    , hot4s: { left: "100%" }
    , hot20s: { left: "500%", opacity: 0 }
    , hot40s: { left: "1000%", opacity: 0 }
    , hot60s: { left: "1500%", opacity: 0 }
    }

styleProps = StyleX.recordProps styles

tabs :: Array { icon :: ReactComponent Icon.IconProps, id :: String, label :: String }
tabs =
  [ { icon: Icon.snowflake, id: "cold", label: "Cold" }
  , { icon: Icon.flame, id: "hot", label: "Hot" }
  ]

bars :: Array Bar
bars =
  [ { tool: { cold: "iris build", hot: "iris watch" }
    , seconds: { cold: "4.25s", hot: "0.28s" }
    , iris: true
    , width: { cold: styles.coldIrisWidth, hot: styles.hotIrisWidth }
    }
  , { tool: { cold: "purs compile", hot: "purs compile" }
    , seconds: { cold: "49.3s", hot: "2.71s" }
    , iris: false
    , width: { cold: styles.coldPursWidth, hot: styles.hotPursWidth }
    }
  , { tool: { cold: "spago build", hot: "spago build" }
    , seconds: { cold: "66.3s", hot: "3.57s" }
    , iris: false
    , width: { cold: styles.coldSpagoWidth, hot: styles.hotSpagoWidth }
    }
  ]

ticks :: Array Tick
ticks =
  [ { label: "0s", position: { cold: styles.tick0, hot: styles.tick0 } }
  , { label: "1s", position: { cold: styles.cold1s, hot: styles.hot1s } }
  , { label: "2s", position: { cold: styles.cold2s, hot: styles.hot2s } }
  , { label: "3s", position: { cold: styles.cold3s, hot: styles.hot3s } }
  , { label: "4s", position: { cold: styles.cold4s, hot: styles.hot4s } }
  , { label: "20s", position: { cold: styles.cold20s, hot: styles.hot20s } }
  , { label: "40s", position: { cold: styles.cold40s, hot: styles.hot40s } }
  , { label: "60s", position: { cold: styles.cold60s, hot: styles.hot60s } }
  ]

marker :: Measured StyleX.Style
marker = { cold: styles.coldMarker, hot: styles.hotMarker }

badge :: { multiple :: Measured String, position :: Measured StyleX.Style }
badge =
  { multiple: { cold: "11.6×", hot: "9.7×" }
  , position: { cold: styles.coldBadge, hot: styles.hotBadge }
  }

benchmarks :: JSX
benchmarks =
  DOM.section
    { className: Section.section.className
    , id: "benchmarks"
    , "aria-labelledby": "benchmarks-heading"
    }
    ( DOM.div
        ContentShell.contentShell
        ( element
            benchmarkChartImpl
            { chart
            , controlsClassName: styleProps.controls.className
            , footer
            , headerClassName: styleProps.header.className
            , iconClassName: styleProps.tabIcon.className
            , introduction:
                DOM.div
                  styleProps.introduction
                  [ Section.heading
                      { id: "benchmarks-heading"
                      , text: "Builds in seconds, "
                      , emphasis: "rebuilds in milliseconds."
                      }
                  ]
            , panelClassName: styleProps.panel.className
            , rootClassName: styleProps.root.className
            , tabClassName: (StyleX.props tabStyles.tab).className
            , tabListClassName: (StyleX.props tabStyles.tabList).className
            , tabs
            }
        )
    )
  where
  footer =
    DOM.p
      styleProps.methodology
      [ DOM.text
          "Cold builds start from an empty output directory. Hot rebuilds follow an edit to one module, which Iris recompiles in iris watch; it is timed from saving the file to the finished rebuild. Each tool builds acme, which depends on all 648 packages in Registry package set 81.1.0 (7,540 modules). Medians of five runs, and of 20 edits for iris watch, on an Apple M3 Pro (12 cores, 36 GB) with Iris 0.1.2-dev, purs 0.15.16 and Spago 1.0.4. purs compile runs on Spago's sources directly, excluding Spago's overhead. "
      , DOM.a
          { className: styleProps.link.className
          , href:
              "https://github.com/purefunctor/purescript-iris-website/blob/main/scripts/benchmark-builds.ts"
          , rel: "noopener noreferrer"
          , target: targetBlank
          }
          "Run the benchmark yourself"
      , DOM.text "."
      ]

chart :: { selected :: String, started :: Boolean } -> JSX
chart { selected, started } =
  fragment
    [ DOM.div
        styleProps.chart
        [ DOM.div
            { className: styleProps.overlay.className, "aria-hidden": true }
            [ DOM.div
                styleProps.plotArea
                ( map
                      ( \{ position } ->
                          DOM.span (StyleX.props [ styles.gridline, pick position ]) []
                      )
                      ticks
                    <> [ DOM.span (StyleX.props [ styles.marker, pick marker ]) [] ]
                )
            ]
        , DOM.ol styleProps.rows (map row bars)
        ]
    , DOM.div
        { className: (StyleX.props [ styles.grid, styles.axis ]).className, "aria-hidden": true }
        [ DOM.span {} []
        , DOM.div
            styleProps.ticks
            [ DOM.div
                styleProps.plotArea
                ( map
                    ( \{ label, position } ->
                        DOM.span (StyleX.props [ styles.tick, pick position ]) label
                    )
                    ticks
                )
            ]
        , DOM.span {} []
        ]
    ]
  where
  hot = selected == "hot"

  pick :: forall a. Measured a -> a
  pick measured = if hot then measured.hot else measured.cold

  -- Keeps both measurements' figures in place so that switching crossfades between them.
  swap :: Measured (Array JSX) -> JSX
  swap measured =
    DOM.span styleProps.swap [ variant (not hot) measured.cold, variant hot measured.hot ]

  variant shown =
    DOM.span
      { className:
          ( StyleX.props [ styles.variant, StyleX.conditional (not shown) styles.concealed ]
          ).className
      , "aria-hidden": not shown
      }

  figure measured
    | measured.cold == measured.hot = DOM.text measured.cold
    | otherwise = swap { cold: [ DOM.text measured.cold ], hot: [ DOM.text measured.hot ] }

  row { tool, seconds, iris, width } =
    DOM.li
      (StyleX.props [ styles.grid, styles.row ])
      [ DOM.span
          (StyleX.props [ styles.tool, StyleX.conditional iris styles.irisTool ])
          (figure tool)
      , DOM.span
          styleProps.plot
          ( [ DOM.span
                { className:
                    ( StyleX.props
                        [ styles.bar
                        , StyleX.conditional iris styles.irisBar
                        , pick width
                        , if started then styles.racing else styles.waiting
                        ]
                    ).className
                , "aria-hidden": true
                }
                []
            ]
              <> if iris
                 then
                   [ DOM.span
                       (StyleX.props [ styles.badge, pick badge.position ])
                       ( swap
                           { cold: comparison badge.multiple.cold
                           , hot: comparison badge.multiple.hot
                           }
                       )
                   ]
                 else []
          )
      , DOM.span
          (StyleX.props [ styles.value, StyleX.conditional iris styles.irisValue ])
          (figure seconds)
      ]

  comparison multiple =
    [ DOM.text (multiple <> " faster"), DOM.span styleProps.badgeComparison " than purs compile" ]
