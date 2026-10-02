module Website.Components.Header (playgroundHeader) where

import Prelude

import Iris.StyleX as StyleX
import Website.Components.Header.Styles (controlStyles)
import React.Basic (JSX)
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetSelf)

styles = StyleX.create
  { headerBackground:
      { "--landing-header-color": "var(--landing-color-paper)"
      , backgroundColor: "var(--landing-color-purescript-charcoal)"
      , flexShrink: 0
      , width: "100%"
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
      , ":focus-visible":
          { outline: "2px solid var(--landing-header-focus, var(--landing-color-signal))"
          , outlineOffset: 4
          }
      }
  , headerBrandCopy: { display: "flex" }
  , headerBrandName:
      { fontFamily: "var(--landing-font-wordmark)"
      , fontSize: 26
      , fontWeight: 400
      , letterSpacing: "-0.045em"
      , lineHeight: 0.9
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
