module Website.Landing.Index (component) where

import Prelude

import Iris.StyleX as StyleX
import Data.Foldable (for_)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Website.Components.ContentShell as ContentShell
import Website.Components.Header as Header
import Website.Components.Icon as Icon
import Website.Landing.Demos as Demos
import Website.Landing.Features as Features
import Website.Landing.Installation as Installation
import React.Basic (ReactComponent, Ref, element)
import React.Basic.Hooks ((/\))
import React.Basic.Hooks as Hooks
import Web.DOM.Element as Element
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLHtmlElement as HTMLHtmlElement
import Web.HTML.Navigator as Navigator
import Web.HTML.Window as Window
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

foreign import observeAlphaDock ::
  { banner :: Ref (Nullable Element.Element)
  , header :: Ref (Nullable Element.Element)
  , onDock :: Boolean -> Effect Unit
  } ->
  Effect (Effect Unit)

styles = StyleX.create
  { page:
      { "--landing-header-height": "86px"
      , backgroundColor: "var(--landing-color-paper)"
      , fontFamily: "var(--landing-font-body)"
      , minHeight: "100vh"
      , "@media (max-width: 700px)": { "--landing-header-height": "68px" }
      }
  , firstScreen:
      { display: "flex"
      , flexDirection: "column"
      , minHeight: "calc(100svh - var(--landing-header-height))"
      }
  , hero:
      { alignItems: "flex-start"
      , backgroundImage:
          "linear-gradient(90deg, var(--landing-color-paper) 0%, var(--landing-color-paper) 18%, oklch(from var(--landing-color-paper) l c h / 86%) 34%, transparent 64%), var(--landing-hero-image)"
      , backgroundPosition: "center right"
      , backgroundRepeat: "no-repeat"
      , backgroundSize: "cover"
      , display: "flex"
      , flexDirection: "column"
      , flexGrow: 1
      , isolation: "isolate"
      , justifyContent: "center"
      , paddingBlock:
          { default: "64px 58px"
          , "@media (max-width: 800px)": "44px 64px"
          , "@media (max-width: 700px) and (max-height: 650px)": "16px"
          }
      , position: "relative"
      , "@media (max-width: 700px)":
          { backgroundImage:
              "linear-gradient(90deg, var(--landing-color-paper) 0%, var(--landing-color-paper) 22%, oklch(from var(--landing-color-paper) l c h / 92%) 54%, oklch(from var(--landing-color-paper) l c h / 24%) 100%), var(--landing-hero-image-mobile)"
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
      , fontSize: "var(--landing-type-statement)"
      , fontWeight: 520
      , letterSpacing: "-0.03em"
      , lineHeight: 1.1
      , marginBlockStart:
          { default: "clamp(44px, 6vw, 76px)"
          , "@media (max-width: 700px) and (max-height: 650px)": "16px"
          }
      , maxWidth: 700
      , textWrap: "balance"
      }
  , actions:
      { alignItems: "center"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: 12
      , marginBlockStart:
          { default: 32
          , "@media (max-width: 700px) and (max-height: 650px)": 12
          }
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
      , fontSize: "var(--landing-type-small)"
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
      , fontSize: "var(--landing-type-small)"
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
    bannerRef <- Hooks.useRef Nullable.null
    headerRef <- Hooks.useRef Nullable.null
    alphaDocked /\ setAlphaDocked <- Hooks.useState' false
    Hooks.useEffectOnce configurePlatformStyles
    Hooks.useEffectOnce $ observeAlphaDock
      { banner: bannerRef, header: headerRef, onDock: setAlphaDocked }
    pure $ DOM.div (StyleX.props styles.page)
      [ headerComponent { alphaDocked, headerRef }
      , DOM.main {}
          [ DOM.div (StyleX.props styles.firstScreen)
              [ Header.alphaBanner bannerRef
              , DOM.div (StyleX.props styles.hero)
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
              ]
          , Installation.installationSection
          , Features.featuresSection
          , element Demos.component {}
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
