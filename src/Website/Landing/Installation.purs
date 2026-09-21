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
      , width: "100%"
      }
  , content:
      { alignItems: "start"
      , display: "grid"
      , columnGap: "clamp(48px, 9vw, 132px)"
      , gridTemplateColumns:
          { default: "minmax(240px, 0.75fr) minmax(0, 1.25fr)"
          , "@media (max-width: 800px)": "minmax(0, 1fr)"
          }
      , paddingBlock: "40px 72px"
      , rowGap: 40
      , "@media (max-width: 800px)":
          { paddingBlock: "40px 64px"
          }
      }
  , introduction: { display: "grid", gap: 20 }
  , title:
      { fontFamily: "Anybody Variable, sans-serif"
      , fontSize: "clamp(1.7rem, 3vw, 2.75rem)"
      , fontStretch: "118%"
      , fontWeight: 650
      , letterSpacing: "-0.045em"
      , lineHeight: 1.08
      }
  , description:
      { color: "var(--landing-color-muted)"
      , fontSize: 15
      , lineHeight: 1.65
      , maxWidth: 420
      }
  , commands:
      { backgroundColor: "transparent"
      , borderColor: "oklch(from var(--landing-color-ink) l c h / 14%)"
      , borderStyle: "solid"
      , borderWidth: "1px 0"
      , display: "grid"
      , gap: 12
      , minWidth: 0
      , padding: "28px clamp(20px, 4vw, 36px)"
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
      , fontSize: 12
      , fontWeight: 600
      , gap: 7
      , height: 38
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
      , fontFamily: "JetBrains Mono Variable, monospace"
      , fontSize: 14
      , lineHeight: "20px"
      , minWidth: 0
      , overflowWrap: "anywhere"
      , overflowX: "auto"
      , padding: 0
      , whiteSpace: "pre-wrap"
      , width: "100%"
      , "@media (max-width: 800px)":
          { fontSize: 12
          , lineHeight: "18px"
          }
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
      , fontSize: 12
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
            [ DOM.div (StyleX.props styles.introduction)
                [ DOM.h2 (StyleX.props styles.title) "Install IRIS"
                , DOM.p (StyleX.props styles.description)
                    "Bring IRIS into a new project or use it with packages from the PureScript ecosystem."
                ]
            , element installationCommandsImpl
                { commandClassName: (StyleX.props styles.command).className
                , copyButtonClassName: (StyleX.props styles.copyButton).className
                , copyButtonVisibleClassName: (StyleX.props styles.copyButtonVisible).className
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
