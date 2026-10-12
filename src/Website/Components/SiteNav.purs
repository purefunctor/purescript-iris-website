module Website.Components.SiteNav (headerLink, siteHeader, siteNav) where

import Prelude

import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (EventHandler, handler_)
import Website.Breakpoints (breakpoints)
import Website.Components.ExternalLink as ExternalLink
import Website.Components.Icon as Icon
import Website.Components.Logo (logo)
import Website.Components.NavigationLink as NavigationLink
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

foreign import scrollToTop :: EventHandler

foreign import mobileNavigationImpl ::
  ReactComponent
    { className :: String
    , buttonClassName :: String
    , panelClassName :: String
    , openIcon :: JSX
    , closeIcon :: JSX
    , content :: Array JSX
    }

styles =
  StyleX.create
    { header:
        { "WebkitBackdropFilter": "blur(30px) saturate(1.2)"
        , backdropFilter: "blur(30px) saturate(1.2)"
        , backgroundColor:
            { default: "var(--glass-fill-strong)"
            , "@media (prefers-reduced-transparency: reduce)": "var(--loam-900)"
            }
        , borderBlockEndColor: "var(--border-subtle)"
        , borderBlockEndStyle: "solid"
        , borderBlockEndWidth: 1
        , height: "var(--nav-height)"
        , insetBlockStart: 0
        , position: "sticky"
        , zIndex: 20
        }
    , containedHeader:
        { backgroundColor: "var(--loam-900)"
        , backdropFilter: "none"
        , "WebkitBackdropFilter": "none"
        }
    , content:
        { alignItems: "center"
        , display: "flex"
        , gap:
            StyleX.conditionalValue
              "0px"
              [ StyleX.conditionalCase breakpoints.upTo960 "clamp(12px, 2.4vw, 28px)" ]
        , height: "100%"
        , minWidth: 0
        , paddingInline: "var(--gutter)"
        }
    , containedContent:
        { gap: 0, marginInline: "auto", maxWidth: "var(--container-wide)", paddingInline: 0 }
    -- Where the documentation shows its rail, the brand spans the rail's width and navigation
    -- starts at the rail's edge.
    , brandCell:
        { display: "flex"
        , flexShrink: 0
        , width:
            StyleX.conditionalValue
              "calc(var(--rail-width) - var(--gutter))"
              [ StyleX.conditionalCase breakpoints.upTo960 "auto" ]
        }
    , containedBrandCell: { width: "auto", alignSelf: "stretch" }
    , containedBrand:
        { paddingInlineStart: "var(--gutter)"
        , paddingInlineEnd:
            StyleX.conditionalValue 36 [ StyleX.conditionalCase breakpoints.upTo800 16 ]
        , width: "auto"
        }
    , brand:
        { alignItems: "center"
        , color: "var(--text-primary)"
        , cursor: "default"
        , display: "inline-flex"
        , gap: 7
        , lineHeight: 1
        , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , textDecoration: "none"
        }
    , logo: { flexShrink: 0, height: 26, width: 26 }
    , wordmark: { fontSize: 21, fontWeight: 900, letterSpacing: "-0.04em" }
    , links:
        { display:
            StyleX.conditionalValue "flex" [ StyleX.conditionalCase breakpoints.upTo800 "none" ]
        , alignSelf: "stretch"
        , flexGrow: 1
        , minWidth: 0
        }
    -- Header links are flat tabs that fill the header's height.
    , link:
        { position: "relative"
        , isolation: "isolate"
        , alignSelf: "stretch"
        , alignItems: "center"
        , display: "flex"
        , flexShrink: 0
        , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
        , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
        , cursor: "default"
        , fontSize: 14
        , fontWeight: 500
        , outlineColor: "var(--focus-ring)"
        , outlineOffset: -2
        , paddingInline: 16
        , textDecoration: "none"
        , transitionDuration: "140ms"
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
        , whiteSpace: "nowrap"
        }
    , current:
        { backgroundColor: { default: "var(--accent-soft)", ":hover": "var(--surface-2)" }
        , color: "var(--iris-200)"
        }
    -- Share interaction states; size related controls together rather than every item alike.
    , landingItem:
        { alignSelf: "stretch"
        , backgroundColor:
            { default: "transparent"
            , ":hover": "var(--surface-2)"
            , ":active": "var(--accent-soft)"
            }
        , borderRadius: 0
        , boxShadow: "none"
        , color:
            { default: "var(--text-secondary)"
            , ":hover": "var(--text-primary)"
            , ":active": "var(--iris-200)"
            }
        , outlineColor: "var(--focus-ring)"
        , outlineOffset: -2
        , outlineStyle: { default: "none", ":focus-visible": "solid" }
        , outlineWidth: 2
        , justifyContent: "center"
        , paddingInline: 16
        , width: 144
        , transitionDuration:
            { default: "120ms", ":active": "0ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
        }
    , sectionLink: { width: 112, paddingInline: 12 }
    , socialLink: { width: 44, paddingInline: 0 }
    , actions:
        { alignItems: "center"
        , alignSelf: "stretch"
        , display: "flex"
        , flexShrink: 0
        , marginInlineStart: "auto"
        }
    , mobileNavigation:
        { display:
            StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo800 "flex" ]
        , alignSelf: "stretch"
        }
    , menuButton: { width: 64, paddingInline: 0, fontSize: 20 }
    , menuPanel:
        { backgroundColor: "var(--loam-900)"
        , insetBlockStart: "100%"
        , insetInline: 0
        , maxHeight: "calc(100dvh - var(--nav-height))"
        , overflowY: "auto"
        , padding: 12
        , position: "absolute"
        }
    , menuItem: { width: "100%", height: 48, paddingInline: 12, fontSize: 16 }
    , menuLabel: { textAlign: "start" }
    , menuFooter: { display: "flex", height: 48, marginBlockStart: 8 }
    , icon: { display: "inline-flex", width: 17 }
    , label: { textAlign: "center", width: "100%" }
    , documentation: { marginInlineStart: "auto" }
    , desktopInstall:
        { display:
            StyleX.conditionalValue "flex" [ StyleX.conditionalCase breakpoints.upTo800 "none" ]
        }
    , install:
        { backgroundColor:
            { default: "var(--accent)"
            , ":hover": "var(--accent-hover)"
            , ":active": "var(--accent-press)"
            }
        , color: "var(--text-on-accent)"
        , cursor: "var(--landing-interactive-cursor, pointer)"
        }
    }

