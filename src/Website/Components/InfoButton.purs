module Website.Components.InfoButton (infoButton) where

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Components.IconButton.Styles (iconButtonStyles)

foreign import infoButtonImpl ::
  ReactComponent { className :: String, text :: String, tooltipClassName :: String }

-- | A small information button whose tooltip carries a short note.
infoButton :: String -> JSX
infoButton text =
  element
    infoButtonImpl
    { className: (StyleX.props [ iconButtonStyles.button, iconButtonStyles.small ]).className
    , text
    , tooltipClassName: (StyleX.props iconButtonStyles.tooltip).className
    }
