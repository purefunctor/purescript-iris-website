module Website.Components.SiteNav (headerLink, siteHeader, siteNav) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import React.Basic.Events (EventHandler)
import Website.Breakpoints (breakpoints)
import Website.Components.Button as Button
import Website.Components.ExternalLink as ExternalLink
import Website.Components.Icon as Icon
import Website.Components.Logo (logo)
import Website.Components.NavigationLink as NavigationLink
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

foreign import scrollToTop :: EventHandler

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
    , brand:
        { alignItems: "center"
        , borderRadius: 5
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
            StyleX.conditionalValue "flex" [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
        , alignSelf: "stretch"
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
        , fontWeight: 600
        }
    , actions:
        { alignItems: "center"
        , alignSelf: "stretch"
        , display: "flex"
        , flexShrink: 0
        , gap: 8
        , marginInlineStart: "auto"
        }
    , iconLink:
        { alignItems: "center"
        , backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
        , borderRadius: 8
        , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
        , cursor: "default"
        , display: "inline-flex"
        , fontSize: 13
        , height: 36
        , justifyContent: "center"
        , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , transitionDuration: "140ms"
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
        , width: 36
        }
    }

styleProps = StyleX.recordProps styles

-- | Shared site chrome and home link, spanning the viewport; each area supplies its own
-- | navigation.
siteHeader :: Array JSX -> JSX
siteHeader navigation =
  DOM.header
    styleProps.header
    [ DOM.div
        styleProps.content
        ( [ DOM.div
              styleProps.brandCell
              [ DOM.a
                  { className: styleProps.brand.className
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
    [ DOM.nav
        { className: styleProps.links.className, "aria-label": "Sections" }
        [ link "/#benchmarks" "Benchmarks", link "/#editor" "Editor" ]
    , DOM.div
        styleProps.actions
        [ link "/docs/getting-started" "Docs"
        , DOM.a
            { className: styleProps.iconLink.className
            , href: "https://github.com/purefunctor/purescript-iris"
            , rel: "noopener noreferrer"
            , target: targetBlank
            , "aria-label": "Iris on GitHub" <> ExternalLink.newTabLabel
            }
            (element Icon.gitHub { "aria-hidden": true, focusable: false })
        , Button.buttonAction
            { icon: Nothing
            , label: "Install"
            , onPress: onInstall
            , size: Button.Small
            , variant: Button.Primary
            }
        ]
    ]
  where
  link href label = headerLink { href, label, current: false }

-- | A link in a site header's navigation, marked when it leads to the current page.
headerLink :: { href :: String, label :: String, current :: Boolean } -> JSX
headerLink { href, label, current } =
  NavigationLink.navigationLink
    { href
    , className: (StyleX.props [ styles.link, StyleX.conditional current styles.current ]).className
    , current
    , content: DOM.text label
    }
