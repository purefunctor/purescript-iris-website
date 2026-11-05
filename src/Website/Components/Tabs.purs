module Website.Components.Tabs (Item, tabs) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)

type Item = { id :: String, tab :: JSX, panel :: JSX }

type Classes = { root :: String, list :: String, tab :: String, panel :: String }

foreign import tabsImpl ::
  ReactComponent { label :: String, items :: Array Item, classes :: Classes }

styles = StyleX.create
  { root: { display: "grid", gridTemplateColumns: "minmax(0, 1fr)" }
  , panel: { gridArea: "2 / 1", visibility: { default: "visible", "[data-inert]": "hidden" } }
  }

tabs :: { label :: String, items :: Array Item, classes :: Classes } -> JSX
tabs { label, items, classes } = element tabsImpl
  { label
  , items
  , classes:
      classes
        { root = (StyleX.props [ styles.root ]).className <> " " <> classes.root
        , panel = (StyleX.props [ styles.panel ]).className <> " " <> classes.panel
        }
  }
