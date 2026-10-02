module Website.Components.ContentShell (contentShell) where

import Iris.StyleX as StyleX

styles = StyleX.create
  { contentShell:
      { marginInline: "auto"
      , maxWidth: "var(--container-wide)"
      , paddingInline: "var(--gutter)"
      , width: "100%"
      }
  }

contentShell = StyleX.props styles.contentShell
