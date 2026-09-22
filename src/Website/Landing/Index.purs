module Website.Landing.Index (component) where

import Prelude

import Iris.StyleX as StyleX
import Data.Foldable (for_)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Website.Components.ContentShell as ContentShell
import Website.Components.Header as Header
import Website.Components.Icon as Icon
import Website.Landing.Installation as Installation
import React.Basic (ReactComponent, element)
import React.Basic.Hooks as Hooks
import Web.DOM.Element as Element
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLHtmlElement as HTMLHtmlElement
import Web.HTML.Navigator as Navigator
import Web.HTML.Window as Window
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

styles = StyleX.create
  { page:
      { backgroundColor: "var(--landing-color-paper)"
      , fontFamily: "var(--landing-font-body)"
      , minHeight: "100vh"
      }
  , hero:
      { alignItems: "flex-start"
      , backgroundImage:
          "linear-gradient(90deg, var(--landing-color-paper) 0%, var(--landing-color-paper) 18%, oklch(from var(--landing-color-paper) l c h / 86%) 34%, transparent 64%), url('/iris-digital-field.webp')"
      , backgroundPosition: "center right"
      , backgroundRepeat: "no-repeat"
      , backgroundSize: "cover"
      , display: "flex"
      , flexDirection: "column"
      , isolation: "isolate"
      , justifyContent: "center"
      , minHeight: "100svh"
      , paddingBlock:
          { default: "150px 86px"
          , "@media (max-width: 800px)": "112px 64px"
          }
      , position: "relative"
      , "@media (max-width: 700px)":
          { backgroundImage:
              "linear-gradient(90deg, var(--landing-color-paper) 0%, var(--landing-color-paper) 22%, oklch(from var(--landing-color-paper) l c h / 92%) 54%, oklch(from var(--landing-color-paper) l c h / 24%) 100%), url('/iris-digital-field.webp')"
          , backgroundPosition: "52% center"
          , backgroundSize: "auto 100%"
          }
      }
  , heroContent:
      { alignItems: "flex-start"
      , display: "flex"
      , flexDirection: "column"
      , position: "relative"
      , maxWidth: 720
      , width: "100%"
      , zIndex: 1
      }
  , heroTitle:
      { color: "var(--landing-color-ink)"
      , fontFamily: "var(--landing-font-wordmark)"
      , fontSize: "var(--landing-hero-size, clamp(6rem, 18vw, 15rem))"
      , fontWeight: 400
      , letterSpacing: "var(--landing-wordmark-tracking, -0.06em)"
      , lineHeight: 0.72
      , marginBlockEnd: "var(--landing-hero-leading-offset, 0.28em)"
      , marginBlockStart: 0
      , overflow: "visible"
      , position: "relative"
      , width: "fit-content"
      }
  , heroTitleReflection:
      { "WebkitMaskImage": "linear-gradient(to top, black 0%, transparent 72%)"
      , color: "inherit"
      , filter: "blur(0.012em)"
      , insetBlockStart: "0.78em"
      , insetInlineStart: "-0.04em"
      , lineHeight: 0.72
      , maskImage: "linear-gradient(to top, black 0%, transparent 72%)"
      , opacity: 0.22
      , overflow: "visible"
      , paddingInline: "0.04em"
      , pointerEvents: "none"
      , position: "absolute"
      , transform: "scaleY(-1)"
      , transformOrigin: "center"
      , userSelect: "none"
      , whiteSpace: "nowrap"
      }
  , statement:
      { color: "var(--landing-color-ink)"
      , fontFamily: "var(--landing-font-heading)"
      , fontSize: "clamp(2rem, 3.4vw, 3.25rem)"
      , fontWeight: 520
      , letterSpacing: "-0.045em"
      , lineHeight: 1.02
      , marginBlockStart: "clamp(44px, 6vw, 76px)"
      , maxWidth: 700
      , textWrap: "balance"
      }
  , actions:
      { alignItems: "center"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: 12
      , marginBlockStart: 32
      }
  , primaryAction:
      { alignItems: "center"
      , backgroundColor:
          { default: "oklch(from var(--landing-color-ink) l c h / 4%)"
          , ":hover": "oklch(from var(--landing-color-ink) l c h / 10%)"
          }
      , borderRadius: 9999
      , color: "var(--landing-color-ink)"
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 14
      , fontWeight: 650
      , justifyContent: "center"
      , minHeight: 48
      , paddingInline: 24
      , textDecoration: "none"
      , transition: "background-color 160ms ease"
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 3
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , footer:
      { backgroundColor: "var(--landing-color-paper)"
      , borderTopColor: "var(--landing-color-line)"
      , borderTopStyle: "solid"
      , borderTopWidth: 1
      , display: "grid"
      , gap: 8
      , minHeight: 88
      , padding: "32px"
      , placeItems: "center"
      , textAlign: "center"
      , width: "100%"
      , "@media (max-width: 640px)": { minHeight: 72, padding: "24px 20px" }
      }
  , footerCopy:
      { color: "var(--landing-color-muted)"
      , fontSize: 14
      , lineHeight: 1.6
      , marginInline: "auto"
      , maxWidth: 760
      }
  , footerLink:
      { color: { default: "var(--landing-color-ink)", ":hover": "var(--landing-color-violet)" }
      , textDecorationLine: "underline"
      , textDecorationThickness: 1
      , textUnderlineOffset: 3
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 3
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , footerCopyrights:
      { alignItems: "center"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: "4px 20px"
      , justifyContent: "center"
      }
  , footerCopyrightItem: { alignItems: "center", display: "inline-flex", gap: 5 }
  , footerCopyrightIcon: { display: "inline-flex", fontSize: 14 }
  }

component :: ReactComponent {}
component = unsafePerformEffect do
  headerComponent <- Header.header
  Hooks.reactComponent "LandingPage" \_ -> Hooks.do
    Hooks.useEffectOnce configurePlatformStyles
    pure $ DOM.div (StyleX.props styles.page)
      [ headerComponent unit
      , DOM.main {}
          [ DOM.div (StyleX.props styles.hero)
              [ DOM.div ContentShell.contentShell
                  [ DOM.div (StyleX.props styles.heroContent)
                      [ DOM.h1
                          { className: (StyleX.props styles.heroTitle).className }
                          [ DOM.span {} "IRIS"
                          , DOM.span
                              { className: (StyleX.props styles.heroTitleReflection).className
                              , "aria-hidden": true
                              }
                              "IRIS"
                          ]
                      , DOM.p (StyleX.props styles.statement)
                          "Functional programming for the browser, the server, and everywhere in between."
                      , DOM.div (StyleX.props styles.actions)
                          [ DOM.a
                              { className: (StyleX.props styles.primaryAction).className
                              , href: "#install"
                              }
                              "Install IRIS"
                          ]
                      ]
                  ]
              ]
          , Installation.installationSection
          ]
      , DOM.footer (StyleX.props styles.footer)
          [ DOM.p (StyleX.props [ styles.footerCopy, styles.footerCopyrights ])
              [ DOM.span (StyleX.props styles.footerCopyrightItem)
                  [ DOM.span
                      { className: (StyleX.props styles.footerCopyrightIcon).className
                      , role: "img"
                      , "aria-label": "Copyright"
                      }
                      (element Icon.copyright { "aria-hidden": true, focusable: false })
                  , DOM.a
                      { className: (StyleX.props styles.footerLink).className
                      , href: "https://github.com/purescript/purescript/blob/master/LICENSE"
                      , target: targetBlank
                      , rel: "noopener noreferrer"
                      }
                      "PureScript"
                  , DOM.span {} " 2017–2025"
                  ]
              , DOM.span (StyleX.props styles.footerCopyrightItem)
                  [ DOM.span
                      { className: (StyleX.props styles.footerCopyrightIcon).className
                      , role: "img"
                      , "aria-label": "Copyright"
                      }
                      (element Icon.copyright { "aria-hidden": true, focusable: false })
                  , DOM.a
                      { className: (StyleX.props styles.footerLink).className
                      , href:
                          "https://github.com/purefunctor/purescript-iris/blob/main/LICENSE"
                      , target: targetBlank
                      , rel: "noopener noreferrer"
                      }
                      "IRIS"
                  , DOM.span {} " by purefunctor, 2023–2026"
                  ]
              ]
          ]
      ]

configurePlatformStyles :: Effect (Effect Unit)
configurePlatformStyles = do
  browserWindow <- window
  platform <- Window.navigator browserWindow >>= Navigator.platform
  when (isMacOS platform) do
    document <- Window.document browserWindow
    documentElement <- HTMLDocument.documentElement document
    for_ documentElement \html ->
      Element.setAttribute "data-landing-macos" "" (HTMLHtmlElement.toElement html)
  pure (pure unit)

isMacOS :: String -> Boolean
isMacOS = case _ of
  "MacIntel" -> true
  "MacPPC" -> true
  "Mac68K" -> true
  "macOS" -> true
  _ -> false
