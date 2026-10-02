module Website.Landing.Demos (component) where

import Prelude

import Data.Array (index, length, mapWithIndex)
import Data.Maybe (fromMaybe)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (handler_)
import React.Basic.Hooks as Hooks
import Website.Components.ContentShell as ContentShell
import Website.Components.VideoPlayer as VideoPlayer
import Website.Landing.Section as Section
import Yoga.React.DOM as DOM

type Demo = { slug :: String, title :: String, description :: String }

mediaPath :: String -> String
mediaPath slug = "/editor-demos/" <> slug <> ".mp4"

inferredTypes :: Demo
inferredTypes =
  { slug: "inferred-types"
  , title: "Inferred local types"
  , description: "Inspect the types of local values without adding annotations."
  }

typeIntelligence :: Array Demo
typeIntelligence =
  [ inferredTypes
  , { slug: "rename"
    , title: "Scope-aware rename"
    , description: "Rename a binding without changing a similarly named style field."
    }
  , { slug: "live-diagnostics"
    , title: "Live diagnostics"
    , description:
        "Find and clear a type error on an unsaved edit. On-change diagnostics are optional."
    }
  , { slug: "document-highlights"
    , title: "Document highlights"
    , description: "See references to a local binding in the current file."
    }
  , { slug: "semantic-highlighting"
    , title: "Semantic highlighting"
    , description: "See semantic colors in a PureScript source file."
    }
  ]

workflows :: Array Demo
workflows =
  [ { slug: "completion", title: "Completion", description: "Complete a locally bound setter." }
  , { slug: "typed-hole-suggestions"
    , title: "Typed-hole suggestions"
    , description: "Replace a typed hole with a suggested expression."
    }
  , { slug: "automatic-import"
    , title: "Automatic imports"
    , description: "Import a completed name."
    }
  , { slug: "go-to-definition"
    , title: "Go to definition"
    , description: "Jump from a name to its definition."
    }
  , { slug: "find-references"
    , title: "Find references"
    , description: "Find uses of a name across the workspace."
    }
  , { slug: "document-symbols"
    , title: "Document symbols"
    , description: "Search symbols in the current file."
    }
  , { slug: "workspace-symbols"
    , title: "Workspace symbols"
    , description: "Search symbols across the project."
    }
  ]

demos :: Array Demo
demos = typeIntelligence <> workflows

styles = StyleX.create
  { section: { paddingBlock: "64px 96px", scrollMarginTop: "var(--nav-height)" }
  , introduction:
      { display: "flex"
      , flexDirection: "column"
      , gap: 14
      , marginBlockEnd: 40
      , maxWidth: 640
      }
  , layout:
      { alignItems: "flex-start"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: "40px 56px"
      }
  , playerColumn:
      { display: "flex"
      , flexBasis: 560
      , flexDirection: "column"
      , flexGrow: 1
      , flexShrink: 1
      , gap: 20
      , minWidth: 0
      }
  , caption:
      { display: "flex"
      , flexDirection: "column"
      , gap: 6
      , maxWidth: "68ch"
      }
  , captionTitle:
      { fontSize: 20
      , fontWeight: 500
      , letterSpacing: "-0.015em"
      , lineHeight: 1.25
      }
  , captionDescription:
      { color: "var(--text-secondary)"
      , fontSize: 15
      , lineHeight: 1.65
      , textWrap: "pretty"
      }
  , groups:
      { display: "flex"
      , flexBasis: 300
      , flexDirection: "column"
      , flexGrow: 1
      , flexShrink: 1
      , gap: 28
      , minWidth: 0
      }
  , groupTitle:
      { color: "var(--text-tertiary)"
      , fontSize: 13
      , fontWeight: 500
      , lineHeight: 1.3
      , paddingBlockEnd: 8
      , paddingInline: 12
      }
  , list:
      { display: "flex"
      , flexDirection: "column"
      , gap: 2
      , listStyle: "none"
      , padding: 0
      }
  , choice:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderRadius: 8
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "grid"
      , fontSize: 15
      , gap: 12
      , gridTemplateColumns: "24px minmax(0, 1fr)"
      , lineHeight: 1.65
      , padding: "10px 12px"
      , textAlign: "start"
      , transition: "background-color 140ms var(--ease-out), color 140ms var(--ease-out)"
      , width: "100%"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
  , selected:
      { backgroundColor: { default: "var(--surface-2)", ":hover": "var(--surface-2)" }
      , color: { default: "var(--text-primary)", ":hover": "var(--text-primary)" }
      }
  , number:
      { color: "var(--text-tertiary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      }
  , title: { overflowWrap: "break-word" }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "EditorDemos" \_ -> Hooks.do
  selected /\ setSelected <- Hooks.useState 0
  playing /\ setPlaying <- Hooks.useState true
  let
    demo = fromMaybe inferredTypes (index demos selected)
    select number = do
      setSelected (const number)
      setPlaying (const true)
  pure $ DOM.section
    { className: styleProps.section.className
    , id: "editor"
    , "aria-labelledby": "editor-heading"
    }
    [ DOM.div ContentShell.contentShell
        [ DOM.div styleProps.introduction
            [ Section.heading
                { id: "editor-heading", text: "Iris in ", emphasis: "your editor." }
            , Section.lead
                "Twelve short recordings of the Iris VS Code extension working in this website’s PureScript source. Choose a workflow to watch."
            ]
        , DOM.div styleProps.layout
            [ DOM.div styleProps.playerColumn
                [ element VideoPlayer.component
                    { label: demo.title <> " recording"
                    , onEnded: setSelected \current -> (current + 1) `mod` length demos
                    , playing
                    , poster: if selected == 0 then "/editor-demos/inferred-types.webp" else ""
                    , setPlaying
                    , src: mediaPath demo.slug
                    }
                , DOM.div styleProps.caption
                    [ DOM.h3 styleProps.captionTitle demo.title
                    , DOM.p styleProps.captionDescription demo.description
                    ]
                ]
            , DOM.div styleProps.groups
                [ group "Type intelligence while editing" 0 typeIntelligence selected select
                , group "Everyday editor workflows" (length typeIntelligence) workflows selected
                    select
                ]
            ]
        ]
    ]

group :: String -> Int -> Array Demo -> Int -> (Int -> Effect Unit) -> JSX
group title offset items selected select =
  DOM.div {}
    [ DOM.h3 styleProps.groupTitle title
    , DOM.ol styleProps.list $ mapWithIndex
        ( \position demo ->
            let
              number = offset + position
              current = number == selected
            in
              DOM.li {}
                [ DOM.button
                    { type: "button"
                    , className:
                        (StyleX.props [ styles.choice, StyleX.conditional current styles.selected ]).className
                    , "aria-current": if current then "true" else "false"
                    , onClick: handler_ (select number)
                    }
                    [ DOM.span styleProps.number (show (number + 1))
                    , DOM.span styleProps.title demo.title
                    ]
                ]
        )
        items
    ]
