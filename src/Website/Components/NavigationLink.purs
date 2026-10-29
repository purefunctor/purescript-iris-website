module Website.Components.NavigationLink (classNames, navigationLink) where

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)

foreign import navigationLinkImpl ::
  ReactComponent
    { href :: String
    , className :: String
    , canvasClassName :: String
    , contentClassName :: String
    , current :: Boolean
    , content :: JSX
    }

styles = StyleX.create
  { canvas:
      { position: "absolute"
      , inset: 0
      , width: "100%"
      , height: "100%"
      , zIndex: 0
      , pointerEvents: "none"
      , opacity: { default: 0.0, "[data-ocean]": 1.0 }
      }
  , content:
      { position: "relative"
      , zIndex: 1
      , display: "flex"
      , alignItems: "center"
      , justifyContent: "space-between"
      , gap: 10
      , width: "100%"
      , minWidth: 0
      }
  }

styleProps = StyleX.recordProps styles

classNames :: { canvas :: String, content :: String }
classNames = { canvas: styleProps.canvas.className, content: styleProps.content.className }

navigationLink :: { href :: String, className :: String, current :: Boolean, content :: JSX } -> JSX
navigationLink { href, className, current, content } = element navigationLinkImpl
  { href
  , className
  , canvasClassName: classNames.canvas
  , contentClassName: classNames.content
  , current
  , content
  }