styleProps = StyleX.recordProps styles

-- | Shared site chrome, with a contained landing layout or a viewport-wide rail layout.
siteHeader :: { contained :: Boolean } -> Array JSX -> JSX
siteHeader { contained } navigation =
  DOM.header
    (StyleX.props [ styles.header, StyleX.conditional contained styles.containedHeader ])
    [ DOM.div
        (StyleX.props [ styles.content, StyleX.conditional contained styles.containedContent ])
        ( [ DOM.div
              ( StyleX.props
                  [ styles.brandCell, StyleX.conditional contained styles.containedBrandCell ]
              )
              [ DOM.a
                  { className:
                      ( StyleX.props
                          [ styles.brand
                          , StyleX.conditional contained styles.landingItem
                          , StyleX.conditional contained styles.containedBrand
                          ]
                      ).className
                  , href: "/"
                  , onClick: scrollToTop
                  , "aria-label": "Iris home"
                  }
                  [ logo { className: styleProps.logo.className }
                  , DOM.span styleProps.wordmark "IRIS"
                  ]
              ]
          ]
            <> navigation
        )
    ]

-- | `onInstall` runs when the Install action is pressed.
siteNav :: { onInstall :: Effect Unit } -> JSX
siteNav { onInstall } =
  siteHeader
    { contained: true }
    [ DOM.nav
        { className: styleProps.links.className, "aria-label": "Explore Iris" }
        [ link false "/#benchmarks" "Benchmarks"
        , link false "/#editor" "Editor"
        , socialLink "https://github.com/purefunctor/purescript-iris" "Iris on GitHub" Icon.gitHub
        , socialLink "https://x.com/purefunctor" "purefunctor on X" Icon.xSocial
        , socialLink "https://bsky.app/profile/purefunctor.me" "purefunctor on Bluesky" Icon.bluesky
        , documentationLink
        ]
    , DOM.div
        styleProps.actions
        [ element
            mobileNavigationImpl
            { className: styleProps.mobileNavigation.className
            , buttonClassName:
                (StyleX.props [ styles.link, styles.landingItem, styles.menuButton ]).className
            , panelClassName: styleProps.menuPanel.className
            , openIcon: element Icon.menu { "aria-hidden": true, focusable: false }
            , closeIcon: element Icon.x { "aria-hidden": true, focusable: false }
            , content:
                [ link true "/#benchmarks" "Benchmarks"
                , link true "/#editor" "Editor"
                , link true "/docs/getting-started/" "Documentation"
                , installButton true
                , DOM.div
                    styleProps.menuFooter
                    [ socialLink
                        "https://github.com/purefunctor/purescript-iris"
                        "Iris on GitHub"
                        Icon.gitHub
                    , socialLink "https://x.com/purefunctor" "purefunctor on X" Icon.xSocial
                    , socialLink
                        "https://bsky.app/profile/purefunctor.me"
                        "purefunctor on Bluesky"
                        Icon.bluesky
                    ]
                ]
            }
        , installButton false
        ]
    ]
  where
  installButton mobile =
    DOM.button
      { className:
          ( StyleX.props
              [ styles.link
              , styles.landingItem
              , styles.install
              , if mobile then styles.menuItem else styles.desktopInstall
              ]
          ).className
      , onClick: handler_ onInstall
      , type: "button"
      }
      "Install"
  link mobile href label =
    NavigationLink.navigationLink
      { href
      , className:
          ( StyleX.props
              [ styles.link
              , styles.landingItem
              , styles.sectionLink
              , StyleX.conditional mobile styles.menuItem
              ]
          ).className
      , current: false
      , content:
          DOM.span (StyleX.props [ styles.label, StyleX.conditional mobile styles.menuLabel ]) label
      }
  socialLink href label icon =
    DOM.a
      { className: (StyleX.props [ styles.link, styles.landingItem, styles.socialLink ]).className
      , href
      , rel: "noopener noreferrer"
      , target: targetBlank
      , "aria-label": label <> ExternalLink.newTabLabel
      }
      (DOM.span styleProps.icon (element icon { "aria-hidden": true, focusable: false }))
  documentationLink =
    NavigationLink.navigationLink
      { href: "/docs/getting-started/"
      , className:
          (StyleX.props [ styles.link, styles.landingItem, styles.documentation ]).className
      , current: false
      , content: DOM.span styleProps.label "Documentation"
      }

-- | A link in a site header's navigation, marked when it leads to the current page.
headerLink :: { href :: String, label :: String, current :: Boolean } -> JSX
headerLink { href, label, current } =
  NavigationLink.navigationLink
    { href
    , className: (StyleX.props [ styles.link, StyleX.conditional current styles.current ]).className
    , current
    , content: DOM.text label
    }
