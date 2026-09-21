module Website.Landing.Index (component) where

import Prelude

import Iris.StyleX as StyleX
import Data.Foldable (for_)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Website.Components.ContentShell as ContentShell
import Website.Components.Header as Header
import Website.Components.Icon as Icon
import Website.Landing.Features as Features
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
      , fontFamily: "InterVariable, sans-serif"
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
      , fontFamily: "Anybody Variable, sans-serif"
      , fontSize: "clamp(5rem, 12vw, 11rem)"
      , fontStretch: "138%"
      , fontWeight: 680
      , letterSpacing: "-0.065em"
      , lineHeight: 0.78
      , marginBlock: 0
      }
  , statement:
      { color: "var(--landing-color-ink)"
      , fontSize: "clamp(2rem, 3.8vw, 3.6rem)"
      , fontWeight: 540
      , letterSpacing: "-0.045em"
      , lineHeight: 1.02
      , marginBlockStart: "clamp(44px, 6vw, 76px)"
      , maxWidth: 700
      , textWrap: "balance"
      }
  , lead:
      { color: "oklch(from var(--landing-color-muted) calc(l - 0.07) c h)"
      , fontSize: "clamp(1rem, 1.8vw, 1.18rem)"
      , lineHeight: 1.6
      , marginBlockStart: 24
      , maxWidth: 570
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
          { default: "var(--landing-color-violet)"
          , ":hover": "oklch(from var(--landing-color-violet) calc(l - 0.07) c h)"
          }
      , borderRadius: 9999
      , color: "var(--landing-color-paper)"
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
  , secondaryAction:
      { alignItems: "center"
      , backgroundColor: "transparent"
      , color: { default: "var(--landing-color-ink)", ":hover": "var(--landing-color-violet)" }
      , cursor: "pointer"
      , display: "inline-flex"
      , fontSize: 14
      , fontWeight: 600
      , justifyContent: "center"
      , minHeight: 48
      , paddingInline: 8
      , textDecorationLine: "underline"
      , textDecorationThickness: 1
      , textUnderlineOffset: 5
      , transition: "color 160ms ease"
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
                      [ DOM.h1 (StyleX.props styles.heroTitle) "IRIS"
                      , DOM.p (StyleX.props styles.statement)
                          "A modern functional programming language with effect tracking."
                      , DOM.p (StyleX.props styles.lead)
                          "IRIS uses the PureScript package ecosystem and compiles to readable JavaScript. Its effect types show what a program can do before it runs."
                      , DOM.div (StyleX.props styles.actions)
                          [ DOM.a
                              { className: (StyleX.props styles.primaryAction).className
                              , href: "/playground"
                              }
                              "Open playground"
                          , DOM.a
                              { className: (StyleX.props styles.secondaryAction).className
                              , href: "#install"
                              }
                              "Install IRIS"
                          ]
                      ]
                  ]
              ]
          , Installation.installationSection
          , DOM.div ContentShell.contentShell [ Features.featuresSection ]
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
