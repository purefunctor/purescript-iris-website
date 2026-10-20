// Projects that the sidebar offers as starting points. The first is the default project, which a
// new visit opens and Reset restores. Each one is a complete project that loads in place of the
// current one. The program's frame carries the site's tokens and fonts, so the styles below only
// arrange elements and reuse the playground's raised keys.

const KEY = String.raw`  , key:
      { backgroundColor:
          { default: "var(--surface-2)", ":hover": "var(--surface-3)", ":active": "var(--surface-1)" }
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active": "inset 0 1px 3px oklch(0% 0 0 / 45%)"
          , ":focus-visible": "var(--shadow-focus)"
          }
      , cursor: "default"
      , fontWeight: 600
      , height: 32
      -- As wide as the playground's Run key, which reads as a key rather than an icon.
      , minWidth: 72
      , outlineStyle: "none"
      , paddingInline: 16
      , textShadow: "0 -1px 0 oklch(0% 0 0 / 35%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      }`;

const COUNTER_STYLES = String.raw`-- The number rises in whenever it changes; each value is a new element, so it plays again.
bump = StyleX.keyframes
  { from: { opacity: 0, transform: "translateY(45%) scale(0.8)" }
  , to: { opacity: 1, transform: "none" }
  }

styles = StyleX.create
  { page:
      { alignItems: "center"
      , display: "flex"
      , flexDirection: "column"
      , gap: 12
      , justifyContent: "center"
      , minHeight: "100vh"
      , padding: 24
      }
  -- Set like the site's section headings, in bold.
  , title: { fontSize: 28, fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.1, margin: 0 }
  , row: { alignItems: "center", display: "flex", gap: 12 }
  , count:
      { animationDuration: "240ms"
      , animationName: { default: bump, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      , display: "inline-block"
      , fontSize: 20
      , fontWeight: 600
      , fontVariantNumeric: "tabular-nums"
      , minWidth: "3ch"
      , textAlign: "center"
      }
${KEY}
  -- The playground's Run key: orange, with an engraved label.
  , accent:
      { backgroundColor:
          { default: "var(--accent)", ":hover": "var(--accent-hover)", ":active": "var(--accent-press)" }
      , color: "var(--text-on-accent)"
      , textShadow: "0 1px 0 oklch(from var(--signal-200) l c h / 45%)"
      }
  }

styleProps = StyleX.recordProps styles`;

const TODO_STYLES = String.raw`styles = StyleX.create
  { page: { display: "flex", flexDirection: "column", gap: 12, maxWidth: 480, padding: 24 }
  , title: { fontSize: 16, fontWeight: 600, margin: 0 }
  , form: { display: "flex", gap: 8 }
  , input:
      { backgroundColor: "var(--surface-1)"
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow:
          { default: "inset 0 1px 2px oklch(0% 0 0 / 45%)", ":focus-visible": "var(--shadow-focus)" }
      , flexGrow: 1
      , height: 32
      , minWidth: 0
      , outlineStyle: "none"
      , paddingInline: 14
      }
${KEY}
  , list: { listStyle: "none", margin: 0, padding: 0 }
  , item:
      { alignItems: "center"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , gap: 8
      , minHeight: 40
      }
  , label: { alignItems: "center", display: "flex", flexGrow: 1, gap: 10, minWidth: 0 }
  , checkbox: { accentColor: "var(--accent)", margin: 0 }
  , done: { color: "var(--text-tertiary)", textDecorationLine: "line-through" }
  , remove:
      { backgroundColor: { default: "var(--surface-1)", ":hover": "var(--surface-3)" }
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , height: 24
      , outlineStyle: "none"
      , width: 24
      }
  , remaining: { color: "var(--text-tertiary)", fontSize: 12, margin: 0 }
  }

styleProps = StyleX.recordProps styles`;

const HALOGEN_IMPORTS = String.raw`import Effect (Effect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Iris.StyleX as StyleX`;

const HALOGEN_STYLE = String.raw`-- | Halogen takes a StyleX class name as a class property.
style :: forall r i. StyleX.Props -> HP.IProp (class :: String | r) i
style { className } = HP.class_ (HH.ClassName className)`;

const REACT_MAIN = (component) => String.raw`main :: Effect Unit
main = do
  -- The playground's frame offers #app as a mount point.
  app <- getElementById "app" =<< (map toNonElementParentNode <<< document =<< window)
  case app of
    Nothing -> throw "There is no #app element."
    Just element -> do
      ${component} <- mk${component[0].toUpperCase()}${component.slice(1)}
      root <- createRoot element
      renderRoot root (${component} unit)`;

const REACT_ROOT_IMPORTS = String.raw`import React.Basic.DOM.Client (createRoot, renderRoot)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)`;

