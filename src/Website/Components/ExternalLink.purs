module Website.Components.ExternalLink (externalLink, newTabLabel) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

styles = StyleX.create
  { visuallyHidden:
      { clipPath: "inset(50%)"
      , height: 1
      , overflow: "hidden"
      , position: "absolute"
      , whiteSpace: "nowrap"
      , width: 1
      }
  }

newTabLabel :: String
newTabLabel = " (opens in a new tab)"

externalLink :: { className :: String, href :: String } -> Array JSX -> JSX
externalLink { className, href } content =
  DOM.a { className, href, rel: "noopener noreferrer", target: targetBlank }
    (content <> [ DOM.span (StyleX.props styles.visuallyHidden) newTabLabel ])
