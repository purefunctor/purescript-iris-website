module Website.Landing.Closing (closing) where

import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import Website.Breakpoints (breakpoints)
import Website.Components.ContentShell as ContentShell
import Website.Components.Icon as Icon
import Website.Components.Installation as Installation
import Website.Components.Logo (logo)
import Website.Components.Terminal as Terminal
import Website.Landing.Section as Section
import Yoga.React.DOM as DOM

styles = StyleX.create
  { section: { paddingBlock: "clamp(56px, 7vw, 96px)" }
  , panel:
      { alignItems: "center"
      , backgroundColor: "var(--granite-850)"
      , backgroundImage:
          "radial-gradient(circle at 20px 20px, var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), radial-gradient(circle at calc(100% - 20px) 20px, var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), radial-gradient(circle at 20px calc(100% - 20px), var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), radial-gradient(circle at calc(100% - 20px) calc(100% - 20px), var(--granite-700) 0 3px, oklch(0% 0 0 / 70%) 3px 4px, transparent 4.5px), linear-gradient(100deg, transparent 15%, oklch(from var(--granite-50) l c h / 4%) 40%, transparent 65%), repeating-linear-gradient(0deg, oklch(from var(--granite-50) l c h / 2.5%) 0 1px, transparent 1px 3px), repeating-linear-gradient(0deg, oklch(0% 0 0 / 18%) 0 1px, transparent 1px 7px), linear-gradient(180deg, oklch(from var(--granite-50) l c h / 5%), transparent 30%, oklch(0% 0 0 / 20%))"
      , borderColor: "oklch(0% 0 0 / 70%)"
      , borderStyle: "solid"
      , borderWidth: 1
      , boxShadow:
          "inset 0 1px 0 oklch(from var(--granite-50) l c h / 16%), inset 1px 0 0 oklch(from var(--granite-50) l c h / 6%), inset -1px 0 0 oklch(0% 0 0 / 40%), inset 0 -1px 0 oklch(0% 0 0 / 60%), inset 0 0 0 5px oklch(from var(--granite-950) l c h / 25%), 0 40px 80px -40px oklch(0% 0 0 / 80%)"
      , display: "grid"
      , gap: "clamp(32px, 5vw, 64px)"
      , gridTemplateColumns: StyleX.conditionalValue "minmax(0, 1fr) minmax(0, 1fr)"
          [ StyleX.conditionalCase breakpoints.upTo960 "minmax(0, 1fr)" ]
      , padding: "clamp(24px, 5vw, 64px)"
      }
  , copy: { display: "flex", flexDirection: "column", gap: 24, minWidth: 0 }
  , terminal: { minWidth: 0 }
  , lockup:
      { alignItems: "center"
      , display: "inline-flex"
      , gap: "0.08em"
      , verticalAlign: "bottom"
      , whiteSpace: "nowrap"
      }
  , wordmark: { fontWeight: 900, letterSpacing: "-0.05em" }
  , mark: { flexShrink: 0, height: "0.9em", width: "0.9em" }
  , well:
      { alignSelf: "flex-start"
      , backgroundColor: "var(--granite-950)"
      , borderColor: "oklch(0% 0 0 / 70%)"
      , borderStyle: "solid"
      , borderWidth: 1
      , boxShadow:
          "inset 0 2px 6px oklch(0% 0 0 / 60%), 0 1px 0 oklch(from var(--granite-50) l c h / 8%)"
      , maxWidth: "100%"
      , padding: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo480 10 ]
      }
  , guide:
      { alignItems: "center"
      , alignSelf: "flex-start"
      , color: { default: "var(--accent-text)", ":hover": "var(--signal-200)" }
      , display: "inline-flex"
      , fontSize: 15
      , gap: 8
      , outlineColor: "var(--focus-ring)"
      , textDecoration: "none"
      }
  , guideIcon: { display: "inline-flex", fontSize: 14 }
  }

styleProps = StyleX.recordProps styles

closing :: JSX
closing =
  DOM.section { className: styleProps.section.className, "aria-labelledby": "closing-heading" }
    [ DOM.div ContentShell.contentShell
        [ DOM.div styleProps.panel
            [ DOM.div styleProps.copy
                [ DOM.div {}
                    [ Section.eyebrow { index: "05", label: "Get started" }
                    , DOM.h2
                        { className: (StyleX.props [ Section.headingStyle ]).className
                        , id: "closing-heading"
                        }
                        [ DOM.text "Start building with "
                        , DOM.span styleProps.lockup
                            [ DOM.span styleProps.wordmark "IRIS"
                            , logo { className: styleProps.mark.className }
                            ]
                        ]
                    ]
                , Section.lead
                    "Install the binary, create a project with Spago's template, and run it with Node.js."
                , DOM.div styleProps.well (Installation.installation { fill: false })
                , DOM.a { className: styleProps.guide.className, href: "/docs/getting-started/" }
                    [ DOM.text "Read the getting started guide"
                    , DOM.span styleProps.guideIcon
                        (element Icon.arrowRight { "aria-hidden": true, focusable: false })
                    ]
                ]
            , DOM.div styleProps.terminal
                ( Terminal.terminal
                    [ { command: "mkdir hello-iris", output: "" }
                    , { command: "cd hello-iris", output: "" }
                    , { command: "iris new"
                      , output:
                          "Created package `hello-iris` with package set 81.6.0.\nRun `iris build` to get started."
                      }
                    , { command: "iris run"
                      , output:
                          "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nNo lockfile found, generating it...\nLockfile written to spago.lock. Please commit this file.\n🍝"
                      }
                    ]
                )
            ]
        ]
    ]
