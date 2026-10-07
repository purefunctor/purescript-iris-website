module Website.Components.SiteNav (siteHeader, siteNav) where

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
        , gap: "clamp(12px, 2.4vw, 28px)"
        , height: "100%"
        , marginInline: "auto"
        , maxWidth: "var(--container-wide)"
        , minWidth: 0
        , paddingInline: "var(--gutter)"
        }
    , brand:
        { alignItems: "center"
        , borderRadius: 5
        , color: "var(--text-primary)"
        , cursor: "default"
        , display: "inline-flex"
        , gap: 7
        , lineHeight: 1
        , boxShadow:
            { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , textDecoration: "none"
        }
    , logo: { flexShrink: 0, height: 26, width: 26 }
    , name: { alignItems: "baseline", display: "inline-flex", gap: 6 }
    , wordmark: { fontSize: 21, fontWeight: 900, letterSpacing: "-0.04em" }
    , stage:
        { color: "var(--text-tertiary)"
        , fontFamily: "var(--font-mono)"
        , fontSize: 11
        , fontWeight: 500
        , transform: "translateY(-2px)"
        }
    , links:
        { display:
            StyleX.conditionalValue
              "flex"
              [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
        , gap: 4
        , minWidth: 0
        }
    , link:
        { backgroundColor:
            { default: "transparent", ":hover": "var(--surface-2)" }
        , borderRadius: 5
        , color:
            { default: "var(--text-secondary)"
            , ":hover": "var(--text-primary)"
            }
        , cursor: "default"
        , fontSize: 14
        , fontWeight: 500
        , lineHeight: 1
        , boxShadow:
            { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , paddingBlock: 7
        , paddingInline: 10
        , textDecoration: "none"
        , transitionDuration: "140ms"
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
        , whiteSpace: "nowrap"
        }
    , actions:
        { alignItems: "center"
        , display: "flex"
        , flexShrink: 0
        , gap: 8
        , marginInlineStart: "auto"
        }
    , iconLink:
        { alignItems: "center"
        , backgroundColor:
            { default: "transparent", ":hover": "var(--surface-2)" }
        , borderRadius: 8
        , color:
            { default: "var(--text-secondary)"
            , ":hover": "var(--text-primary)"
            }
        , cursor: "default"
        , display: "inline-flex"
        , fontSize: 13
        , height: 36
        , justifyContent: "center"
        , boxShadow:
            { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , transitionDuration: "140ms"
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
        , width: 36
        }
    }

styleProps = StyleX.recordProps styles

-- | Shared site chrome and home link; each area supplies its own navigation.
siteHeader :: Array JSX -> JSX
siteHeader navigation =
  DOM.header
    styleProps.header
    [ DOM.div
        styleProps.content
        (
          [ DOM.a
              { className: styleProps.brand.className
              , href: "/"
              , onClick: scrollToTop
              , "aria-label": "Iris home"
              }
              [ logo { className: styleProps.logo.className }
              , DOM.span
                  styleProps.name
                  [ DOM.span styleProps.wordmark "IRIS"
                  , DOM.span
                      { className: styleProps.stage.className
                      , "aria-hidden": true
                      }
                      "alpha"
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
        [ link "#benchmarks" "Benchmarks", link "#editor" "Editor" ]
    , DOM.div
        styleProps.actions
        [ DOM.a
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
  link href label = DOM.a { className: styleProps.link.className, href } label
