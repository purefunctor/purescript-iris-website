module Website.Landing.Toolchain (toolchain) where

import Prelude

import Data.Array (filter)
import Data.String (Pattern(..), split, take)
import Iris.StyleX as StyleX
import React.Basic (JSX, fragment)
import Website.Breakpoints (breakpoints)
import Website.Components.ContentShell as ContentShell
import Website.Components.Tabs as Tabs
import Website.Landing.Section as Section
import Yoga.React.DOM as DOM

type Subcommand = { name :: String, description :: String, featured :: Boolean }

subcommands :: Array Subcommand
subcommands =
  [ { name: "new"
    , description: "Create a Spago project in the current directory."
    , featured: false
    }
  , { name: "build", description: "Build a Spago workspace or package.", featured: true }
  , { name: "run", description: "Build and run a Spago package with Node.js.", featured: false }
  , { name: "test"
    , description: "Build and test one or more Spago packages with Node.js."
    , featured: false
    }
  , { name: "watch"
    , description: "Build a Spago workspace or package and rebuild when inputs change."
    , featured: true
    }
  , { name: "lsp"
    , description: "Run the language server over standard input and output."
    , featured: true
    }
  , { name: "format"
    , description: "Format a Spago workspace or explicit source files."
    , featured: true
    }
  , { name: "skills"
    , description: "Print agent skills for using Iris, which match this version."
    , featured: true
    }
  , { name: "add", description: "Add dependencies to a Spago package.", featured: false }
  , { name: "self", description: "Manage this installation of Iris.", featured: false }
  ]

type Session =
  { id :: String, label :: String, entries :: Array { command :: String, output :: String } }

sessions :: Array Session
sessions =
  [ { id: "signature"
    , label: "Query"
    , entries:
        [ { command: "iris watch query signature Data.Maybe.fromMaybe"
          , output: """-- | Takes a default value, and a `Maybe` value. If the `Maybe` value is
-- | `Nothing` the default value is returned, otherwise the value inside the
-- | `Just` is returned.
-- |
-- | ``` purescript
-- | fromMaybe x Nothing == x
-- | fromMaybe x (Just y) == y
-- | ```
fromMaybe :: forall a. a -> Maybe a -> a"""
          }
        ]
    }
  , { id: "search"
    , label: "Search"
    , entries:
        [ { command: "iris watch query search fromMay"
          , output: """Data.Maybe.fromMaybe :: forall a. a -> Maybe a -> a
Data.Maybe.fromMaybe' :: forall a. (Unit -> a) -> Maybe a -> a
Data.Unfoldable.fromMaybe :: forall (f :: Type -> Type) a. Unfoldable (f :: Type -> Type) => Maybe a -> (f :: Type -> Type) a
Web.File.FileReader.ReadyState.fromEnumReadyState :: ReadyState -> Int
Data.String.NonEmpty.CodeUnits.fromNonEmptyCharArray :: NonEmptyArray Char -> NonEmptyString
Web.HTML.HTMLMediaElement.ReadyState.fromEnumReadyState :: ReadyState -> Int
Web.HTML.HTMLTrackElement.ReadyState.fromEnumReadyState :: ReadyState -> Int
Data.String.NonEmpty.CodePoints.fromNonEmptyCodePointArray :: NonEmptyArray CodePoint -> NonEmptyString"""
          }
        ]
    }
  , { id: "format"
    , label: "Format"
    , entries:
        [ { command: "cat Main.purs"
          , output: """module Main where
import Prelude
import Effect.Console (log)
greet :: String->String
greet name = "Hello, "<>name<>"!"
main = log (greet   "Iris")"""
          }
        , { command: "iris format --file - < Main.purs"
          , output: """module Main where

import Prelude

import Effect.Console (log)

greet :: String -> String
greet name = "Hello, " <> name <> "!"
main = log (greet "Iris")"""
          }
        ]
    }
  , { id: "skills"
    , label: "Skills"
    , entries:
        [ { command: "iris skills"
          , output:
              """stylex	Write StyleX styles in PureScript with Iris through the built-in Iris.StyleX, Iris.StyleX.When, and Iris.StyleX.Types modules, which Iris compiles to `@stylexjs/stylex` calls. Covers translating StyleX's JavaScript API and examples into PureScript, the placement rules Iris enforces, what only the StyleX plugin checks, and bundler settings for Iris output. Use when writing or changing styles in a module that imports Iris.StyleX, when Iris or the StyleX plugin reports an error about StyleX code from PureScript, or when adding StyleX to a project built with Iris.
watch	Ask a running `iris watch` about a PureScript project with `iris watch query` for signatures, module exports, definitions, references, instances, dependent modules, name search, diagnostics, and generated JavaScript, addressed by qualified name. Use when working in a project built with Iris, after editing PureScript files, or instead of reading dependency sources to learn an API."""
          }
        ]
    }
  ]

