module Website.Components.ContentShell (contentShell) where

import Iris.StyleX as StyleX

styles = StyleX.create
  { contentShell:
      { marginInline: "auto"
      , maxWidth: 1180
      , paddingInline:
          { default: 32
          , "@media (max-width: 800px)": 20
          }
      , width: "100%"
      }
  }

contentShell = StyleX.props styles.contentShell
