module Website.Components.Header (header, alphaBanner, playgroundHeader) where

import Prelude

import Iris.StyleX as StyleX
import Data.Nullable (Nullable)
import Website.Components.Header.Mobile as Mobile
import Website.Components.Header.Styles (controlStyles)
import Website.Components.Icon as Icon
import React.Basic (JSX, ReactComponent, Ref, element)
import React.Basic.Hooks (Component)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank, targetSelf)

styles = StyleX.create
  { headerBackground:
      { "--landing-header-color": "var(--landing-color-paper)"
      , backgroundColor: "var(--landing-color-purescript-charcoal)"
      , flexShrink: 0
      , width: "100%"
      }
  , landingHeaderBackground:
      { "--landing-header-color": "var(--landing-color-ink)"
      , "--landing-header-focus": "var(--landing-color-crystal)"
      , backgroundColor: "transparent"
      , height: "var(--landing-header-height)"
      , insetBlockStart: 0
      , position: "sticky"
      , width: "100%"
      , zIndex: 15
      , "::before":
          { backgroundColor:
              { default: "oklch(from var(--landing-color-paper) l c h / 80%)"
              , "@media (max-width: 700px)": "oklch(from var(--landing-color-paper) l c h / 85%)"
              , "@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px)))":
                  "oklch(from var(--landing-color-paper) l c h / 94%)"
              , "@media (prefers-reduced-transparency: reduce)": "var(--landing-color-paper)"
              , "@media (prefers-contrast: more)": "var(--landing-color-paper)"
              }
          , backgroundImage:
              { default: "linear-gradient(to bottom, oklch(100% 0 0 / 50%), transparent 60%)"
              , "@media (prefers-reduced-transparency: reduce)": "none"
              , "@media (prefers-contrast: more)": "none"
              }
          , backdropFilter:
              { default: "blur(24px) saturate(1.35)"
              , "@media (max-width: 700px)": "blur(20px) saturate(1.3)"
              , "@media (prefers-reduced-transparency: reduce)": "none"
              , "@media (prefers-contrast: more)": "none"
              }
          , "WebkitBackdropFilter":
              { default: "blur(24px) saturate(1.35)"
              , "@media (max-width: 700px)": "blur(20px) saturate(1.3)"
              , "@media (prefers-reduced-transparency: reduce)": "none"
              , "@media (prefers-contrast: more)": "none"
              }
          , content: "''"
          , inset: 0
          , pointerEvents: "none"
          , position: "absolute"
          , zIndex: -1
          }
      , "::after":
          { boxShadow:
              "inset 0 -1px 0 oklch(100% 0 0 / 75%), 0 1px 0 oklch(from var(--landing-color-ink) l c h / 9%), 0 16px 32px -26px oklch(from var(--landing-color-ink) l c h / 55%)"
          , content: "''"
          , inset: 0
          , opacity: 0
          , pointerEvents: "none"
          , position: "absolute"
          , transition: "opacity 220ms cubic-bezier(0.16, 1, 0.3, 1)"
          , zIndex: -1
          , "@media (prefers-reduced-motion: reduce)": { transitionDuration: "0ms" }
          }
      }
  , landingHeaderDocked:
      { "::after": { opacity: 1 }
      }
  , headerContent:
      { alignItems: "center"
      , display: "grid"
      , gap: 24
      , gridTemplateColumns: "minmax(0, 1fr) auto"
      , marginInline: "auto"
      , maxWidth: 1280
      , minHeight: 86
      , paddingBlock: 20
      , paddingInline: 40
      , width: "100%"
      , "@media (max-width: 700px)": { gap: 12, minHeight: 68, paddingBlock: 12, paddingInline: 20 }
      }
  , alphaBanner:
      { backgroundColor: "var(--landing-color-ink)"
      , backgroundImage:
          "linear-gradient(90deg, var(--landing-color-ink) 48%, oklch(from var(--landing-color-ink) l c h / 94%) 76%, oklch(from var(--landing-color-ink) l c h / 70%) 100%), var(--landing-alpha-image)"
      , backgroundPosition: "center, right center"
      , backgroundRepeat: "no-repeat"
      , backgroundSize: "cover, 820px auto"
      , color: "var(--landing-color-paper)"
      , width: "100%"
      , "@media (max-width: 700px)":
          { backgroundImage:
              "linear-gradient(90deg, var(--landing-color-ink) 45%, oklch(from var(--landing-color-ink) l c h / 88%) 100%), var(--landing-alpha-image)"
          , backgroundSize: "cover, 360px auto"
          }
      }
  , alphaBannerContent:
      { alignItems: "stretch"
      , display: "flex"
      , marginInline: "auto"
      , maxWidth: 1280
      , minHeight: 72
      , width: "100%"
      , "@media (max-width: 700px)": { minHeight: 84 }
      }
  , alphaBannerMark:
      { alignItems: "center"
      , backgroundColor: "var(--landing-color-violet)"
      , clipPath: "polygon(0 0, 100% 0, calc(100% - 28px) 100%, 0 100%)"
      , display: "flex"
      , flexShrink: 0
      , fontFamily: "var(--landing-font-wordmark)"
      , fontSize: 29
      , letterSpacing: "-0.06em"
      , paddingInline: "40px 55px"
      , "@media (max-width: 700px)":
          { clipPath: "polygon(0 0, 100% 0, calc(100% - 14px) 100%, 0 100%)"
          , fontSize: 17
          , paddingInline: "20px 27px"
          }
      }
  , alphaBannerMessage:
      { alignSelf: "center"
      , fontSize: 15
      , lineHeight: 1.4
      , maxWidth: 740
      , padding: "14px 40px 14px 10px"
      , "@media (max-width: 700px)":
          { fontSize: 13
          , lineHeight: 1.35
          , padding: "12px 16px 12px 8px"
          }
      }
  , headerBrand:
      { alignItems: "center"
      , color: "var(--landing-header-color)"
      , cursor: "default"
      , display: "flex"
      , position: "relative"
      , textDecoration: "none"
      , zIndex: 30
      , ":focus-visible":
          { outline: "2px solid var(--landing-header-focus, var(--landing-color-signal))"
          , outlineOffset: 4
          }
      }
  , brandGroup: { alignItems: "center", display: "flex", gap: 10, minWidth: 0 }
  , alphaDockTag:
      { alignItems: "center"
      , backgroundColor: "var(--landing-color-violet)"
      , backgroundImage: "linear-gradient(to bottom, oklch(100% 0 0 / 16%), transparent 55%)"
      , clipPath: "polygon(0 0, 100% 0, calc(100% - 8px) 100%, 0 100%)"
      , color: "var(--landing-color-paper)"
      , display: "inline-flex"
      , fontFamily: "var(--landing-font-wordmark)"
      , fontSize: 13
      , height: 22
      , letterSpacing: "-0.06em"
      , opacity: 0
      , paddingInline: "8px 14px"
      , pointerEvents: "none"
      , transform: "translateY(8px)"
      , transition: "opacity 140ms ease-out, transform 140ms ease-out, visibility 0s 140ms"
      , visibility: "hidden"
      , "@media (max-width: 700px)": { fontSize: 11, height: 20 }
      , "@media (prefers-reduced-motion: reduce)":
          { transform: "none", transitionDuration: "0ms" }
      }
  , alphaDockTagVisible:
      { opacity: 1
      , transform: "none"
      , transition:
          "opacity 220ms cubic-bezier(0.16, 1, 0.3, 1), transform 220ms cubic-bezier(0.16, 1, 0.3, 1), visibility 0s"
      , visibility: "visible"
      , "@media (prefers-reduced-motion: reduce)": { transitionDuration: "0ms" }
      }
  , headerBrandCopy: { display: "flex" }
  , headerBrandName:
      { fontFamily: "var(--landing-font-wordmark)"
      , fontSize: 26
      , fontWeight: 400
      , letterSpacing: "-0.045em"
      , lineHeight: 0.9
      }
  , desktopNavigation:
      { alignItems: "center"
      , display: "flex"
      , gap: 12
      , justifyContent: "flex-end"
      , "@media (max-width: 700px)": { display: "none" }
      }
  , desktopSocialLink:
      { alignItems: "center"
      , backgroundColor:
          { default: "transparent"
          , ":hover": "oklch(from var(--landing-header-color) l c h / 8%)"
          }
      , borderRadius: 9999
      , color: "var(--landing-header-color)"
      , cursor: "default"
      , display: "inline-flex"
      , height: 38
      , justifyContent: "center"
      , marginInlineStart: 0
      , textDecoration: "none"
      , width: 38
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 2
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , desktopTryLink:
      { alignItems: "center"
      , backgroundColor:
          { default: "var(--landing-color-violet)"
          , ":hover": "oklch(from var(--landing-color-violet) calc(l + 0.07) c h)"
          }
      , color: "var(--landing-color-paper)"
      , borderRadius: 9999
      , cursor: "default"
      , display: "inline-flex"
      , justifyContent: "center"
      , marginInlineStart: 18
      , textDecoration: "none"
      , whiteSpace: "nowrap"
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 2
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , desktopDocumentationLink:
      { alignItems: "center"
      , backgroundColor:
          { default: "var(--landing-color-signal)", ":hover": "var(--landing-color-signal-bright)" }
      , color: "var(--landing-color-ink)"
      , cursor: "default"
      , display: "inline-flex"
      , justifyContent: "center"
      , marginInlineStart: 0
      , textDecoration: "none"
      , whiteSpace: "nowrap"
      , ":focus-visible":
          { outlineColor: "var(--landing-color-crystal)"
          , outlineOffset: 2
          , outlineStyle: "solid"
          , outlineWidth: 2
          }
      }
  , headerLinkIcon:
      { alignItems: "center", display: "inline-flex", flexShrink: 0, fontSize: 15, opacity: 0.82 }
  , headerLinkContent: { alignItems: "center", display: "inline-flex", gap: 8 }
  , visuallyHidden:
      { clipPath: "inset(50%)"
      , height: 1
      , overflow: "hidden"
      , position: "absolute"
      , whiteSpace: "nowrap"
      , width: 1
      }
  , playgroundActions:
      { display: "flex"
      , alignItems: "center"
      , justifyContent: "flex-end"
      , flexWrap: "wrap"
      , gap: 8
      , "@media (max-width: 700px)": { maxWidth: 140 }
      , "@media (max-width: 380px)": { maxWidth: 100 }
      }
  , backLink:
      { marginInlineStart: 0
      }
  , backLinkSuffix: { "@media (max-width: 380px)": { display: "none" } }
  }

styleProps = StyleX.recordProps styles

data NavigationDestination = GitHub | Bluesky | X | Documentation
data NavigationLayout = DesktopNavigation | MobileNavigation

header :: Component { alphaDocked :: Boolean, headerRef :: Ref (Nullable Element) }
header = Hooks.component "Header" \props -> Hooks.do
  pure $ landingHeaderFrame props.headerRef props.alphaDocked
    [ navigation styleProps.desktopNavigation DesktopNavigation
    , Mobile.navigationDrawer
        (element Icon.menu { "aria-hidden": true, focusable: false })
        (element Icon.x { "aria-hidden": true, focusable: false })
        (navigation Mobile.navigationStyle MobileNavigation)
    ]

playgroundHeader :: JSX -> JSX
playgroundHeader controls = headerFrame
  [ DOM.div (StyleX.props styles.playgroundActions)
      [ controls
      , DOM.nav { "aria-label": "Website navigation" }
          [ DOM.a
              { href: "/"
              , "aria-label": "Back to website"
              , className:
                  (StyleX.props [ controlStyles.control, styles.desktopTryLink, styles.backLink ]).className
              }
              ( DOM.span {}
                  [ DOM.text "Back"
                  , DOM.span (StyleX.props styles.backLinkSuffix) " to website"
                  ]
              )
          ]
      ]
  ]

headerFrame :: Array JSX -> JSX
headerFrame children = DOM.header styleProps.headerBackground
  [ DOM.div styleProps.headerContent ([ brand ] <> children) ]

landingHeaderFrame :: Ref (Nullable Element) -> Boolean -> Array JSX -> JSX
landingHeaderFrame headerRef alphaDocked children =
  DOM.header
    { className:
        ( StyleX.props
            [ styles.landingHeaderBackground
            , StyleX.conditional alphaDocked styles.landingHeaderDocked
            ]
        ).className
    , ref: DOM.reactRef headerRef
    }
    [ DOM.div styleProps.headerContent
        ( [ DOM.div styleProps.brandGroup
              [ brand
              , DOM.span
                  { className:
                      ( StyleX.props
                          [ styles.alphaDockTag
                          , StyleX.conditional alphaDocked styles.alphaDockTagVisible
                          ]
                      ).className
                  , "aria-hidden": true
                  }
                  "ALPHA"
              ]
          ] <> children
        )
    ]

alphaBanner :: Ref (Nullable Element) -> JSX
alphaBanner bannerRef = DOM.div
  { className: styleProps.alphaBanner.className, ref: DOM.reactRef bannerRef }
  [ DOM.div styleProps.alphaBannerContent
      [ DOM.span styleProps.alphaBannerMark "ALPHA"
      , DOM.p styleProps.alphaBannerMessage
          "IRIS is alpha software. Documentation is sparse and behaviour will change."
      ]
  ]

brand :: JSX
brand =
  DOM.a
    { className: styleProps.headerBrand.className
    , href: "/"
    , target: targetSelf
    , "aria-label": "IRIS home"
    }
    [ DOM.span styleProps.headerBrandCopy
        [ DOM.span styleProps.headerBrandName "IRIS" ]
    ]

navigation :: StyleX.Props -> NavigationLayout -> JSX
navigation style layout =
  DOM.nav
    { className: style.className
    , id: navigationId layout
    , "aria-label": navigationLabel layout
    }
    if isDesktopNavigation layout then
      [ navigationLink layout GitHub
      , navigationLink layout Bluesky
      , navigationLink layout X
      , navigationLink layout Documentation
      ]
    else
      [ navigationLink layout Documentation
      , navigationLink layout GitHub
      , navigationLink layout Bluesky
      , navigationLink layout X
      ]

navigationLink :: NavigationLayout -> NavigationDestination -> JSX
navigationLink layout destination =
  let
    destinationName' = destinationName destination
    mobile = isMobileNavigation layout
    linkStyle =
      if mobile then Mobile.linkStyle destinationName'
      else desktopLinkStyle destination
    contentStyle =
      if mobile then Mobile.linkContentStyle
      else styleProps.headerLinkContent
    label = destinationLabel destination
    destinationText =
      if mobile || not (isSocialDestination destination) then DOM.span {} label
      else DOM.span styleProps.visuallyHidden label
    destinationIconStyle =
      if not mobile then styleProps.headerLinkIcon
      else if isSocialDestination destination then
        Mobile.brandIconStyle
      else Mobile.navigationIconStyle
    externalIcon =
      if mobile then
        [ DOM.span Mobile.externalLinkIconStyle
            (element Icon.externalLink { "aria-hidden": true, focusable: false })
        ]
      else []
    linkChildren =
      [ DOM.span contentStyle
          [ destinationText
          , DOM.span destinationIconStyle
              (element (destinationIcon destination) { "aria-hidden": true, focusable: false })
          ]
      ] <> externalIcon
  in
    DOM.a
      { className: linkStyle.className
      , href: destinationHref destination
      , hidden: isTemporarilyHiddenDestination destination
      , target: targetBlank
      , rel: "noopener noreferrer"
      }
      linkChildren

navigationId :: NavigationLayout -> String
navigationId = case _ of
  DesktopNavigation -> "primary-navigation-desktop"
  MobileNavigation -> "primary-navigation-mobile"

navigationLabel :: NavigationLayout -> String
navigationLabel = case _ of
  DesktopNavigation -> "Primary navigation"
  MobileNavigation -> "Mobile navigation"

isDesktopNavigation :: NavigationLayout -> Boolean
isDesktopNavigation = case _ of
  DesktopNavigation -> true
  _ -> false

isMobileNavigation :: NavigationLayout -> Boolean
isMobileNavigation = case _ of
  MobileNavigation -> true
  _ -> false

desktopLinkStyle :: NavigationDestination -> StyleX.Props
desktopLinkStyle = case _ of
  GitHub -> StyleX.props styles.desktopSocialLink
  Bluesky -> StyleX.props styles.desktopSocialLink
  X -> StyleX.props styles.desktopSocialLink
  Documentation -> StyleX.props [ controlStyles.control, styles.desktopDocumentationLink ]

isSocialDestination :: NavigationDestination -> Boolean
isSocialDestination = case _ of
  GitHub -> true
  Bluesky -> true
  X -> true
  _ -> false

isTemporarilyHiddenDestination :: NavigationDestination -> Boolean
isTemporarilyHiddenDestination = case _ of
  Documentation -> true
  _ -> false

destinationName :: NavigationDestination -> String
destinationName = case _ of
  GitHub -> "github"
  Bluesky -> "bluesky"
  X -> "x"
  Documentation -> "documentation"

destinationHref :: NavigationDestination -> String
destinationHref = case _ of
  GitHub -> "https://github.com/purefunctor/purescript-iris"
  Bluesky -> "https://bsky.app/profile/purefunctor.me"
  X -> "https://x.com/purefunctor"
  Documentation -> "/docs"

destinationLabel :: NavigationDestination -> String
destinationLabel = case _ of
  GitHub -> "GitHub"
  Bluesky -> "Bluesky"
  X -> "X"
  Documentation -> "Documentation"

destinationIcon :: NavigationDestination -> ReactComponent Icon.IconProps
destinationIcon = case _ of
  GitHub -> Icon.gitHub
  Bluesky -> Icon.bluesky
  X -> Icon.xSocial
  Documentation -> Icon.bookOpen
