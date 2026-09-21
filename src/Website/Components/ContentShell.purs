module Website.Components.ContentShell (contentShell) where

import Iris.StyleX as StyleX

styles = StyleX.create
  { contentShell:
      { marginInline: "auto"
      , maxWidth: 1280
      , paddingInline:
          { default: 40
          , "@media (max-width: 800px)": 20
          }
      , width: "100%"
      }
  }

contentShell = StyleX.props styles.contentShell
