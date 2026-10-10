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
import Website.Breakpoints (breakpoints)
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
  , description: "Hover shows the inferred types of local values, with no annotations required."
  }

typeIntelligence :: Array Demo
typeIntelligence =
  [ inferredTypes
  , { slug: "rename"
    , title: "Scope-aware rename"
    , description: "Renames follow scope, leaving a similarly named style field untouched."
    }
  , { slug: "live-diagnostics"
    , title: "Live diagnostics"
    , description:
        "Type errors appear and clear on unsaved edits; on-change diagnostics are opt-in."
    }
  , { slug: "document-highlights"
    , title: "Document highlights"
    , description: "Every reference to a local binding is highlighted in the current file."
    }
  , { slug: "semantic-highlighting"
    , title: "Semantic highlighting"
    , description:
        "Names are coloured by their role: parameters, functions, constructors, types and classes."
    }
  ]

workflows :: Array Demo
workflows =
  [ { slug: "completion"
    , title: "Completion"
    , description: "Completion offers names in scope, including locally bound setters."
    }
  , { slug: "typed-hole-suggestions"
    , title: "Typed-hole suggestions"
    , description: "A typed hole is replaced with a suggested expression that fits its type."
    }
  , { slug: "automatic-import"
    , title: "Automatic imports"
    , description: "Completing a name from another module adds its import."
    }
  , { slug: "go-to-definition"
    , title: "Go to definition"
    , description: "Names jump to their declarations, in the project or its dependencies."
    }
  , { slug: "find-references"
    , title: "Find references"
    , description: "Every use of a name is found across the workspace."
    }
  , { slug: "document-symbols"
    , title: "Document symbols"
    , description: "Declarations in the current file are searchable by name."
    }
  , { slug: "workspace-symbols"
    , title: "Workspace symbols"
    , description: "Declarations across the whole project are searchable by name."
    }
  ]

demos :: Array Demo
demos = typeIntelligence <> workflows

styles =
  StyleX.create
    { introduction:
        { display: "flex", flexDirection: "column", gap: 14, marginBlockEnd: 40, maxWidth: 640 }
    -- The playlist keeps a narrow column beside the player and moves below it on smaller screens.
    , layout:
        { alignItems: "start"
        , display: "grid"
        , gap: 40
        , gridTemplateColumns:
            StyleX.conditionalValue
              "minmax(0, 1fr)"
              [ StyleX.conditionalCase breakpoints.from960 "minmax(0, 1fr) 260px" ]
        }
    , playerColumn: { display: "flex", flexDirection: "column", gap: 20, minWidth: 0 }
    , caption: { display: "flex", flexDirection: "column", gap: 6, maxWidth: "68ch" }
    , captionTitle: { fontSize: 20, fontWeight: 500, letterSpacing: "-0.015em", lineHeight: 1.25 }
    , captionDescription:
        { color: "var(--text-secondary)", fontSize: 15, lineHeight: 1.65, textWrap: "pretty" }
    , groups: { display: "flex", flexDirection: "column", gap: 28, minWidth: 0 }
    , groupTitle:
        { color: "var(--text-tertiary)"
        , fontSize: 13
        , fontWeight: 500
        , lineHeight: 1.3
        , paddingBlockEnd: 8
        , paddingInline: 12
        }
    , list: { display: "flex", flexDirection: "column", gap: 2, listStyle: "none", padding: 0 }
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
        , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
        , outline: { default: "revert", ":focus-visible": "none" }
        , paddingBlock: 10
        , paddingInline: 12
        , textAlign: "start"
        , transitionDuration: "140ms"
        , transitionProperty: "background-color, color"
        , transitionTimingFunction: "var(--ease-out)"
        , width: "100%"
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
  -- Recordings wait for the visitor's first play or selection.
  playing /\ setPlaying <- Hooks.useState false
  let
    demo = fromMaybe inferredTypes (index demos selected)
    select number = do
      setSelected (const number)
      setPlaying (const true)
  pure
    $ DOM.section
        { className: Section.section.className, id: "editor", "aria-labelledby": "editor-heading" }
        [ DOM.div
            ContentShell.contentShell
            [ DOM.div
                styleProps.introduction
                [ Section.heading
                    { id: "editor-heading", text: "Language analysis in the editor.", emphasis: "" }
                , Section.lead
                    "The IRIS language server provides completion, navigation, diagnostics and code actions via the Language Server Protocol. See the demo on Visual Studio Code:"
                ]
            , DOM.div
                styleProps.layout
                [ DOM.div
                    styleProps.playerColumn
                    [ element
                        VideoPlayer.component
                        { label: demo.title <> " recording"
                        , onEnded: setSelected \current -> (current + 1) `mod` length demos
                        , playing
                        , poster: if selected == 0 then "/editor-demos/inferred-types.webp" else ""
                        , setPlaying
                        , src: mediaPath demo.slug
                        }
                    , DOM.div
                        styleProps.caption
                        [ DOM.h3 styleProps.captionTitle demo.title
                        , DOM.p styleProps.captionDescription demo.description
                        ]
                    ]
                , DOM.div
                    styleProps.groups
                    [ group "Type intelligence" 0 typeIntelligence selected select
                    , group
                        "Navigation and editing"
                        (length typeIntelligence)
                        workflows
                        selected
                        select
                    ]
                ]
            ]
        ]

group :: String -> Int -> Array Demo -> Int -> (Int -> Effect Unit) -> JSX
group title offset items selected select =
  DOM.div
    {}
    [ DOM.h3 styleProps.groupTitle title
    , DOM.ol styleProps.list
        $ mapWithIndex
            ( \position demo ->
                let
                  number = offset + position
                  current = number == selected
                in
                  DOM.li
                    {}
                    [ DOM.button
                        { type: "button"
                        , className:
                            ( StyleX.props
                                [ styles.choice, StyleX.conditional current styles.selected ]
                            ).className
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
