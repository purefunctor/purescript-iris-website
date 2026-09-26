module Website.Landing.Demos (component) where

import Prelude

import Iris.StyleX as StyleX
import Data.Array (mapWithIndex)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (handler_)
import React.Basic.Hooks as Hooks
import Website.Components.ContentShell as ContentShell
import Website.Components.Icon as Icon
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

styles = StyleX.create
  { section:
      { backgroundColor: "var(--landing-color-paper)"
      , paddingBlock: "clamp(72px, 8vw, 120px)"
      }
  , heading:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "clamp(2.5rem, 5vw, 4.5rem)"
      , fontWeight: 520
      , letterSpacing: "-0.045em"
      , lineHeight: 1
      }
  , intro:
      { color: "var(--landing-color-muted)"
      , fontSize: 17
      , lineHeight: 1.6
      , marginBlock: "16px 32px"
      }
  , layout:
      { alignItems: "start"
      , display: "grid"
      , gap: "clamp(28px, 4vw, 56px)"
      , gridTemplateColumns:
          { default: "minmax(0, 1.7fr) minmax(0, 1fr)"
          , "@media (max-width: 800px)": "minmax(0, 1fr)"
          }
      }
  , playerPane:
      { gridColumn: 1
      , gridRow: 1
      , minWidth: 0
      }
  , player:
      { aspectRatio: "16 / 9"
      , backgroundColor: "var(--landing-color-purescript-charcoal)"
      , width: "100%"
      }
  , caption:
      { display: "grid"
      , gap: 6
      , marginBlockStart: 18
      }
  , captionTitle:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "clamp(1.5rem, 3vw, 2.25rem)"
      , fontWeight: 600
      , lineHeight: 1.1
      }
  , captionDescription:
      { color: "var(--landing-color-muted)"
      , fontSize: 15
      , lineHeight: 1.5
      }
  , groups:
      { display: "grid"
      , gap: 22
      , gridColumn: 2
      , gridRow: 1
      , minWidth: 0
      , paddingInlineStart: 24
      , borderLeft: "1px solid var(--landing-color-line)"
      , "@media (max-width: 800px)":
          { borderLeft: "none"
          , gap: 16
          , gridColumn: 1
          , gridRow: 2
          , paddingInlineStart: 0
          }
      }
  , group: { minWidth: 0 }
  , groupTitle:
      { fontFamily: "var(--landing-font-heading)"
      , fontSize: "clamp(1.2rem, 1.7vw, 1.5rem)"
      , fontWeight: 600
      , lineHeight: 1.15
      , marginBottom: 8
      }
  , list:
      { display: "grid"
      , gap: 2
      , listStyle: "none"
      , minWidth: 0
      , padding: 0
      , width: "100%"
      }
  , choice:
      { alignItems: "center"
      , backgroundColor:
          { default: "transparent"
          , ":hover": "oklch(from var(--landing-color-violet) l c h / 7%)"
          }
      , color: "var(--landing-color-ink)"
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "grid"
      , fontSize: 14
      , gap: 8
      , gridTemplateColumns: "24px minmax(0, 1fr) 14px"
      , minHeight: 38
      , padding: "7px 8px"
      , textAlign: "left"
      , width: "100%"
      , ":focus-visible": { outline: "2px solid var(--landing-color-crystal)", outlineOffset: 2 }
      , "@media (max-width: 800px)": { minHeight: 48 }
      }
  , selected:
      { backgroundColor: "oklch(from var(--landing-color-violet) l c h / 10%)"
      , color: "var(--landing-color-violet)"
      }
  , number:
      { color: "var(--landing-color-muted)"
      , fontFamily: "var(--landing-font-code)"
      , fontSize: 12
      }
  , play:
      { color: "var(--landing-color-violet)"
      , display: "inline-flex"
      , fontSize: 15
      , justifyContent: "flex-end"
      }
  }

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "EditorDemos" \_ -> Hooks.do
  selected /\ setSelected <- Hooks.useState'
    { demo: inferredTypes, sequence: 0, autoplay: false }
  let
    select demo = setSelected { demo, sequence: selected.sequence + 1, autoplay: true }
  pure $ DOM.section
    { className: (StyleX.props styles.section).className
    , id: "editor-demos"
    , "aria-labelledby": "editor-demos-heading"
    }
    [ DOM.div ContentShell.contentShell
        [ DOM.h2 { className: (StyleX.props styles.heading).className, id: "editor-demos-heading" }
            "Iris in the editor"
        , DOM.p (StyleX.props styles.intro)
            "Twelve short recordings of the Iris VS Code extension working in this website’s PureScript source. Choose a workflow to watch."
        , DOM.div (StyleX.props styles.layout)
            [ DOM.div (StyleX.props styles.playerPane)
                [ DOM.createBuiltinElement "video"
                    { key: show selected.sequence
                    , className: (StyleX.props styles.player).className
                    , autoPlay: selected.autoplay
                    , controls: true
                    , playsInline: true
                    , poster: if selected.autoplay then "" else "/editor-demos/inferred-types.webp"
                    , preload: "none"
                    , src: mediaPath selected.demo.slug
                    , "aria-label": selected.demo.title <> " demo"
                    }
                    []
                , DOM.div (StyleX.props styles.caption)
                    [ DOM.h3 (StyleX.props styles.captionTitle) selected.demo.title
                    , DOM.p (StyleX.props styles.captionDescription) selected.demo.description
                    ]
                ]
            , DOM.div (StyleX.props styles.groups)
                [ group "Type intelligence while editing" 1 typeIntelligence selected.demo.slug
                    select
                , group "Everyday editor workflows" 6 workflows selected.demo.slug select
                ]
            ]
        ]
    ]

group :: String -> Int -> Array Demo -> String -> (Demo -> Effect Unit) -> JSX
group title start demos selectedSlug setSelected =
  DOM.div (StyleX.props styles.group)
    [ DOM.h3 (StyleX.props styles.groupTitle) title
    , DOM.ol (StyleX.props styles.list) $ mapWithIndex
        ( \index demo -> DOM.li {}
            [ DOM.button
                { type: "button"
                , className:
                    ( StyleX.props
                        [ styles.choice
                        , StyleX.conditional (selectedSlug == demo.slug) styles.selected
                        ]
                    ).className
                , "aria-pressed": selectedSlug == demo.slug
                , onClick: handler_ (setSelected demo)
                }
                [ DOM.span (StyleX.props styles.number) (show (start + index))
                , DOM.span {} demo.title
                , DOM.span (StyleX.props styles.play)
                    (element Icon.play { "aria-hidden": true, focusable: false })
                ]
            ]
        )
        demos
    ]
