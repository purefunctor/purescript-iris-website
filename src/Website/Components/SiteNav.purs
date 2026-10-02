module Website.Components.SiteNav (siteNav) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import Website.Components.Button as Button
import Website.Components.Icon as Icon
import Yoga.React.DOM as DOM

styles = StyleX.create
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
      { alignItems: "baseline"
      , borderRadius: 5
      , color: "var(--text-primary)"
      , cursor: "default"
      , display: "inline-flex"
      , gap: 6
      , lineHeight: 1
      , textDecoration: "none"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
  , wordmark:
      { fontSize: 21
      , fontWeight: 600
      , letterSpacing: "-0.03em"
      }
  , stage:
      { color: "var(--text-tertiary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , fontWeight: 500
      , transform: "translateY(-2px)"
      }
  , links:
      { display: "flex"
      , gap: 4
      , minWidth: 0
      , "@media (max-width: 720px)": { display: "none" }
      }
  , link:
      { backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 5
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , fontSize: 14
      , fontWeight: 500
      , lineHeight: 1
      , padding: "7px 10px"
      , textDecoration: "none"
      , transition: "background-color 140ms var(--ease-out), color 140ms var(--ease-out)"
      , whiteSpace: "nowrap"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
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
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 8
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 13
      , height: 36
      , justifyContent: "center"
      , transition: "background-color 140ms var(--ease-out), color 140ms var(--ease-out)"
      , width: 36
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
  }

styleProps = StyleX.recordProps styles

-- | `onInstall` runs when the Install action is pressed.
siteNav :: { onInstall :: Effect Unit } -> JSX
siteNav { onInstall } =
  DOM.header styleProps.header
    [ DOM.div styleProps.content
        [ DOM.a { className: styleProps.brand.className, href: "/", "aria-label": "Iris home" }
            [ DOM.span styleProps.wordmark "Iris"
            , DOM.span { className: styleProps.stage.className, "aria-hidden": true } "alpha"
            ]
        , DOM.nav { className: styleProps.links.className, "aria-label": "Sections" }
            [ link "#features" "Features"
            , link "#editor" "Editor"
            ]
        , DOM.div styleProps.actions
            [ DOM.a
                { className: styleProps.iconLink.className
                , href: "https://github.com/purefunctor/purescript-iris"
                , "aria-label": "Iris on GitHub"
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
    ]
  where
  link href label = DOM.a { className: styleProps.link.className, href } label
