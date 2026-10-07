module Website.Landing.Footer (footer) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX, element)
import Website.Components.ExternalLink as ExternalLink
import Website.Components.Icon as Icon
import Website.Components.Logo (logo)
import Yoga.React.DOM as DOM

type Column = { heading :: String, links :: Array { label :: String, href :: String } }

columns :: Array Column
columns =
  [ { heading: "Project"
    , links:
        [ { label: "Releases"
          , href: "https://github.com/purefunctor/purescript-iris/releases"
          }
        , { label: "Compiler source"
          , href: "https://github.com/purefunctor/purescript-iris"
          }
        , { label: "Extension source"
          , href: "https://github.com/purefunctor/purescript-iris-vscode"
          }
        , { label: "Website source"
          , href: "https://github.com/purefunctor/purescript-iris-website"
          }
        ]
    }
  , { heading: "PureScript"
    , links:
        [ { label: "PureScript", href: "https://www.purescript.org" }
        , { label: "Pursuit", href: "https://pursuit.purescript.org" }
        , { label: "Registry", href: "https://github.com/purescript/registry" }
        , { label: "Spago", href: "https://github.com/purescript/spago" }
        ]
    }
  , { heading: "Follow"
    , links:
        [ { label: "Bluesky", href: "https://bsky.app/profile/purefunctor.me" }
        , { label: "X / Twitter", href: "https://x.com/purefunctor" }
        ]
    }
  ]

styles = StyleX.create
  { footer:
      { backgroundColor: "var(--bg-canvas)"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      }
  , content:
      { marginInline: "auto"
      , maxWidth: "var(--container-wide)"
      , paddingBlockStart: 56
      , paddingBlockEnd: 40
      , paddingInline: "var(--gutter)"
      }
  , columns:
      { display: "grid"
      , gap: 32
      , gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 160px), 1fr))"
      }
  , brand: { display: "flex", flexDirection: "column", gap: 12 }
  , lockup: { alignItems: "center", display: "flex", gap: 10 }
  , logo: { flexShrink: 0, height: 38, width: 38 }
  , wordmark:
      { fontSize: 32
      , fontWeight: 900
      , letterSpacing: "-0.04em"
      , lineHeight: 1
      }
  , tagline:
      { color: "var(--text-tertiary)"
      , fontSize: 13
      , lineHeight: 1.5
      , maxWidth: 280
      , textWrap: "pretty"
      }
  , column: { display: "flex", flexDirection: "column", gap: 10 }
  , heading:
      { color: "var(--text-tertiary)"
      , fontSize: 13
      , fontWeight: 600
      , lineHeight: 1.3
      }
  , links: { display: "flex", flexDirection: "column", gap: 10, listStyle: "none", padding: 0 }
  , link:
      { borderRadius: 3
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , fontSize: 13
      , lineHeight: 1.5
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , textDecorationColor: { default: "transparent", ":hover": "currentColor" }
      , textDecorationLine: "underline"
      , textUnderlineOffset: 3
      , transitionDuration: "140ms"
      , transitionProperty: "color, text-decoration-color"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , legal:
      { alignItems: "center"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , color: "var(--text-tertiary)"
      , display: "flex"
      , flexWrap: "wrap"
      , fontSize: 13
      , rowGap: 8
      , columnGap: 24
      , lineHeight: 1.5
      , marginBlockStart: 48
      , paddingBlockStart: 24
      }
  , notice: { alignItems: "center", display: "inline-flex", gap: 5 }
  , copyright: { display: "inline-flex", fontSize: 12 }
  }

styleProps = StyleX.recordProps styles

footer :: JSX
footer =
  DOM.footer styleProps.footer
    [ DOM.div styleProps.content
        [ DOM.div styleProps.columns
            ( [ DOM.div styleProps.brand
                  [ DOM.div styleProps.lockup
                      [ logo { className: styleProps.logo.className }
                      , DOM.span styleProps.wordmark "IRIS"
                      ]
                  , DOM.p styleProps.tagline
                      "A superset of PureScript, written in Rust."
                  ]
              ] <> map column columns
            )
        , DOM.p styleProps.legal
            [ notice "PureScript" "https://github.com/purescript/purescript/blob/master/LICENSE"
                " 2017–2025"
            , notice "IRIS" "https://github.com/purefunctor/purescript-iris/blob/main/LICENSE"
                " by purefunctor, 2023–2026"
            ]
        ]
    ]
  where
  column { heading, links } =
    DOM.nav { className: styleProps.column.className, "aria-labelledby": "footer-" <> heading }
      [ DOM.h2 { className: styleProps.heading.className, id: "footer-" <> heading } heading
      , DOM.ul styleProps.links
          ( map
              ( \{ label, href } -> DOM.li {}
                  ( ExternalLink.externalLink { className: styleProps.link.className, href }
                      [ DOM.text label ]
                  )
              )
              links
          )
      ]

  notice name href suffix =
    DOM.span styleProps.notice
      [ DOM.span
          { className: styleProps.copyright.className, role: "img", "aria-label": "Copyright" }
          (element Icon.copyright { "aria-hidden": true, focusable: false })
      , ExternalLink.externalLink { className: styleProps.link.className, href } [ DOM.text name ]
      , DOM.span {} suffix
      ]
