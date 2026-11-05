module Website.Playground.Scroll (followingScroll, scroll) where

import Data.Nullable (Nullable)
import React.Basic (JSX, ReactComponent, Ref, element)
import React.Basic.Events (EventHandler)
import Web.DOM.Element (Element)

foreign import scrollImpl :: ReactComponent { className :: String, children :: Array JSX }

foreign import followingScrollImpl ::
  ReactComponent
    { className :: String
    , label :: String
    , scrollRef :: Ref (Nullable Element)
    , onScroll :: EventHandler
    , children :: Array JSX
    }

scroll :: String -> Array JSX -> JSX
scroll className children = element scrollImpl { className, children }

followingScroll ::
  { className :: String
  , label :: String
  , scrollRef :: Ref (Nullable Element)
  , onScroll :: EventHandler
  } -> Array JSX -> JSX
followingScroll { className, label, scrollRef, onScroll } children =
  element followingScrollImpl { className, label, scrollRef, onScroll, children }
