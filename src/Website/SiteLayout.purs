module Website.SiteLayout (html, application) where

import Iris.StyleX as StyleX
import Website.Breakpoints (breakpoints)

styles = StyleX.create
  { html:
      { scrollbarGutter:
          StyleX.conditionalValue "stable" [ StyleX.conditionalCase breakpoints.upTo800 "auto" ]
      }
  -- Pages that fill the viewport, such as the playground, never scroll on wide screens, so a
  -- reserved gutter would only leave an empty strip beside them.
  , application: { scrollbarGutter: "auto" }
  }

html = StyleX.attrs styles.html

application = StyleX.attrs styles.application
