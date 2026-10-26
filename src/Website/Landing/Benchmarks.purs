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

foreign import benchmarkChartImpl ::
  ReactComponent
    { chart :: { selected :: String, started :: Boolean } -> JSX
    , controlsClassName :: String
    , footer :: JSX
    , headerClassName :: String
    , introduction :: JSX
    , panelClassName :: String
    , rootClassName :: String
    , particlesClassName :: String
    , tabListClassName :: String
    , tabs :: Array Tab
    }

type Tab =
  { className :: String
  , icon :: ReactComponent Icon.IconProps
  , iconClassName :: String
  , id :: String
  , label :: String
  }

type Measured a = { cold :: a, hot :: a }

type Bar =
  { tool :: Measured String
  , seconds :: Measured String
  , iris :: Boolean
  , width :: Measured StyleX.Style
  }

type Tick = { label :: String, position :: Measured StyleX.Style }

grow = StyleX.keyframes { from: { transform: "scaleX(0)" }, to: { transform: "scaleX(1)" } }

raceDuration :: String
raceDuration = "1.5s"

morphDuration :: String
morphDuration = "0.8s"

strongEaseOut :: String
strongEaseOut = "cubic-bezier(0.16, 1, 0.3, 1)"

styles = StyleX.create
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
  , controls: { alignItems: "center", display: "flex", gap: 8, position: "relative" }
  , particles:
      { height: "calc(100% + 200px)"
      , insetBlockStart: -140
      , insetInlineStart: -80
      , maxWidth: "none"
      , pointerEvents: "none"
      , position: "absolute"
      , width: "calc(100% + 160px)"
      , zIndex: 1
      }
  , tabIcon: { flexShrink: 0, fontSize: 11 }
  , coldIcon: { color: "var(--frost-400)" }
  , hotIcon: { color: "var(--ember-400)" }
  , coldTab:
      { backgroundColor:
          { default: "transparent"
          , ":hover": "var(--glass-fill)"
          , "[data-selected]": "oklch(from var(--frost-400) l c h / 16%)"
          }
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--frost-300)"
          , "[data-selected]": "var(--frost-300)"
          }
      }
  , hotTab:
      { backgroundColor:
          { default: "transparent"
          , ":hover": "var(--glass-fill)"
          , "[data-selected]": "oklch(from var(--ember-400) l c h / 16%)"
          }
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--ember-300)"
          , "[data-selected]": "var(--ember-300)"
          }
      }
  , chart: { position: "relative" }
  , grid:
      { columnGap: StyleX.conditionalValue 24 [ StyleX.conditionalCase breakpoints.upTo600 10 ]
      , display: "grid"
      , gridTemplateColumns: StyleX.conditionalValue "168px minmax(0, 1fr) 96px"
          [ StyleX.conditionalCase breakpoints.upTo600 "92px minmax(0, 1fr) 64px" ]
      }
  , overlay:
      { insetBlock: 0
      , insetInlineEnd: StyleX.conditionalValue "calc(96px + 24px - 16px)"
          [ StyleX.conditionalCase breakpoints.upTo600 "calc(64px + 10px - 16px)" ]
      , insetInlineStart: StyleX.conditionalValue "calc(168px + 24px)"
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
      , transitionDuration:
          { default: morphDuration, "@media (prefers-reduced-motion: reduce)": "0s" }
      , transitionProperty: "left, opacity"
      , transitionTimingFunction: strongEaseOut
      , width: 1
      }
  , marker:
      { backgroundColor: "var(--accent)"
      , insetBlock: 0
      , position: "absolute"
      , transitionDuration:
          { default: morphDuration, "@media (prefers-reduced-motion: reduce)": "0s" }
      , transitionProperty: "left"
      , transitionTimingFunction: strongEaseOut
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
      , transitionDuration:
          { default: morphDuration, "@media (prefers-reduced-motion: reduce)": "0s" }
      , transitionProperty: "width"
      , transitionTimingFunction: strongEaseOut
      }
  , irisBar: { backgroundColor: "var(--accent)" }
  , waiting:
      { transform: { default: "scaleX(0)", "@media (prefers-reduced-motion: reduce)": "none" } }
  , racing:
      { animationDuration: raceDuration
      , animationFillMode: "both"
      , animationName: { default: grow, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: strongEaseOut
      }
  , badge:
      { backgroundColor: "var(--surface-2)"
      , borderRadius: 999
      , color: "var(--text-secondary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: StyleX.conditionalValue 13 [ StyleX.conditionalCase breakpoints.upTo600 11 ]
      , paddingBlock: 4
      , paddingInline: 8
      , position: "absolute"
      , transitionDuration:
          { default: morphDuration, "@media (prefers-reduced-motion: reduce)": "0s" }
      , transitionProperty: "left"
      , transitionTimingFunction: strongEaseOut
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
      , transitionDuration:
          { default: morphDuration, "@media (prefers-reduced-motion: reduce)": "0s" }
      , transitionProperty: "left, opacity"
      , transitionTimingFunction: strongEaseOut
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

tabs :: Array Tab
tabs =
  [ { className: (StyleX.props [ tabStyles.tab, styles.coldTab ]).className
    , icon: Icon.snowflake
    , iconClassName: (StyleX.props [ styles.tabIcon, styles.coldIcon ]).className
    , id: "cold"
    , label: "Cold"
    }
  , { className: (StyleX.props [ tabStyles.tab, styles.hotTab ]).className
    , icon: Icon.flame
    , iconClassName: (StyleX.props [ styles.tabIcon, styles.hotIcon ]).className
    , id: "hot"
    , label: "Hot"
    }
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
benchmarks = DOM.section
  { className: Section.section.className
  , id: "benchmarks"
  , "aria-labelledby": "benchmarks-heading"
  }
  ( DOM.div ContentShell.contentShell
      ( element benchmarkChartImpl
          { chart
          , controlsClassName: styleProps.controls.className
          , footer
          , headerClassName: styleProps.header.className
          , introduction: DOM.div styleProps.introduction
              [ Section.heading
                  { id: "benchmarks-heading"
                  , text: "Builds in seconds, "
                  , emphasis: "rebuilds in milliseconds."
                  }
              ]
          , panelClassName: styleProps.panel.className
          , particlesClassName: styleProps.particles.className
          , rootClassName: styleProps.root.className
          , tabListClassName: (StyleX.props tabStyles.tabList).className
          , tabs
          }
      )
  )
  where
  footer = DOM.p styleProps.methodology
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
chart { selected, started } = fragment
  [ DOM.div styleProps.chart
      [ DOM.div { className: styleProps.overlay.className, "aria-hidden": true }
          [ DOM.div styleProps.plotArea
              ( map (\{ position } -> DOM.span (StyleX.props [ styles.gridline, pick position ]) [])
                    ticks
                  <> [ DOM.span (StyleX.props [ styles.marker, pick marker ]) [] ]
              )
          ]
      , DOM.ol styleProps.rows (map row bars)
      ]
  , DOM.div
      { className: (StyleX.props [ styles.grid, styles.axis ]).className, "aria-hidden": true }
      [ DOM.span {} []
      , DOM.div styleProps.ticks
          [ DOM.div styleProps.plotArea
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

  swap :: Measured (Array JSX) -> JSX
  swap measured =
    DOM.span styleProps.swap [ variant (not hot) measured.cold, variant hot measured.hot ]

  variant shown = DOM.span
    { className:
        (StyleX.props [ styles.variant, StyleX.conditional (not shown) styles.concealed ]).className
    , "aria-hidden": not shown
    }

  figure measured
    | measured.cold == measured.hot = DOM.text measured.cold
    | otherwise = swap { cold: [ DOM.text measured.cold ], hot: [ DOM.text measured.hot ] }

  row { tool, seconds, iris, width } = DOM.li (StyleX.props [ styles.grid, styles.row ])
    [ DOM.span (StyleX.props [ styles.tool, StyleX.conditional iris styles.irisTool ]) (figure tool)
    , DOM.span styleProps.plot
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
                 [ DOM.span (StyleX.props [ styles.badge, pick badge.position ])
                     ( swap
                         { cold: comparison badge.multiple.cold
                         , hot: comparison badge.multiple.hot
                         }
                     )
                 ]
               else []
        )
    , DOM.span (StyleX.props [ styles.value, StyleX.conditional iris styles.irisValue ])
        (figure seconds)
    ]

  comparison multiple =
    [ DOM.text (multiple <> " faster"), DOM.span styleProps.badgeComparison " than purs compile" ]