export const TEMPLATES = [
  {
    id: "console",
    name: "Console",
    description: "Logs to the output",
    files: [
      {
        path: "src/Main.purs",
        text: String.raw`module Main where

import Prelude

import Data.Array (range)
import Data.Foldable (sum)
import Effect (Effect)
import Effect.Console (log)
import Greeting (greet)

main :: Effect Unit
main = do
  log (greet "Iris")
  log ("The sum of 1 to 10 is " <> show (sum (range 1 10)))
`,
      },
      {
        path: "src/Greeting.purs",
        text: String.raw`module Greeting (greet) where

import Prelude

greet :: String -> String
greet name = "Hello, " <> name <> "!"
`,
      },
    ],
  },
  {
    id: "halogen-counter",
    name: "Halogen counter",
    description: "A Halogen component styled with StyleX",
    files: [
      {
        path: "src/Main.purs",
        text: String.raw`module Main where

import Prelude

import Data.Tuple (Tuple(..))
${HALOGEN_IMPORTS}
import Halogen.HTML.Elements.Keyed as HK

${COUNTER_STYLES}

${HALOGEN_STYLE}

data Action = Increment | Decrement

counter :: forall query input output m. H.Component query input output m
counter = H.mkComponent
  { initialState: \_ -> 0
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }
  where
  render count = HH.div [ style styleProps.page ]
    [ HH.h1 [ style styleProps.title ] [ HH.text "Halogen counter" ]
    , HH.div [ style styleProps.row ]
        [ HH.button [ style styleProps.key, HE.onClick \_ -> Decrement ] [ HH.text "−" ]
        , HK.div_
            [ Tuple (show count) (HH.span [ style styleProps.count ] [ HH.text (show count) ]) ]
        , HH.button
            [ style (StyleX.props [ styles.key, styles.accent ]), HE.onClick \_ -> Increment ]
            [ HH.text "+" ]
        ]
    ]

  handleAction = case _ of
    Increment -> H.modify_ (_ + 1)
    Decrement -> H.modify_ (_ - 1)

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI counter unit body
`,
      },
    ],
  },
  {
    id: "halogen-todos",
    name: "Halogen todos",
    description: "A Halogen todo list styled with StyleX",
    files: [
      {
        path: "src/Main.purs",
        text: String.raw`module Main where

import Prelude

import Data.Array (filter, length, snoc)
import Data.String (trim)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
${HALOGEN_IMPORTS}
import Web.Event.Event (Event, preventDefault)

${TODO_STYLES}

${HALOGEN_STYLE}

type Todo = { key :: Int, text :: String, done :: Boolean }

type State = { todos :: Array Todo, draft :: String, next :: Int }

data Action = SetDraft String | Add Event | Toggle Int | Remove Int

todos :: forall query input output. H.Component query input output Aff
todos = H.mkComponent
  { initialState: \_ ->
      { todos:
          [ { key: 0, text: "Open the playground", done: true }
          , { key: 1, text: "Write some PureScript", done: false }
          ]
      , draft: ""
      , next: 2
      }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }
  where
  render state = HH.div [ style styleProps.page ]
    [ HH.h1 [ style styleProps.title ] [ HH.text "Halogen todos" ]
    , HH.form [ style styleProps.form, HE.onSubmit Add ]
        [ HH.input
            [ style styleProps.input
            , HP.placeholder "What needs doing?"
            , HP.value state.draft
            , HE.onValueInput SetDraft
            ]
        , HH.button [ style styleProps.key, HP.type_ HP.ButtonSubmit ] [ HH.text "Add" ]
        ]
    , HH.ul [ style styleProps.list ] (map item state.todos)
    , HH.p [ style styleProps.remaining ]
        [ HH.text (show (length (filter (not <<< _.done) state.todos)) <> " left") ]
    ]

  item todo = HH.li [ style styleProps.item ]
    [ HH.label [ style styleProps.label ]
        [ HH.input
            [ style styleProps.checkbox
            , HP.type_ HP.InputCheckbox
            , HP.checked todo.done
            , HE.onChange \_ -> Toggle todo.key
            ]
        , HH.span [ style (StyleX.props [ StyleX.conditional todo.done styles.done ]) ]
            [ HH.text todo.text ]
        ]
    , HH.button
        [ style styleProps.remove, HP.title "Remove", HE.onClick \_ -> Remove todo.key ]
        [ HH.text "×" ]
    ]

  handleAction = case _ of
    SetDraft draft -> H.modify_ _ { draft = draft }
    Add event -> do
      -- The form only collects the todo; it is never submitted.
      liftEffect (preventDefault event)
      H.modify_ \state -> case trim state.draft of
        "" -> state
        text -> state
          { todos = snoc state.todos { key: state.next, text, done: false }
          , draft = ""
          , next = state.next + 1
          }
    Toggle key -> H.modify_ \state -> state
      { todos = map (\todo -> if todo.key == key then todo { done = not todo.done } else todo)
          state.todos
      }
    Remove key -> H.modify_ \state -> state
      { todos = filter (\todo -> todo.key /= key) state.todos }

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI todos unit body
`,
      },
    ],
  },
  {
    id: "react-counter",
    name: "React counter",
    description: "A React component styled with StyleX",
    files: [
      {
        path: "src/Main.purs",
        text: String.raw`module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception (throw)
import Iris.StyleX as StyleX
import React.Basic (keyed)
import React.Basic.DOM as R
import React.Basic.Events (handler_)
import React.Basic.Hooks (Component, component, useState, (/\))
import React.Basic.Hooks as React
${REACT_ROOT_IMPORTS}

${COUNTER_STYLES}

mkCounter :: Component Unit
mkCounter = component "Counter" \_ -> React.do
  count /\ setCount <- useState 0
  let
    key keyStyles label change = R.button
      { className: (StyleX.props keyStyles).className
      , onClick: handler_ (setCount change)
      , children: [ R.text label ]
      }
  pure $ R.div
    { className: styleProps.page.className
    , children:
        [ R.h1 { className: styleProps.title.className, children: [ R.text "React counter" ] }
        , R.div
            { className: styleProps.row.className
            , children:
                [ key [ styles.key ] "−" (_ - 1)
                , keyed (show count) $ R.span
                    { className: styleProps.count.className, children: [ R.text (show count) ] }
                , key [ styles.key, styles.accent ] "+" (_ + 1)
                ]
            }
        ]
    }

${REACT_MAIN("counter")}
`,
      },
    ],
  },
  {
    id: "react-todos",
    name: "React todos",
    description: "A React todo list styled with StyleX",
    files: [
      {
        path: "src/Main.purs",
        text: String.raw`module Main where

import Prelude

import Data.Array (filter, length, snoc)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (trim)
import Effect (Effect)
import Effect.Exception (throw)
import Iris.StyleX as StyleX
import React.Basic (keyed)
import React.Basic.DOM as R
import React.Basic.DOM.Events (preventDefault, targetValue)
import React.Basic.Events (handler, handler_)
import React.Basic.Hooks (Component, component, useState, (/\))
import React.Basic.Hooks as React
${REACT_ROOT_IMPORTS}

${TODO_STYLES}

type Todo = { key :: Int, text :: String, done :: Boolean }

mkTodos :: Component Unit
mkTodos = component "Todos" \_ -> React.do
  todos /\ setTodos <- useState
    [ { key: 0, text: "Open the playground", done: true }
    , { key: 1, text: "Write some PureScript", done: false }
    ]
  draft /\ setDraft <- useState ""
  next /\ setNext <- useState 2
  let
    add = case trim draft of
      "" -> pure unit
      text -> do
        setTodos \current -> snoc current { key: next, text, done: false }
        setNext (_ + 1)
        setDraft (const "")
    toggle key = setTodos $ map \todo ->
      if todo.key == key then todo { done = not todo.done } else todo
    remove key = setTodos (filter \todo -> todo.key /= key)

    item todo = keyed (show todo.key) $ R.li
      { className: styleProps.item.className
      , children:
          [ R.label
              { className: styleProps.label.className
              , children:
                  [ R.input
                      { className: styleProps.checkbox.className
                      , type: "checkbox"
                      , checked: todo.done
                      , onChange: handler_ (toggle todo.key)
                      }
                  , R.span
                      { className: (StyleX.props [ StyleX.conditional todo.done styles.done ]).className
                      , children: [ R.text todo.text ]
                      }
                  ]
              }
          , R.button
              { className: styleProps.remove.className
              , title: "Remove"
              , onClick: handler_ (remove todo.key)
              , children: [ R.text "×" ]
              }
          ]
      }
  pure $ R.div
    { className: styleProps.page.className
    , children:
        [ R.h1 { className: styleProps.title.className, children: [ R.text "React todos" ] }
        , R.form
            { className: styleProps.form.className
            -- The form only collects the todo; it is never submitted.
            , onSubmit: handler preventDefault (const add)
            , children:
                [ R.input
                    { className: styleProps.input.className
                    , placeholder: "What needs doing?"
                    , value: draft
                    , onChange: handler targetValue \value -> setDraft (const (fromMaybe "" value))
                    }
                , R.button
                    { className: styleProps.key.className
                    , type: "submit"
                    , children: [ R.text "Add" ]
                    }
                ]
            }
        , R.ul { className: styleProps.list.className, children: map item todos }
        , R.p
            { className: styleProps.remaining.className
            , children: [ R.text (show (length (filter (not <<< _.done) todos)) <> " left") ]
            }
        ]
    }

${REACT_MAIN("todos")}
`,
      },
    ],
  },
];