overflowCue = StyleX.keyframes
  { from: { maskImage: "linear-gradient(to right, black calc(100% - 56px), transparent)" }
  , to: { maskImage: "linear-gradient(to right, black, black)" }
  }

styles = StyleX.create
  { layout:
      { alignItems: "start"
      , display: "grid"
      , columnGap: "clamp(32px, 5vw, 72px)"
      , rowGap: StyleX.conditionalValue 28 [ StyleX.conditionalCase breakpoints.upTo960 32 ]
      , gridTemplateAreas: StyleX.conditionalValue "'intro console' 'commands console'"
          [ StyleX.conditionalCase breakpoints.upTo960 "'intro' 'console' 'commands'" ]
      , gridTemplateColumns: StyleX.conditionalValue "minmax(0, 5fr) minmax(0, 7fr)"
          [ StyleX.conditionalCase breakpoints.upTo960 "minmax(0, 1fr)" ]
      , gridTemplateRows:
          StyleX.conditionalValue "auto 1fr" [ StyleX.conditionalCase breakpoints.upTo960 "auto" ]
      }
  , intro: { display: "flex", flexDirection: "column", gap: 20, gridArea: "intro" }
  , commands: { display: "flex", flexDirection: "column", gap: 4, gridArea: "commands" }
  , commandsLabel: { color: "var(--text-tertiary)", fontSize: 13, marginBlockEnd: 8 }
  , more: { color: "var(--text-tertiary)", fontSize: 14, marginBlockStart: 8 }
  , summary:
      { color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , fontSize: 14
      , outlineColor: "var(--focus-ring)"
      , paddingBlock: 8
      }
  , lead: { color: "var(--text-secondary)", fontSize: 17, lineHeight: 1.65, textWrap: "pretty" }
  , inlineCode:
      { backgroundColor: "var(--surface-2)"
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: "0.88em"
      , paddingBlock: 1
      , paddingInline: 5
      , whiteSpace: "nowrap"
      }
  , table:
      { borderBlockStartColor: "var(--border-default)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , display: "grid"
      , gridTemplateColumns: "max-content minmax(0, 1fr)"
      }
  , row: { display: "contents" }
  , name:
      { alignItems: "center"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , color: "var(--text-tertiary)"
      , display: "flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , gap: 10
      , paddingBlock: 10
      , paddingInlineEnd: 24
      , whiteSpace: "nowrap"
      }
  , featuredName: { color: "var(--text-primary)" }
  , led: { backgroundColor: "var(--granite-700)", flexShrink: 0, height: 5, width: 5 }
  , featuredLed: { backgroundColor: "var(--accent)", boxShadow: "0 0 8px var(--accent)" }
  , description:
      { borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , color: "var(--text-tertiary)"
      , fontSize: 14
      , lineHeight: 1.5
      , paddingBlock: 10
      }
  , featuredDescription: { color: "var(--text-secondary)" }
  , console:
      { alignSelf: "start"
      , gridArea: "console"
      , backgroundColor: "var(--granite-900)"
      , borderColor: "var(--border-default)"
      , borderStyle: "solid"
      , borderWidth: 1
      , boxShadow:
          "inset 0 1px 0 var(--glass-highlight), 0 40px 80px -40px oklch(0% 0 0 / 80%), 0 0 0 6px oklch(from var(--granite-900) l c h / 50%)"
      , display: "flex"
      , flexDirection: "column"
      , minWidth: 0
      , top: "calc(var(--nav-height) + 32px)"
      }
  , list:
      { borderBlockEndColor: "var(--border-default)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , overflowX: "auto"
      }
  , tab:
      { alignItems: "center"
      , backgroundColor:
          { default: "transparent"
          , ":hover": "var(--surface-1)"
          , "[data-selected]": "var(--surface-1)"
          }
      , borderInlineEndColor: "var(--border-subtle)"
      , borderInlineEndStyle: "solid"
      , borderInlineEndWidth: 1
      , boxShadow: { default: "none", "[data-selected]": "inset 0 -2px 0 var(--accent)" }
      , "--led": { default: "var(--granite-700)", "[data-selected]": "var(--accent)" }
      , "--led-glow": { default: "transparent", "[data-selected]": "var(--accent)" }
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--text-primary)"
          , "[data-selected]": "var(--text-primary)"
          }
      , cursor: "default"
      , display: "flex"
      , flexShrink: 0
      , fontSize: 13
      , fontWeight: 500
      , gap: 8
      , height: 44
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , paddingInline: StyleX.conditionalValue 18 [ StyleX.conditionalCase breakpoints.upTo480 13 ]
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color, box-shadow"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , tabLed:
      { backgroundColor: "var(--led)", boxShadow: "0 0 8px var(--led-glow)", height: 5, width: 5 }
  , panel:
      { display: "flex"
      , flexDirection: "column"
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      }
  , pre:
      { color: "var(--syn-text)"
      , flexGrow: 1
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , lineHeight: 1.7
      , margin: 0
      , overflowX: "auto"
      , scrollbarColor: "var(--granite-700) transparent"
      , scrollbarWidth: "thin"
      , animationName: overflowCue
      , animationTimeline: "scroll(self inline)"
      , animationTimingFunction: "linear"
      , animationFillMode: "both"
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingBlock: 20
      , paddingInline: 22
      , tabSize: 8
      }
  , entry: { display: "block", marginBlockEnd: 18 }
  , command: { color: "var(--text-primary)", display: "block", whiteSpace: "pre" }
  , prompt: { color: "var(--accent-text)", userSelect: "none" }
  , output: { display: "block", paddingBlockStart: 6 }
  , outputLine: { color: "var(--syn-text)", display: "block", minHeight: "1lh", whiteSpace: "pre" }
  , documentation: { color: "var(--text-tertiary)", whiteSpace: "pre-wrap" }
  , status:
      { alignItems: "center"
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , color: "var(--text-secondary)"
      , display: "flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 11
      , gap: 10
      , height: 34
      , letterSpacing: "0.04em"
      , paddingInline: 18
      , textTransform: "uppercase"
      }
  , statusLed: { backgroundColor: "var(--granite-500)", height: 5, width: 5 }
  }

