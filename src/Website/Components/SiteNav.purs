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

foreign import spectrumInstallButtonImpl ::
  ReactComponent
    { className :: String
    , pressedClassName :: String
    , label :: String
    , onPress :: Effect Unit
    , content :: Array JSX
    }

-- Staggered bars carry a wave across the button. Each bar sinks by moving rather than by clipping,
-- so the wave adds to the fill's own transitions instead of interrupting them, and its label copy
-- moves the opposite way to stay aligned with the label beneath.
installWave = StyleX.keyframes { "40%": { transform: "translateY(20%)" } }
installLabelWave = StyleX.keyframes { "40%": { transform: "translateY(-20%)" } }

styles =
  StyleX.create
    { header:
        { "WebkitBackdropFilter": "blur(30px) saturate(1.2)"
        , backdropFilter: "blur(30px) saturate(1.2)"
        , backgroundColor:
            { default: "var(--glass-fill-strong)"
            , "@media (prefers-reduced-transparency: reduce)": "var(--granite-900)"
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
        { backgroundColor: "var(--granite-900)"
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
        , color: "var(--signal-200)"
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
            , ":active": "var(--signal-200)"
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
        { backgroundColor: "var(--granite-900)"
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
        , cursor: "default"
        }
    -- Hard spectrum bars, a strip along the bottom edge at rest, rise in turn to fill the button.
    -- Each bar clips its own dark copy of the label, so the bars mask the text as they rise.
    , spectrumInstall:
        { backgroundColor: "transparent"
        , color: "var(--text-primary)"
        , cursor: "default"
        , fontSize: 18
        , fontWeight: 900
        , letterSpacing: "-0.04em"
        , lineHeight: 1
        , overflow: "hidden"
        , textTransform: "uppercase"
        , width: 168
        , "--install-fill": { default: "0.07", ":hover": "1", ":focus-visible": "1" }
        -- The bars would cover the header's focus outline, so the ring is drawn above them.
        , outlineStyle: "none"
        , "--install-ring": { default: "transparent", ":focus-visible": "var(--focus-ring)" }
        , "::after":
            { boxShadow: "inset 0 0 0 2px var(--install-ring, transparent)"
            , content: "''"
            , insetBlock: 0
            , insetInline: 0
            , pointerEvents: "none"
            , position: "absolute"
            , zIndex: 2
            }
        }
    , pressedInstall:
        { "--install-wave":
            { default: installWave, "@media (prefers-reduced-motion: reduce)": "none" }
        , "--install-label-wave":
            { default: installLabelWave, "@media (prefers-reduced-motion: reduce)": "none" }
        }
    , bars:
        { display: "flex"
        , insetBlock: 0
        , insetInline: 0
        , pointerEvents: "none"
        , position: "absolute"
        , zIndex: 1
        }
    -- The clip extends past each side so that bars meet without anti-aliased seams.
    , bar:
        { clipPath: "inset(calc((1 - var(--install-fill, 0.07)) * 100%) -1px 0 -1px)"
        , flexBasis: 0
        , flexGrow: 1
        , minWidth: 0
        , position: "relative"
        , transitionDuration: { default: "320ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
        , transitionProperty: "clip-path"
        , transitionTimingFunction: "var(--ease-out)"
        , animationDuration: "520ms"
        , animationName: "var(--install-wave, none)"
        , animationTimingFunction: "cubic-bezier(0.45, 0, 0.55, 1)"
        }
    , bar0:
        { backgroundColor: "var(--spectrum-red)", animationDelay: "0ms", transitionDelay: "0ms" }
    , bar1:
        { backgroundColor: "var(--spectrum-orange)"
        , animationDelay: "45ms"
        , transitionDelay: "28ms"
        }
    , bar2:
        { backgroundColor: "var(--spectrum-yellow)"
        , animationDelay: "90ms"
        , transitionDelay: "56ms"
        }
    , bar3:
        { backgroundColor: "var(--spectrum-green)"
        , animationDelay: "135ms"
        , transitionDelay: "84ms"
        }
    , bar4:
        { backgroundColor: "var(--spectrum-blue)"
        , animationDelay: "180ms"
        , transitionDelay: "112ms"
        }
    , bar5:
        { backgroundColor: "var(--spectrum-indigo)"
        , animationDelay: "225ms"
        , transitionDelay: "140ms"
        }
    , bar6:
        { backgroundColor: "var(--spectrum-violet)"
        , animationDelay: "270ms"
        , transitionDelay: "168ms"
        }
    -- Each copy spans the whole button, offset so it lines up with the label beneath.
    , barLabel:
        { alignItems: "center"
        , animationDelay: "inherit"
        , animationDuration: "inherit"
        , animationName: "var(--install-label-wave, none)"
        , animationTimingFunction: "inherit"
        , color: "var(--granite-950)"
        , display: "flex"
        , insetBlock: 0
        , justifyContent: "center"
        , position: "absolute"
        , width: "700%"
        }
    , barLabel0: { insetInlineStart: "0%" }
    , barLabel1: { insetInlineStart: "-100%" }
    , barLabel2: { insetInlineStart: "-200%" }
    , barLabel3: { insetInlineStart: "-300%" }
    , barLabel4: { insetInlineStart: "-400%" }
    , barLabel5: { insetInlineStart: "-500%" }
    , barLabel6: { insetInlineStart: "-600%" }
    , spectrumInstallLabel: { position: "relative" }
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
                , menuInstallButton
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
        , spectrumInstallButton
        ]
    ]
  where
  menuInstallButton =
    DOM.button
      { className:
          ( StyleX.props [ styles.link, styles.landingItem, styles.install, styles.menuItem ]
          ).className
      , onClick: handler_ onInstall
      , type: "button"
      }
      "Install"
  spectrumInstallButton =
    element
      spectrumInstallButtonImpl
      { className: (StyleX.props spectrumInstallStyles).className
      , pressedClassName:
          (StyleX.props (spectrumInstallStyles <> [ styles.pressedInstall ])).className
      , label: "Install"
      , onPress: onInstall
      , content:
          [ DOM.span
              { className: styleProps.bars.className, "aria-hidden": true }
              ( map
                  ( \{ bar, label } ->
                      DOM.span
                        (StyleX.props [ styles.bar, bar ])
                        (DOM.span (StyleX.props [ styles.barLabel, label ]) "Install")
                  )
                  [ { bar: styles.bar0, label: styles.barLabel0 }
                  , { bar: styles.bar1, label: styles.barLabel1 }
                  , { bar: styles.bar2, label: styles.barLabel2 }
                  , { bar: styles.bar3, label: styles.barLabel3 }
                  , { bar: styles.bar4, label: styles.barLabel4 }
                  , { bar: styles.bar5, label: styles.barLabel5 }
                  , { bar: styles.bar6, label: styles.barLabel6 }
                  ]
              )
          , DOM.span styleProps.spectrumInstallLabel "Install"
          ]
      }
  spectrumInstallStyles =
    [ styles.link, styles.landingItem, styles.desktopInstall, styles.spectrumInstall ]
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
