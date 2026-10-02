module Website.Landing.Places (places) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Components.ContentShell as ContentShell
import Website.Components.Icon as Icon
import Website.Landing.Section as Section
import Yoga.React.DOM as DOM

type Place =
  { icon :: ReactComponent Icon.IconProps
  , title :: String
  , body :: String
  , command :: String
  }

placeList :: Array Place
placeList =
  [ { icon: Icon.server
    , title: "On the server"
    , body:
        "Build a Spago package and run it on Node.js. Test suites run the same way with iris test."
    , command: "iris run"
    }
  , { icon: Icon.globe
    , title: "In the browser"
    , body:
        "Emit ES modules for Vite and other bundlers. This website’s React components are written in PureScript and compiled by Iris."
    , command: "iris build"
    }
  , { icon: Icon.codeXml
    , title: "In your editor"
    , body:
        "The language server answers completion, hover, references and diagnostics from the same incremental queries as the build."
    , command: "iris lsp --stdio"
    }
  ]

styles = StyleX.create
  { section: { paddingBlock: "96px 40px" }
  , heading: { marginBlockEnd: 40, maxWidth: 640 }
  , grid:
      { display: "grid"
      , gap: 16
      , gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 280px), 1fr))"
      , listStyle: "none"
      , padding: 0
      }
  , card:
      { backgroundColor: "var(--surface-1)"
      , borderRadius: 12
      , display: "flex"
      , flexDirection: "column"
      , gap: 14
      , minWidth: 0
      , padding: 24
      }
  , icon:
      { alignItems: "center"
      , backgroundColor: "var(--accent-soft)"
      , borderRadius: 8
      , color: "var(--accent-text)"
      , display: "inline-flex"
      , fontSize: 15
      , height: 36
      , justifyContent: "center"
      , width: 36
      }
  , title:
      { fontSize: 20
      , fontWeight: 500
      , letterSpacing: "-0.015em"
      , lineHeight: 1.25
      }
  , body:
      { color: "var(--text-secondary)"
      , fontSize: 15
      , lineHeight: 1.65
      , textWrap: "pretty"
      }
  , command:
      { color: "var(--text-tertiary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , lineHeight: 1.62
      , marginBlockStart: "auto"
      , paddingBlockStart: 6
      }
  }

styleProps = StyleX.recordProps styles

places :: JSX
places =
  DOM.section { className: styleProps.section.className, "aria-labelledby": "places-heading" }
    [ DOM.div ContentShell.contentShell
        [ DOM.div styleProps.heading
            [ Section.heading
                { id: "places-heading", text: "One language, ", emphasis: "three places." }
            ]
        , DOM.ul styleProps.grid (map place placeList)
        ]
    ]
  where
  place { icon, title, body, command } =
    DOM.li styleProps.card
      [ DOM.span styleProps.icon (element icon { "aria-hidden": true, focusable: false })
      , DOM.h3 styleProps.title title
      , DOM.p styleProps.body body
      , DOM.code styleProps.command ("$ " <> command)
      ]
