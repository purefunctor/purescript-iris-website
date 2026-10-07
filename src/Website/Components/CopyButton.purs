module Website.Components.CopyButton (Size(..), copyButton) where

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Components.IconButton.Styles (iconButtonStyles)

foreign import copyButtonImpl ::
  ReactComponent
    { className :: String
    , copiedClassName :: String
    , fallbackClassName :: String
    , label :: String
    , text :: String
    , tooltipClassName :: String
    }

data Size = Small | Medium

styles =
  StyleX.create
    { copied: { color: "var(--success)" }
    , fallback: { opacity: 0, position: "fixed" }
    }

sizeStyle :: Size -> StyleX.Style
sizeStyle =
  case _ of
    Small -> iconButtonStyles.small
    Medium -> iconButtonStyles.medium

copyButton :: { label :: String, size :: Size, text :: String } -> JSX
copyButton { label, size, text } =
  element
    copyButtonImpl
    { className:
        (StyleX.props [ iconButtonStyles.button, sizeStyle size ]).className
    , copiedClassName:
        (
          StyleX.props
            [ iconButtonStyles.button, sizeStyle size, styles.copied ]
        ).className
    , fallbackClassName: (StyleX.props styles.fallback).className
    , label
    , text
    , tooltipClassName: (StyleX.props iconButtonStyles.tooltip).className
    }