styleProps = StyleX.recordProps styles

toolchain :: JSX
toolchain = DOM.section
  { className: Section.section.className, id: "toolchain", "aria-labelledby": "toolchain-heading" }
  [ DOM.div ContentShell.contentShell
      [ DOM.div styleProps.layout
          [ DOM.div styleProps.intro
              [ DOM.div {}
                  [ Section.eyebrow { index: "01", label: "Toolchain" }
                  , Section.heading { id: "toolchain-heading", text: "One binary. Every tool." }
                  ]
              , DOM.p styleProps.lead
                  [ DOM.text
                      "The compiler, build server, language server, formatter and agent skills ship in one executable. "
                  , DOM.code styleProps.inlineCode "iris watch"
                  , DOM.text
                      " keeps your project compiled in memory and answers queries by qualified name, for you and for your agents."
                  ]
              ]
          , DOM.div styleProps.console
              [ Tabs.tabs
                  { label: "Terminal sessions"
                  , items: map session sessions
                  , classes:
                      { root: ""
                      , list: styleProps.list.className
                      , tab: styleProps.tab.className
                      , panel: styleProps.panel.className
                      }
                  }
              , DOM.div styleProps.status
                  [ DOM.span { className: styleProps.statusLed.className, "aria-hidden": true } []
                  , DOM.text "Captured output · Iris 0.1.15"
                  ]
              ]
          , DOM.div styleProps.commands
              [ DOM.p styleProps.commandsLabel
                  [ DOM.text "Subcommands, as "
                  , DOM.code styleProps.inlineCode "iris --help"
                  , DOM.text " describes them"
                  ]
              , DOM.dl styleProps.table (map subcommand (filter _.featured subcommands))
              , DOM.details styleProps.more
                  [ DOM.summary styleProps.summary "Every other subcommand"
                  , DOM.dl styleProps.table
                      (map subcommand (filter (not <<< _.featured) subcommands))
                  ]
              ]
          ]
      ]
  ]
  where
  subcommand { name, description, featured } = DOM.div styleProps.row
    [ DOM.dt (StyleX.props [ styles.name, StyleX.conditional featured styles.featuredName ])
        [ DOM.span
            { className:
                ( StyleX.props [ styles.led, StyleX.conditional featured styles.featuredLed ]
                ).className
            , "aria-hidden": true
            }
            []
        , DOM.text ("iris " <> name)
        ]
    , DOM.dd
        ( StyleX.props
            [ styles.description, StyleX.conditional featured styles.featuredDescription ]
        )
        description
    ]
  session { id, label, entries } =
    { id
    , tab: fragment
        [ DOM.span { className: styleProps.tabLed.className, "aria-hidden": true } []
        , DOM.text label
        ]
    , panel: DOM.pre
        { className: styleProps.pre.className
        , tabIndex: 0
        , role: "region"
        , "aria-label": label <> " output"
        }
        (DOM.code {} (map entry entries))
    }
  entry { command, output } = DOM.span styleProps.entry
    [ DOM.span styleProps.command
        [ DOM.span { className: styleProps.prompt.className, "aria-hidden": true } "$ "
        , DOM.text command
        ]
    , DOM.span styleProps.output (map outputLine (split (Pattern "\n") output))
    ]
  outputLine line = DOM.span
    ( StyleX.props
        [ styles.outputLine, StyleX.conditional (take 4 line == "-- |") styles.documentation ]
    )
    line
