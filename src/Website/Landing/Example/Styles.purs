module Website.Landing.Example.Styles where

import Iris.StyleX as StyleX

styles = StyleX.create
  { button:
      { backgroundColor: { default: "orange", ":hover": "coral" }
      , color: "black"
      , padding: "8px 16px"
      }
  }

button :: StyleX.Props
button = StyleX.props styles.button
