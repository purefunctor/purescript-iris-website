module Website.Landing.Demos (component) where

import Prelude

import Data.Array (findLastIndex, index, length, mapWithIndex)
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), maybe)
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

type Chapter = { title :: String, description :: String, at :: Number }

trailer :: Array { src :: String, type :: String }
trailer =
  [ { src: "/editor-demos/trailer-av1.mp4", type: "video/mp4; codecs=\"av01.0.09M.08\"" }
  , { src: "/editor-demos/trailer.mp4", type: "video/mp4; codecs=\"avc1.64002A\"" }
  ]

reading :: Array Chapter
reading =
  [ { title: "Semantic highlighting"
    , description:
        "Names are coloured by their role, such as declarations, record labels, module qualifiers and bindings."
    , at: 5.3
    }
  , { title: "Go to definition"
    , description: "Names jump to their declarations, in the project or its dependencies."
    , at: 15.9
    }
  , { title: "Hover"
    , description:
        "Hover shows inferred types, signatures and documentation, for names and operators alike."
    , at: 18.9
    }
  , { title: "Document highlights"
    , description: "Selecting a name highlights every reference to the same binding in the file."
    , at: 32.1
    }
  , { title: "Document symbols"
    , description: "Declarations in the current file are searchable by name."
    , at: 35.6
    }
  , { title: "Find references"
    , description: "Every use of a name is found across the workspace."
    , at: 41.0
    }
  , { title: "Workspace symbols"
    , description: "Declarations across the whole project are searchable by name."
    , at: 50.3
    }
  ]

writing :: Array Chapter
writing =
  [ { title: "Rename"
    , description:
        "Renames follow scope, and update a constructor, type or value in every module that uses it, qualified or not."
    , at: 55.2
    }
  , { title: "Automatic imports"
    , description: "Completing a name from another module adds its import."
    , at: 73.6
    }
  , { title: "Completion"
    , description: "Completion offers every name in scope, including local bindings."
    , at: 83.5
    }
  , { title: "Typed holes"
    , description: "Typed holes suggest names in scope that fit the expected type."
    , at: 86.2
    }
  , { title: "Diagnostics"
    , description:
        "Type errors appear and clear on unsaved edits; on-change diagnostics are opt-in."
    , at: 91.8
    }
  ]

chapters :: Array Chapter
chapters = reading <> writing

styles = StyleX.create
  { introduction:
      { display: "flex", flexDirection: "column", gap: 14, marginBlockEnd: 40, maxWidth: 640 }
  , layout:
      { alignItems: "start"
      , display: "grid"
      , gap: 40
      , gridTemplateColumns: StyleX.conditionalValue "minmax(0, 1fr)"
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
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
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
  time /\ setTime <- Hooks.useState' 0.0
  playing /\ setPlaying <- Hooks.useState false
  seek /\ setSeek <- Hooks.useState { request: 0, time: 0.0 }
  let
    selected = findLastIndex (\chapter -> chapter.at <= time) chapters
    chapter = index chapters =<< selected
    select number = for_ (index chapters number) \{ at } -> do
      setSeek \{ request } -> { request: request + 1, time: at }
      setTime at
      setPlaying (const true)
  pure
    $ DOM.section
        { className: Section.section.className, id: "editor", "aria-labelledby": "editor-heading" }
        [ DOM.div ContentShell.contentShell
            [ DOM.div styleProps.introduction
                [ Section.heading
                    { id: "editor-heading", text: "Language analysis in the editor.", emphasis: "" }
                , Section.lead
                    "The IRIS language server provides completion, navigation, diagnostics and code actions via the Language Server Protocol. See the demo on Visual Studio Code:"
                ]
            , DOM.div styleProps.layout
                [ DOM.div styleProps.playerColumn
                    [ element VideoPlayer.component
                        { label: "Iris language server demo in Visual Studio Code"
                        , onEnded: setPlaying (const false)
                        , onTime: setTime
                        , playing
                        , poster: "/editor-demos/trailer.webp"
                        , seek
                        , setPlaying
                        , sources: trailer
                        }
                    , chapter # maybe mempty \{ title, description } -> DOM.div styleProps.caption
                        [ DOM.h3 styleProps.captionTitle title
                        , DOM.p styleProps.captionDescription description
                        ]
                    ]
                , DOM.div styleProps.groups
                    [ group "Reading code" 0 reading selected select
                    , group "Writing code" (length reading) writing selected select
                    ]
                ]
            ]
        ]

group :: String -> Int -> Array Chapter -> Maybe Int -> (Int -> Effect Unit) -> JSX
group title offset items selected select = DOM.div {}
  [ DOM.h3 styleProps.groupTitle title
  , DOM.ol styleProps.list $ mapWithIndex
      ( \position chapter ->
          let
            number = offset + position
            current = Just number == selected
          in
            DOM.li {}
              [ DOM.button
                  { type: "button"
                  , className:
                      ( StyleX.props [ styles.choice, StyleX.conditional current styles.selected ]
                      ).className
                  , "aria-current": if current then "true" else "false"
                  , onClick: handler_ (select number)
                  }
                  [ DOM.span styleProps.number (show (number + 1))
                  , DOM.span styleProps.title chapter.title
                  ]
              ]
      )
      items
  ]
