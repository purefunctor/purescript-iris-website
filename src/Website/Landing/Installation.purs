module Website.Landing.Installation (installationSection) where

import Iris.StyleX as StyleX
import Website.Components.ContentShell as ContentShell
import React.Basic (JSX, ReactComponent, element)
import Yoga.React.DOM as DOM

foreign import installationCommandsImpl ::
  ReactComponent
    { commandClassName :: String
    , copyButtonClassName :: String
    , copyButtonVisibleClassName :: String
    , promptClassName :: String
    , rootClassName :: String
    , heading :: JSX
    , headingRowClassName :: String
    , tabClassName :: String
    , tabListClassName :: String
    , terminalClassName :: String
    , tooltipClassName :: String
    }

styles = StyleX.create
  { section:
      { backgroundColor: "oklch(96.5% 0.026 282)"
      , backgroundImage:
          "linear-gradient(90deg, transparent 0 58%, oklch(from var(--landing-color-paper) l c h / 28%) 100%)"
      , color: "var(--landing-color-ink)"
      , scrollMarginTop: "var(--landing-header-height)"
      , width: "100%"
      }
  , content:
      { paddingBlock: "40px 72px"
      , "@media (max-width: 800px)":
          { paddingBlock: "40px 64px"
          }
      }
  , title:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "var(--landing-type-statement)"
      , fontWeight: 500
      , letterSpacing: "-0.035em"
      , lineHeight: 1.1
      }
  , commands:
      { backgroundColor: "transparent"
      , display: "grid"
      , gap: 24
      , minWidth: 0
      }
  , headingRow:
      { alignItems: "flex-start"
      , display: "flex"
      , flexDirection: "column"
      , gap: 20
      }
  , tabList:
      { display: "flex"
      , gap: 8
      }
  , tab:
      { alignItems: "center"
      , backgroundColor:
          { default: "transparent"
          , ":hover": "oklch(from var(--landing-color-ink) l c h / 7%)"
          , "[data-selected]": "oklch(from var(--landing-color-violet) l c h / 10%)"
          }
      , borderColor:
          { default: "oklch(from var(--landing-color-ink) l c h / 16%)"
          , ":hover": "oklch(from var(--landing-color-ink) l c h / 34%)"
          , "[data-selected]": "var(--landing-color-violet)"
          }
      , borderRadius: 2
      , borderStyle: "solid"
      , borderWidth: 1
      , color: "var(--landing-color-ink)"
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: "var(--landing-type-small)"
      , fontWeight: 600
      , gap: 7
      , minHeight: 38
      , justifyContent: "center"
      , paddingInline: 12
      , transition: "background-color 160ms ease, border-color 160ms ease"
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 3
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , command:
      { alignItems: "center"
      , display: "grid"
      , gap: 12
      , gridTemplateColumns: "minmax(0, 1fr) 36px"
      , maxWidth: "100%"
      , minHeight: 36
      , minWidth: 0
      , width: "fit-content"
      }
  , terminal:
      { color: "var(--landing-color-ink)"
      , fontFamily: "var(--landing-font-code)"
      , fontSize: 14
      , lineHeight: 1.5
      , minWidth: 0
      , overflowWrap: "anywhere"
      , overflowX: "auto"
      , padding: 0
      , whiteSpace: "pre-wrap"
      , width: "100%"
      }
  , prompt:
      { color: "var(--landing-color-violet)"
      }
  , copyButton:
      { alignItems: "center"
      , backgroundColor:
          { default: "oklch(from var(--landing-color-ink) l c h / 7%)"
          , ":hover": "oklch(from var(--landing-color-ink) l c h / 13%)"
          }
      , borderRadius: 999
      , color: "var(--landing-color-ink)"
      , display: "inline-flex"
      , height: 36
      , justifyContent: "center"
      , opacity: 0
      , transform: "translateY(3px)"
      , transition: "background-color 160ms ease, opacity 160ms ease, transform 160ms ease"
      , width: 36
      , "@media (pointer: coarse)":
          { opacity: 1
          , transform: "none"
          }
      , "@media (max-width: 800px)":
          { opacity: 1
          , transform: "none"
          }
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 3
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , copyButtonVisible:
      { opacity: 1
      , transform: "none"
      }
  , tooltip:
      { backgroundColor: "var(--landing-color-violet)"
      , borderRadius: 999
      , color: "var(--landing-color-paper)"
      , fontSize: "var(--landing-type-meta)"
      , fontWeight: 600
      , opacity:
          { default: 1
          , "[data-entering]": 0
          , "[data-exiting]": 0
          }
      , padding: "6px 10px"
      , transform:
          { default: "none"
          , "[data-entering]": "translateY(4px) scale(0.92)"
          , "[data-exiting]": "translateY(2px) scale(0.96)"
          }
      , transformOrigin: "bottom center"
      , transition: "opacity 160ms ease, transform 180ms cubic-bezier(0.16, 1, 0.3, 1)"
      , "@media (prefers-reduced-motion: reduce)":
          { transitionDuration: "0ms"
          }
      }
  }

installationSection :: JSX
installationSection =
  DOM.section { className: (StyleX.props styles.section).className, id: "install" }
    [ DOM.div ContentShell.contentShell
        [ DOM.div (StyleX.props styles.content)
            [ element installationCommandsImpl
                { commandClassName: (StyleX.props styles.command).className
                , copyButtonClassName: (StyleX.props styles.copyButton).className
                , copyButtonVisibleClassName: (StyleX.props styles.copyButtonVisible).className
                , heading: DOM.h2 (StyleX.props styles.title) "Install"
                , headingRowClassName: (StyleX.props styles.headingRow).className
                , promptClassName: (StyleX.props styles.prompt).className
                , rootClassName: (StyleX.props styles.commands).className
                , tabClassName: (StyleX.props styles.tab).className
                , tabListClassName: (StyleX.props styles.tabList).className
                , terminalClassName: (StyleX.props styles.terminal).className
                , tooltipClassName: (StyleX.props styles.tooltip).className
                }
            ]
        ]
    ]
