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
  , body :: Array JSX
  , command :: String
  }

-- The tools the hero names, each backed by an `iris` subcommand.
placeList :: Array Place
placeList =
  [ { icon: Icon.codeXml
    , title: "Language analysis"
    , body:
        [ DOM.text
            "Completion, hover, scope-aware rename, references and typed-hole suggestions, served to your editor by the language server."
        ]
    , command: "iris lsp --stdio"
    }
  , { icon: Icon.server
    , title: "Queryable build server"
    , body:
        [ inlineCode "iris watch"
        , DOM.text
            " keeps the project compiled in memory and answers queries for signatures, definitions, references and generated JavaScript."
        ]
    , command: "iris watch query search foldl"
    }
  , { icon: Icon.bot
    , title: "Skills for agents"
    , body:
        [ inlineCode "iris skills"
        , DOM.text
            " prints guides for coding agents that match the installed version of Iris, starting with querying "
        , inlineCode "iris watch"
        , DOM.text "."
        ]
    , command: "iris skills get watch"
    }
  ]

styles = StyleX.create
  { heading: { marginBlockEnd: 40, maxWidth: 640 }
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
  , inlineCode:
      { backgroundColor: "var(--surface-2)"
      , borderColor: "var(--border-subtle)"
      , borderRadius: 3
      , borderStyle: "solid"
      , borderWidth: 1
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: "0.92em"
      , paddingBlock: 1
      , paddingInline: 5
      , whiteSpace: "nowrap"
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

inlineCode :: String -> JSX
inlineCode = DOM.code styleProps.inlineCode

places :: JSX
places =
  DOM.section { className: Section.section.className, "aria-labelledby": "places-heading" }
    [ DOM.div ContentShell.contentShell
        [ DOM.div styleProps.heading
            [ Section.heading
                { id: "places-heading", text: "Vertically integrated tooling.", emphasis: "" }
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
