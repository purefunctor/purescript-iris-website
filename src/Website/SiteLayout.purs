module Website.SiteLayout (html) where

import Iris.StyleX as StyleX
import Website.Breakpoints (breakpoints)

styles =
  StyleX.create
    { html:
        { scrollbarGutter:
            StyleX.conditionalValue "stable" [ StyleX.conditionalCase breakpoints.upTo800 "auto" ]
        }
    }

html = StyleX.attrs styles.html
