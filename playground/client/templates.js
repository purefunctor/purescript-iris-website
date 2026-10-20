// Projects that the sidebar offers as starting points. The first is the default project, which a
// new visit opens and Reset restores. Each one is a complete project that loads in place of the
// current one.

export const TEMPLATES = [
  {
    id: "console",
    name: "Console",
    description: "Logs to the output",
    files: [
      {
        path: "src/Main.purs",
        text: `module Main where

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
        text: `module Greeting (greet) where

import Prelude

greet :: String -> String
greet name = "Hello, " <> name <> "!"
`,
      },
    ],
  },
  {
    id: "halogen",
    name: "Halogen counter",
    description: "A Halogen component styled with StyleX",
    files: [
      {
        path: "src/Main.purs",
        text: `module Main where

import Prelude

import Effect (Effect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Iris.StyleX as StyleX

-- StyleX styles compile to class names and CSS when the project runs. The colors follow the
-- playground's own: granite neutrals, and raised keys lit from above that sink while pressed.
styles = StyleX.create
  { page:
      { alignItems: "center"
      , backgroundColor: "oklch(19.2% 0.005 255)"
      , color: "oklch(96.5% 0.002 255)"
      , display: "flex"
      , fontFamily: "system-ui, sans-serif"
      , inset: 0
      , justifyContent: "center"
      , position: "fixed"
      }
  , card:
      { alignItems: "center"
      , backgroundColor: "oklch(22% 0.005 255)"
      , borderRadius: 20
      , boxShadow:
          "inset 0 1px 0 oklch(100% 0 0 / 8%), 0 1px 0 oklch(0% 0 0 / 40%), 0 16px 40px oklch(0% 0 0 / 45%)"
      , display: "flex"
      , flexDirection: "column"
      , gap: 20
      , paddingBlock: 28
      , paddingInline: 36
      }
  , title: { color: "oklch(66% 0.008 255)", fontSize: 14, fontWeight: 600, margin: 0 }
  , count:
      { fontFamily: "ui-monospace, monospace"
      , fontSize: 56
      , fontVariantNumeric: "tabular-nums"
      , fontWeight: 600
      , lineHeight: 1
      , minWidth: "3ch"
      , textAlign: "center"
      }
  , keys: { display: "flex", gap: 12 }
  , key:
      { backgroundColor:
          { default: "oklch(25% 0.006 255)"
          , ":hover": "oklch(30.5% 0.007 255)"
          , ":active": "oklch(22% 0.005 255)"
          }
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active":
              "inset 0 1px 3px oklch(0% 0 0 / 45%), inset 0 0 0 oklch(0% 0 0 / 0%), 0 0 0 oklch(0% 0 0 / 0%)"
          }
      , color: "oklch(91.5% 0.004 255)"
      , cursor: "default"
      , fontSize: 20
      , fontWeight: 700
      , height: 44
      , outlineColor: "oklch(86% 0.13 95)"
      , outlineOffset: 3
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , textShadow: "0 -1px 0 oklch(0% 0 0 / 35%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      , transitionDuration: "180ms"
      , transitionProperty: "background-color, box-shadow, transform"
      , width: 64
      }
  , accent:
      { backgroundColor:
          { default: "oklch(71% 0.19 44)"
          , ":hover": "oklch(79% 0.15 52)"
          , ":active": "oklch(63% 0.2 38)"
          }
      , color: "oklch(16% 0.004 255)"
      , textShadow: "0 1px 0 oklch(88% 0.08 58 / 45%)"
      }
  }

styleProps = StyleX.recordProps styles

-- | Halogen takes a StyleX class name as a class property.
style :: forall r i. StyleX.Props -> HP.IProp (class :: String | r) i
style { className } = HP.class_ (HH.ClassName className)

data Action = Increment | Decrement

counter :: forall query input output m. H.Component query input output m
counter = H.mkComponent
  { initialState: \\_ -> 0
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }
  where
  render count = HH.div [ style styleProps.page ]
    [ HH.div [ style styleProps.card ]
        [ HH.h1 [ style styleProps.title ] [ HH.text "Halogen counter" ]
        , HH.div [ style styleProps.count ] [ HH.text (show count) ]
        , HH.div [ style styleProps.keys ]
            [ HH.button [ style styleProps.key, HE.onClick \\_ -> Decrement ] [ HH.text "−" ]
            , HH.button
                [ style (StyleX.props [ styles.key, styles.accent ]), HE.onClick \\_ -> Increment ]
                [ HH.text "+" ]
            ]
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
    id: "react",
    name: "React counter",
    description: "A React component styled with StyleX",
    files: [
      {
        path: "src/Main.purs",
        text: `module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception (throw)
import Iris.StyleX as StyleX
import React.Basic.DOM as R
import React.Basic.DOM.Client (createRoot, renderRoot)
import React.Basic.Events (handler_)
import React.Basic.Hooks (Component, component, useState, (/\\))
import React.Basic.Hooks as React
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)

-- StyleX styles compile to class names and CSS when the project runs. The colors follow the
-- playground's own: granite neutrals, and raised keys lit from above that sink while pressed.
styles = StyleX.create
  { page:
      { alignItems: "center"
      , backgroundColor: "oklch(19.2% 0.005 255)"
      , color: "oklch(96.5% 0.002 255)"
      , display: "flex"
      , fontFamily: "system-ui, sans-serif"
      , inset: 0
      , justifyContent: "center"
      , position: "fixed"
      }
  , card:
      { alignItems: "center"
      , backgroundColor: "oklch(22% 0.005 255)"
      , borderRadius: 20
      , boxShadow:
          "inset 0 1px 0 oklch(100% 0 0 / 8%), 0 1px 0 oklch(0% 0 0 / 40%), 0 16px 40px oklch(0% 0 0 / 45%)"
      , display: "flex"
      , flexDirection: "column"
      , gap: 20
      , paddingBlock: 28
      , paddingInline: 36
      }
  , title: { color: "oklch(66% 0.008 255)", fontSize: 14, fontWeight: 600, margin: 0 }
  , count:
      { fontFamily: "ui-monospace, monospace"
      , fontSize: 56
      , fontVariantNumeric: "tabular-nums"
      , fontWeight: 600
      , lineHeight: 1
      , minWidth: "3ch"
      , textAlign: "center"
      }
  , keys: { display: "flex", gap: 12 }
  , key:
      { backgroundColor:
          { default: "oklch(25% 0.006 255)"
          , ":hover": "oklch(30.5% 0.007 255)"
          , ":active": "oklch(22% 0.005 255)"
          }
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active":
              "inset 0 1px 3px oklch(0% 0 0 / 45%), inset 0 0 0 oklch(0% 0 0 / 0%), 0 0 0 oklch(0% 0 0 / 0%)"
          }
      , color: "oklch(91.5% 0.004 255)"
      , cursor: "default"
      , fontSize: 20
      , fontWeight: 700
      , height: 44
      , outlineColor: "oklch(86% 0.13 95)"
      , outlineOffset: 3
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , textShadow: "0 -1px 0 oklch(0% 0 0 / 35%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      , transitionDuration: "180ms"
      , transitionProperty: "background-color, box-shadow, transform"
      , width: 64
      }
  , accent:
      { backgroundColor:
          { default: "oklch(71% 0.19 44)"
          , ":hover": "oklch(79% 0.15 52)"
          , ":active": "oklch(63% 0.2 38)"
          }
      , color: "oklch(16% 0.004 255)"
      , textShadow: "0 1px 0 oklch(88% 0.08 58 / 45%)"
      }
  }

styleProps = StyleX.recordProps styles

mkCounter :: Component Unit
mkCounter = component "Counter" \\_ -> React.do
  count /\\ setCount <- useState 0
  pure $ R.div
    { className: styleProps.page.className
    , children:
        [ R.div
            { className: styleProps.card.className
            , children:
                [ R.h1 { className: styleProps.title.className, children: [ R.text "React counter" ] }
                , R.div { className: styleProps.count.className, children: [ R.text (show count) ] }
                , R.div
                    { className: styleProps.keys.className
                    , children:
                        [ R.button
                            { className: styleProps.key.className
                            , onClick: handler_ (setCount (_ - 1))
                            , children: [ R.text "−" ]
                            }
                        , R.button
                            { className: (StyleX.props [ styles.key, styles.accent ]).className
                            , onClick: handler_ (setCount (_ + 1))
                            , children: [ R.text "+" ]
                            }
                        ]
                    }
                ]
            }
        ]
    }

main :: Effect Unit
main = do
  -- The playground's frame offers #app as a mount point.
  app <- getElementById "app" =<< (map toNonElementParentNode <<< document =<< window)
  case app of
    Nothing -> throw "There is no #app element."
    Just element -> do
      counter <- mkCounter
      root <- createRoot element
      renderRoot root (counter unit)
`,
      },
    ],
  },
];
