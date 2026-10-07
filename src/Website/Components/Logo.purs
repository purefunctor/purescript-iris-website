module Website.Components.Logo (logo) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX)
import Yoga.React.DOM as DOM

type Mark = { x :: Number, y :: Number, radius :: Number, color :: String }

-- | The logo's dots, named by spectrum color.
foreign import marks :: Array Mark

styles =
  StyleX.create
    { red: { fill: "var(--spectrum-red)" }
    , orange: { fill: "var(--spectrum-orange)" }
    , yellow: { fill: "var(--spectrum-yellow)" }
    , green: { fill: "var(--spectrum-green)" }
    , blue: { fill: "var(--spectrum-blue)" }
    , indigo: { fill: "var(--spectrum-indigo)" }
    , violet: { fill: "var(--spectrum-violet)" }
    }

styleProps = StyleX.recordProps styles

-- | The decorative dot mark; `className` sets its size.
logo :: { className :: String } -> JSX
logo { className } =
  DOM.createBuiltinElement
    "svg"
    { className, viewBox: "0 0 32 32", "aria-hidden": true, focusable: "false" }
    (map dot marks)
  where
  dot { x, y, radius, color } =
    DOM.createBuiltinElement
      "circle"
      { className: fill color, cx: x, cy: y, r: radius, key: color }
      []

  fill =
    case _ of
      "red" -> styleProps.red.className
      "orange" -> styleProps.orange.className
      "yellow" -> styleProps.yellow.className
      "green" -> styleProps.green.className
      "blue" -> styleProps.blue.className
      "indigo" -> styleProps.indigo.className
      _ -> styleProps.violet.className
