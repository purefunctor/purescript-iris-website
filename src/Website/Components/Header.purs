module Website.Components.Header (header, playgroundHeader) where

import Prelude

import Iris.StyleX as StyleX
import Website.Components.Header.Mobile as Mobile
import Website.Components.Header.Styles (controlStyles)
import Website.Components.Icon as Icon
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (Component)
import React.Basic.Hooks as Hooks
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
      , backgroundColor: "transparent"
      , insetBlockStart: 0
      , insetInline: 0
      , position: "absolute"
      , width: "100%"
      , zIndex: 10
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
  , headerBrand:
      { alignItems: "center"
      , color: "var(--landing-header-color)"
      , cursor: "default"
      , display: "flex"
      , position: "relative"
      , textDecoration: "none"
      , zIndex: 30
      , ":focus-visible": { outline: "2px solid var(--landing-color-signal)", outlineOffset: 4 }
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
      { alignItems: "center", display: "inline-flex", flexShrink: 0, fontSize: 15, opacity: 0.72 }
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

header :: Component Unit
header = Hooks.component "Header" \_ -> Hooks.do
  pure $ landingHeaderFrame
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

landingHeaderFrame :: Array JSX -> JSX
landingHeaderFrame children = DOM.header styleProps.landingHeaderBackground
  [ DOM.div styleProps.headerContent ([ brand ] <> children) ]

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
